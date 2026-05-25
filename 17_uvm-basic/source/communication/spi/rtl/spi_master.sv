`timescale 1ns/1ps

module spi_master (
  input  logic                  iClk,
  input  logic                  iTick,
  input  logic                  iRst,
  input  logic                  iStart,
  input  logic                  iCpol,
  input  logic                  iCpha,
  input  logic [7:0]            iTxData,
  input  logic                  iMiso,

  output logic [7:0]            oRxData,
  output logic                  oBusy,
  output logic                  oDone,
  output logic                  oSclk,
  output logic                  oCsN,
  output logic                  oMosi
);

  typedef enum logic [2:0] {
    IDLE,
    ASSERT_CS,
    TRANSFER,
    COMPLETE,
    DONE
  } state_e;

  localparam int SAMPLE_CNT_W = 4;
  localparam logic [SAMPLE_CNT_W-1:0] FRAME_BITS  = 4'd8;
  localparam logic [SAMPLE_CNT_W-1:0] LAST_SAMPLE = 4'd7;

  // FSM state: current/next transaction phase.
  state_e                      rCurState;
  state_e                      rNxtState;
  // Number of received sample points accumulated in the current frame.
  logic [SAMPLE_CNT_W-1:0]     rSampleCnt;
  // Shift registers for MOSI transmit data and MISO receive data.
  logic [7:0]                  rTxShift;
  logic [7:0]                  rRxShift;
  logic                        rMisoMeta;
  logic                        rMisoSync;
  // Registered SPI clock level and an extra /2 stage to make one full SCLK from two iTick pulses.
  logic                        rSclk;
  logic                        rTickDiv2;
  // Tracks whether the first MOSI bit is already presented before shift edges begin.
  logic                        rTxPrimed;
  // Set after the last sample so we can still emit the final trailing half-cycle before stopping.
  logic                        rFrameDone;
  // Internal timing pulses derived from the current SPI mode.
  logic                        wClkTick;
  logic                        wLeadEdge;
  logic                        wTrailEdge;
  logic                        wShiftEdge;
  logic                        wSampleEdge;

  assign wClkTick    = iTick && rTickDiv2;
  assign wLeadEdge   = wClkTick && (rCurState == TRANSFER) && (rSclk == iCpol);
  assign wTrailEdge  = wClkTick && (rCurState == TRANSFER) && (rSclk != iCpol);
  assign wShiftEdge  = iCpha ? wLeadEdge : wTrailEdge;
  assign wSampleEdge = iCpha ? wTrailEdge : wLeadEdge;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rCurState <= IDLE;
    end
    else begin
      rCurState <= rNxtState;
    end
  end

  always_comb begin
    rNxtState = rCurState;

    case (rCurState)
      IDLE: begin
        if (iStart) begin
          rNxtState = ASSERT_CS;
        end
      end

      ASSERT_CS: begin
        if (wClkTick) begin
          rNxtState = TRANSFER;
        end
      end

      TRANSFER: begin
        if (rFrameDone && wTrailEdge) begin
          rNxtState = COMPLETE;
        end
      end

      COMPLETE: begin
        if (wClkTick) begin
          rNxtState = DONE;
        end
      end

      DONE: begin
        rNxtState = IDLE;
      end

      default: begin
        rNxtState = IDLE;
      end
    endcase
  end

  always_comb begin
    oBusy = 1'b1;
    oDone = 1'b0;
    oCsN  = 1'b0;

    case (rCurState)
      IDLE: begin
        oBusy = 1'b0;
        oCsN  = 1'b1;
      end

      DONE: begin
        oBusy = 1'b0;
        oDone = 1'b1;
        oCsN  = 1'b1;
      end

      COMPLETE: begin
        oBusy = 1'b1;
        oCsN  = 1'b0;
      end

      default: begin
        oBusy = 1'b1;
        oCsN  = 1'b0;
      end
    endcase
  end

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rSampleCnt <= '0;
      rTxShift   <= '0;
      rRxShift   <= '0;
      rMisoMeta  <= 1'b0;
      rMisoSync  <= 1'b0;
      rSclk      <= 1'b0;
      rTickDiv2  <= 1'b0;
      rTxPrimed  <= 1'b0;
      rFrameDone <= 1'b0;
      oRxData    <= '0;
    end
    else begin
      rMisoMeta <= iMiso;
      rMisoSync <= rMisoMeta;

      if (rCurState != rNxtState) begin
        rTickDiv2 <= 1'b0;
      end
      else if ((rCurState == ASSERT_CS) || (rCurState == TRANSFER) || (rCurState == COMPLETE)) begin
        if (iTick) begin
          rTickDiv2 <= ~rTickDiv2;
        end
      end
      else begin
        rTickDiv2 <= 1'b0;
      end

      case (rCurState)
        IDLE: begin
          rSampleCnt <= '0;
          rSclk      <= iCpol;
          rTxPrimed  <= ~iCpha;
          rFrameDone <= 1'b0;

          if (iStart) begin
            rTxShift <= iTxData;
            rRxShift <= '0;
          end
        end

        ASSERT_CS: begin
          rSclk <= iCpol;
          rFrameDone <= 1'b0;
        end

        TRANSFER: begin
          if (wClkTick) begin
            rSclk   <= ~rSclk;
          end

          if (wShiftEdge) begin
            if (!rTxPrimed) begin
              rTxPrimed <= 1'b1;
            end
            else if (rSampleCnt < FRAME_BITS) begin
              rTxShift <= {rTxShift[6:0], 1'b0};
            end
          end

          if (wSampleEdge) begin
            rRxShift <= {rRxShift[6:0], rMisoSync};

            if (rSampleCnt == LAST_SAMPLE) begin
              oRxData <= {rRxShift[6:0], rMisoSync};
              rFrameDone <= 1'b1;
            end

            if (rSampleCnt < FRAME_BITS) begin
              rSampleCnt <= rSampleCnt + 1'b1;
            end
          end
        end

        COMPLETE: begin
          rSclk <= iCpol;
          rFrameDone <= 1'b0;
        end

        DONE: begin
          rSampleCnt <= '0;
          rSclk      <= iCpol;
          rTxPrimed  <= ~iCpha;
          rFrameDone <= 1'b0;
        end

        default: begin
          rSampleCnt <= '0;
          rTxShift   <= '0;
          rRxShift   <= '0;
          rSclk      <= iCpol;
          rTickDiv2  <= 1'b0;
          rTxPrimed  <= 1'b0;
          rFrameDone <= 1'b0;
          oRxData    <= '0;
        end
      endcase
    end
  end

  assign oSclk = rSclk;
  assign oMosi = rTxShift[7];

endmodule
