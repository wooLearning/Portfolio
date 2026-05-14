`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: SpiMaster
Role: Single-byte SPI master without bus protocol coupling
Summary:
  - Transfers one 8-bit frame per iStart pulse
  - Supports CPOL and CPHA modes
  - Exposes raw SPI pins and busy/done status
StateDescription:
  - S_IDLE: waits for iStart
  - S_ASSERT_CS: asserts chip select before clocks
  - S_TRANSFER: shifts MOSI and samples MISO
  - S_FRAME_END: returns SCLK to idle before the done pulse
  - S_DONE: emits one-cycle done pulse
[MODULE_INFO_END]
*/
module SpiMaster (
  input  logic       iClk,
  input  logic       iRstn,
  input  logic       iTick,
  input  logic       iStart,
  input  logic       iCpol,
  input  logic       iCpha,
  input  logic [7:0] iTxData,
  input  logic       iMiso,
  output logic [7:0] oRxData,
  output logic       oBusy,
  output logic       oDone,
  output logic       oSclk,
  output logic       oCsN,
  output logic       oMosi
);

  typedef enum logic [2:0] {
    S_IDLE,
    S_ASSERT_CS,
    S_TRANSFER,
    S_FRAME_END,
    S_DONE
  } state_e;

  localparam logic [3:0] LP_FRAME_BITS  = 4'd8;
  localparam logic [3:0] LP_LAST_SAMPLE = 4'd7;

  state_e     rState;
  state_e     wNextState;
  logic [3:0] rSampleCnt;
  logic [7:0] rTxShift;
  logic [7:0] rRxShift;
  logic       rSclk;
  logic       rTickDiv2;
  logic       rTxPrimed;
  logic       rFrameDone;
  logic       wClkTick;
  logic       wLeadEdge;
  logic       wTrailEdge;
  logic       wShiftEdge;
  logic       wSampleEdge;

  assign wClkTick    = iTick && rTickDiv2;
  assign wLeadEdge   = wClkTick && (rState == S_TRANSFER) && (rSclk == iCpol);
  assign wTrailEdge  = wClkTick && (rState == S_TRANSFER) && (rSclk != iCpol);
  assign wShiftEdge  = iCpha ? wLeadEdge : wTrailEdge;
  assign wSampleEdge = iCpha ? wTrailEdge : wLeadEdge;

  assign oSclk = rSclk;
  assign oMosi = rTxShift[7];

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rState <= S_IDLE;
    end
    else begin
      rState <= wNextState;
    end
  end

  always_comb begin
    wNextState = rState;

    unique case (rState)
      S_IDLE: begin
        if (iStart) begin
          wNextState = S_ASSERT_CS;
        end
      end

      S_ASSERT_CS: begin
        if (wClkTick) begin
          wNextState = S_TRANSFER;
        end
      end

      S_TRANSFER: begin
        if (rFrameDone && wTrailEdge) begin
          wNextState = S_FRAME_END;
        end
      end

      S_FRAME_END: begin
        if (wClkTick) begin
          wNextState = S_DONE;
        end
      end

      S_DONE: begin
        wNextState = S_IDLE;
      end

      default: begin
        wNextState = S_IDLE;
      end
    endcase
  end

  always_comb begin
    oBusy = 1'b1;
    oDone = 1'b0;
    oCsN  = 1'b0;

    unique case (rState)
      S_IDLE: begin
        oBusy = 1'b0;
        oCsN  = 1'b1;
      end

      S_DONE: begin
        oBusy = 1'b0;
        oDone = 1'b1;
        oCsN  = 1'b1;
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rSampleCnt <= '0;
      rTxShift   <= '0;
      rRxShift   <= '0;
      rSclk      <= 1'b0;
      rTickDiv2  <= 1'b0;
      rTxPrimed  <= 1'b0;
      rFrameDone <= 1'b0;
      oRxData    <= '0;
    end
    else begin
      if (rState != wNextState) begin
        rTickDiv2 <= 1'b0;
      end
      else if ((rState == S_ASSERT_CS) || (rState == S_TRANSFER) ||
               (rState == S_FRAME_END)) begin
        if (iTick) begin
          rTickDiv2 <= ~rTickDiv2;
        end
      end
      else begin
        rTickDiv2 <= 1'b0;
      end

      unique case (rState)
        S_IDLE: begin
          rSampleCnt <= '0;
          rSclk      <= iCpol;
          rTxPrimed  <= ~iCpha;
          rFrameDone <= 1'b0;

          if (iStart) begin
            rTxShift <= iTxData;
            rRxShift <= '0;
          end
        end

        S_ASSERT_CS: begin
          rSclk      <= iCpol;
          rFrameDone <= 1'b0;
        end

        S_TRANSFER: begin
          if (wClkTick) begin
            rSclk <= ~rSclk;
          end

          if (wShiftEdge) begin
            if (!rTxPrimed) begin
              rTxPrimed <= 1'b1;
            end
            else if (rSampleCnt < LP_FRAME_BITS) begin
              rTxShift <= {rTxShift[6:0], 1'b0};
            end
          end

          if (wSampleEdge) begin
            rRxShift <= {rRxShift[6:0], iMiso};

            if (rSampleCnt == LP_LAST_SAMPLE) begin
              oRxData    <= {rRxShift[6:0], iMiso};
              rFrameDone <= 1'b1;
            end

            if (rSampleCnt < LP_FRAME_BITS) begin
              rSampleCnt <= rSampleCnt + 1'b1;
            end
          end
        end

        S_FRAME_END: begin
          rSclk      <= iCpol;
          rFrameDone <= 1'b0;
        end

        S_DONE: begin
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

endmodule
