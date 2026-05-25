`timescale 1ns/1ps

module spi_slave (
  input  logic                  iClk,
  input  logic                  iRst,
  input  logic                  iCpol,
  input  logic                  iCpha,
  input  logic                  iSclk,
  input  logic                  iCsN,
  input  logic                  iMosi,
  input  logic [7:0]            iTxData,

  output logic [7:0]            oRxData,
  output logic                  oRxValid,
  output logic                  oMiso,
  output logic                  oMisoOe
);

  typedef enum logic [1:0] {
    IDLE,
    TRANSFER,
    COMPLETE
  } state_e;

  localparam int SAMPLE_CNT_W = 4;
  localparam logic [SAMPLE_CNT_W-1:0] FRAME_BITS  = 4'd8;
  localparam logic [SAMPLE_CNT_W-1:0] LAST_SAMPLE = 4'd7;

  state_e                  rCurState;
  state_e                  rNxtState;
  logic                    rSclkMeta;
  logic                    rSclkSync;
  logic                    rCsNMeta;
  logic                    rCsNSync;
  logic                    rMosiMeta;
  logic                    rMosiSync;
  logic                    rSclkPrev;
  logic                    rCsNPrev;
  logic [SAMPLE_CNT_W-1:0] rSampleCnt;
  logic [7:0]              rTxShift;
  logic [7:0]              rRxShift;
  logic                    rTxPrimed;
  logic                    wCsFall;
  logic                    wCsRise;
  logic                    wRiseEdge;
  logic                    wFallEdge;
  logic                    wLeadEdge;
  logic                    wTrailEdge;
  logic                    wShiftEdge;
  logic                    wSampleEdge;

  assign wCsFall    =  rCsNPrev && !rCsNSync;
  assign wCsRise    = !rCsNPrev &&  rCsNSync;
  assign wRiseEdge  = !rSclkPrev &&  rSclkSync;
  assign wFallEdge  =  rSclkPrev && !rSclkSync;
  assign wLeadEdge  = iCpol ? wFallEdge : wRiseEdge;
  assign wTrailEdge = iCpol ? wRiseEdge : wFallEdge;
  assign wShiftEdge = iCpha ? wLeadEdge : wTrailEdge;
  assign wSampleEdge = iCpha ? wTrailEdge : wLeadEdge;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rCurState <= IDLE;
      rSclkMeta <= 1'b0;
      rSclkSync <= 1'b0;
      rCsNMeta  <= 1'b1;
      rCsNSync  <= 1'b1;
      rMosiMeta <= 1'b0;
      rMosiSync <= 1'b0;
    end
    else begin
      rCurState <= rNxtState;
      rSclkMeta <= iSclk;
      rSclkSync <= rSclkMeta;
      rCsNMeta  <= iCsN;
      rCsNSync  <= rCsNMeta;
      rMosiMeta <= iMosi;
      rMosiSync <= rMosiMeta;
    end
  end

  always_comb begin
    rNxtState = rCurState;

    case (rCurState)
      IDLE: begin
        if (wCsFall) begin
          rNxtState = TRANSFER;
        end
      end

      TRANSFER: begin
        if ((rCsNSync && (rSampleCnt == FRAME_BITS)) ||
            (wCsRise && ((rSampleCnt == FRAME_BITS) || (rSampleCnt == LAST_SAMPLE)))) begin
          rNxtState = COMPLETE;
        end
      end

      COMPLETE: begin
        rNxtState = IDLE;
      end

      default: begin
        rNxtState = IDLE;
      end
    endcase
  end

  always_comb begin
    oRxValid = 1'b0;

    case (rCurState)
      COMPLETE: begin
        oRxValid = 1'b1;
      end

      default: begin
        oRxValid = 1'b0;
      end
    endcase
  end

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rSclkPrev  <= 1'b0;
      rCsNPrev   <= 1'b1;
      rSampleCnt <= '0;
      rTxShift   <= '0;
      rRxShift   <= '0;
      rTxPrimed  <= 1'b0;
      oRxData    <= '0;
    end
    else begin
      case (rCurState)
        IDLE: begin
          rSampleCnt <= '0;
          rTxPrimed  <= ~iCpha;

          if (wCsFall) begin
            rTxShift <= iTxData;
            rRxShift <= '0;
          end
        end

        TRANSFER: begin
          if (wShiftEdge) begin
            if (!rTxPrimed) begin
              rTxPrimed <= 1'b1;
            end
            else if (rSampleCnt < FRAME_BITS) begin
              rTxShift <= {rTxShift[6:0], 1'b0};
            end
          end

          if (wSampleEdge) begin
            rRxShift <= {rRxShift[6:0], rMosiSync};

            if (rSampleCnt == LAST_SAMPLE) begin
              oRxData <= {rRxShift[6:0], rMosiSync};
            end

            if (rSampleCnt < FRAME_BITS) begin
              rSampleCnt <= rSampleCnt + 1'b1;
            end
          end
        end

        COMPLETE: begin
          rSampleCnt <= '0;
          rTxPrimed  <= ~iCpha;
        end

        default: begin
          rSampleCnt <= '0;
          rTxShift   <= '0;
          rRxShift   <= '0;
          rTxPrimed  <= 1'b0;
          oRxData    <= '0;
        end
      endcase

      rSclkPrev <= rSclkSync;
      rCsNPrev  <= rCsNSync;
    end
  end

  assign oMiso   = rTxShift[7];
  assign oMisoOe = !iCsN;

endmodule
