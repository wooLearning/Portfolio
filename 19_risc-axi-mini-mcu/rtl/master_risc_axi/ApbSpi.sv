`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbSpi
Role: APB wrapper for SPI master with small TX/RX FIFOs
Summary:
  - Exposes CTRL, STATUS, CLKDIV, TXDATA, and RXDATA registers
  - Preserves the legacy one-byte polling flow while allowing queued transfers
  - Adds TX/RX interrupt enables and TX/RX DMA request enables
StateDescription:
  - SPI frame state is held in SpiMaster
  - FIFO pointers/counts track queued TX bytes and received RX bytes
[MODULE_INFO_END]
*/
module ApbSpi #(
  parameter integer P_FIFO_DEPTH = 4
) (
  input  logic        iPclk,
  input  logic        iPresetn,
  input  logic        iPSEL,
  input  logic        iPENABLE,
  input  logic        iPWRITE,
  input  logic [11:0] iPADDR,
  input  logic [31:0] iPWDATA,
  input  logic [3:0]  iPSTRB,
  input  logic        iSpiMiso,
  output logic        oSpiSclk,
  output logic        oSpiMosi,
  output logic [3:0]  oSpiCsN,
  output logic [31:0] oPRDATA,
  output logic        oPREADY,
  output logic        oPSLVERR,
  output logic        oTxIrq,
  output logic        oRxIrq,
  output logic        oTxDmaReq,
  output logic        oRxDmaReq,
  input  logic [7:0]  iTxS_TDATA,
  input  logic        iTxS_TVALID,
  output logic        oTxS_TREADY
);

  localparam logic [7:0] LP_ADDR_CTRL   = 8'h00;
  localparam logic [7:0] LP_ADDR_STATUS = 8'h04;
  localparam logic [7:0] LP_ADDR_CLKDIV = 8'h08;
  localparam logic [7:0] LP_ADDR_TXDATA = 8'h0C;
  localparam logic [7:0] LP_ADDR_RXDATA = 8'h10;
  localparam integer LP_PTR_WIDTH = (P_FIFO_DEPTH <= 2) ? 1 : $clog2(P_FIFO_DEPTH);
  localparam integer LP_CNT_WIDTH = $clog2(P_FIFO_DEPTH + 1);
  localparam logic [LP_CNT_WIDTH-1:0] LP_FIFO_DEPTH_COUNT = P_FIFO_DEPTH[LP_CNT_WIDTH-1:0];

  logic        rCpol;
  logic        rCpha;
  logic [1:0]  rCsSel;
  logic        rTxIrqEnable;
  logic        rRxIrqEnable;
  logic        rTxDmaEnable;
  logic        rRxDmaEnable;
  logic [15:0] rClkDiv;
  logic [15:0] rClkCnt;
  logic        rTick;
  logic        rDoneSticky;
  logic        rRxValidSticky;
  logic        rRxOverrunSticky;
  logic        wWrite;
  logic        wRead;
  logic        wTxWrite;
  logic        wTxStreamWrite;
  logic        wTxPush;
  logic        wRxRead;
  logic        wSpiStartPulse;
  logic        wSpiBusy;
  logic        wSpiDone;
  logic [7:0]  wSpiRxData;
  logic        wSpiCsN;
  logic [1:0]  wActiveCsSel;
  logic [1:0]  rActiveCsSel;
  logic [7:0]  rTxFifo [0:P_FIFO_DEPTH-1];
  logic [7:0]  rRxFifo [0:P_FIFO_DEPTH-1];
  logic [LP_PTR_WIDTH-1:0] rTxWrPtr;
  logic [LP_PTR_WIDTH-1:0] rTxRdPtr;
  logic [LP_CNT_WIDTH-1:0] rTxCount;
  logic [LP_PTR_WIDTH-1:0] rRxWrPtr;
  logic [LP_PTR_WIDTH-1:0] rRxRdPtr;
  logic [LP_CNT_WIDTH-1:0] rRxCount;
  logic        wTxFifoFull;
  logic        wTxFifoEmpty;
  logic        wRxFifoFull;
  logic        wRxFifoEmpty;
  logic        wRxPush;
  logic [LP_PTR_WIDTH-1:0] wTxWrPtrNext;
  logic [LP_PTR_WIDTH-1:0] wTxRdPtrNext;
  logic [LP_PTR_WIDTH-1:0] wRxWrPtrNext;
  logic [LP_PTR_WIDTH-1:0] wRxRdPtrNext;
  integer idx;

  assign wWrite       = iPSEL && iPENABLE && iPWRITE;
  assign wRead        = iPSEL && iPENABLE && !iPWRITE;
  assign wTxFifoFull  = (rTxCount == LP_FIFO_DEPTH_COUNT);
  assign wTxFifoEmpty = (rTxCount == '0);
  assign wRxFifoFull  = (rRxCount == LP_FIFO_DEPTH_COUNT);
  assign wRxFifoEmpty = (rRxCount == '0);
  assign wTxWrite     = wWrite && (iPADDR[7:0] == LP_ADDR_TXDATA) &&
                        iPSTRB[0] && !wTxFifoFull;
  assign oTxS_TREADY  = rTxDmaEnable && !wTxFifoFull;
  assign wTxStreamWrite = iTxS_TVALID && oTxS_TREADY;
  assign wTxPush      = wTxWrite || wTxStreamWrite;
  assign wRxRead      = wRead && (iPADDR[7:0] == LP_ADDR_RXDATA) && !wRxFifoEmpty;
  assign wSpiStartPulse = !wSpiBusy && !wSpiDone && !wTxFifoEmpty;
  assign wRxPush      = wSpiDone && !wRxFifoFull;
  assign wTxWrPtrNext = (rTxWrPtr == (P_FIFO_DEPTH - 1)) ? '0 : rTxWrPtr + 1'b1;
  assign wTxRdPtrNext = (rTxRdPtr == (P_FIFO_DEPTH - 1)) ? '0 : rTxRdPtr + 1'b1;
  assign wRxWrPtrNext = (rRxWrPtr == (P_FIFO_DEPTH - 1)) ? '0 : rRxWrPtr + 1'b1;
  assign wRxRdPtrNext = (rRxRdPtr == (P_FIFO_DEPTH - 1)) ? '0 : rRxRdPtr + 1'b1;
  assign oPREADY      = 1'b1;
  assign oPSLVERR     = 1'b0;
  assign wActiveCsSel = wSpiBusy ? rActiveCsSel : rCsSel;
  assign oTxIrq       = rTxIrqEnable && rDoneSticky;
  assign oRxIrq       = rRxIrqEnable && !wRxFifoEmpty;
  assign oTxDmaReq    = oTxS_TREADY;
  assign oRxDmaReq    = rRxDmaEnable && !wRxFifoEmpty;

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rClkCnt <= 16'd0;
      rTick   <= 1'b0;
    end
    else begin
      rTick <= 1'b0;

      if (wSpiBusy || wSpiStartPulse) begin
        if (rClkCnt >= rClkDiv) begin
          rClkCnt <= 16'd0;
          rTick   <= 1'b1;
        end
        else begin
          rClkCnt <= rClkCnt + 16'd1;
        end
      end
      else begin
        rClkCnt <= 16'd0;
      end
    end
  end

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rCpol           <= 1'b0;
      rCpha           <= 1'b0;
      rCsSel          <= 2'd0;
      rTxIrqEnable    <= 1'b0;
      rRxIrqEnable    <= 1'b0;
      rTxDmaEnable    <= 1'b0;
      rRxDmaEnable    <= 1'b0;
      rActiveCsSel    <= 2'd0;
      rClkDiv         <= 16'd1;
      rDoneSticky     <= 1'b0;
      rRxValidSticky  <= 1'b0;
      rRxOverrunSticky <= 1'b0;
      rTxWrPtr        <= '0;
      rTxRdPtr        <= '0;
      rTxCount        <= '0;
      rRxWrPtr        <= '0;
      rRxRdPtr        <= '0;
      rRxCount        <= '0;

      for (idx = 0; idx < P_FIFO_DEPTH; idx = idx + 1) begin
        rTxFifo[idx] <= 8'd0;
        rRxFifo[idx] <= 8'd0;
      end
    end
    else begin
      if (wSpiDone) begin
        rDoneSticky <= 1'b1;

        if (wRxFifoFull) begin
          rRxOverrunSticky <= 1'b1;
        end
        else begin
          rRxFifo[rRxWrPtr] <= wSpiRxData;
          rRxWrPtr          <= wRxWrPtrNext;
          rRxValidSticky    <= 1'b1;
        end
      end

      if (wSpiStartPulse) begin
        rDoneSticky  <= 1'b0;
        rActiveCsSel <= rCsSel;
        rTxRdPtr     <= wTxRdPtrNext;
      end

      if (wTxPush) begin
        rTxFifo[rTxWrPtr] <= wTxWrite ? iPWDATA[7:0] : iTxS_TDATA;
        rTxWrPtr          <= wTxWrPtrNext;
      end

      if (wRxRead) begin
        rRxRdPtr <= wRxRdPtrNext;
      end

      unique case ({wTxPush, wSpiStartPulse})
        2'b10: rTxCount <= rTxCount + 1'b1;
        2'b01: rTxCount <= rTxCount - 1'b1;
        default: begin end
      endcase

      unique case ({wRxPush, wRxRead})
        2'b10: rRxCount <= rRxCount + 1'b1;
        2'b01: rRxCount <= rRxCount - 1'b1;
        default: begin end
      endcase

      if (wRxRead && (rRxCount == {{(LP_CNT_WIDTH-1){1'b0}}, 1'b1}) && !wRxPush) begin
        rRxValidSticky <= 1'b0;
      end

      if (wWrite) begin
        unique case (iPADDR[7:0])
          LP_ADDR_CTRL: begin
            if (iPSTRB[0] && !wSpiBusy) begin
              rCpol        <= iPWDATA[1];
              rCpha        <= iPWDATA[2];
              rTxIrqEnable <= iPWDATA[3];
              rRxIrqEnable <= iPWDATA[4];
              rTxDmaEnable <= iPWDATA[5];
              rRxDmaEnable <= iPWDATA[6];
              rCsSel       <= iPWDATA[9:8];
            end
          end

          LP_ADDR_STATUS: begin
            if (iPSTRB[0]) begin
              if (iPWDATA[1]) begin
                rDoneSticky <= 1'b0;
              end

              if (iPWDATA[2]) begin
                rRxValidSticky <= 1'b0;
              end

              if (iPWDATA[3]) begin
                rRxOverrunSticky <= 1'b0;
              end
            end
          end

          LP_ADDR_CLKDIV: begin
            if (!wSpiBusy) begin
              rClkDiv <= iPWDATA[15:0];
            end
          end

          default: begin
          end
        endcase
      end
    end
  end

  SpiMaster uSpiMaster (
    .iClk    (iPclk),
    .iRstn   (iPresetn),
    .iTick   (rTick),
    .iStart  (wSpiStartPulse),
    .iCpol   (rCpol),
    .iCpha   (rCpha),
    .iTxData (rTxFifo[rTxRdPtr]),
    .iMiso   (iSpiMiso),
    .oRxData (wSpiRxData),
    .oBusy   (wSpiBusy),
    .oDone   (wSpiDone),
    .oSclk   (oSpiSclk),
    .oCsN    (wSpiCsN),
    .oMosi   (oSpiMosi)
  );

  always_comb begin
    oSpiCsN = 4'b1111;

    unique case (wActiveCsSel)
      2'd0: oSpiCsN[0] = wSpiCsN;
      2'd1: oSpiCsN[1] = wSpiCsN;
      2'd2: oSpiCsN[2] = wSpiCsN;
      default: oSpiCsN[3] = wSpiCsN;
    endcase
  end

  always_comb begin
    oPRDATA = 32'd0;

    unique case (iPADDR[7:0])
      LP_ADDR_CTRL: begin
        oPRDATA = {22'd0, rCsSel, rRxDmaEnable, rTxDmaEnable,
                   rRxIrqEnable, rTxIrqEnable, rCpha, rCpol, 1'b0};
      end

      LP_ADDR_STATUS: begin
        oPRDATA = {24'd0, wRxFifoEmpty, wRxFifoFull, wTxFifoEmpty, wTxFifoFull,
                   rRxOverrunSticky, (rRxValidSticky || !wRxFifoEmpty),
                   rDoneSticky, wSpiBusy};
      end

      LP_ADDR_CLKDIV: begin
        oPRDATA = {16'd0, rClkDiv};
      end

      LP_ADDR_TXDATA: begin
        oPRDATA = wTxFifoEmpty ? 32'd0 : {24'd0, rTxFifo[rTxRdPtr]};
      end

      LP_ADDR_RXDATA: begin
        oPRDATA = wRxFifoEmpty ? 32'd0 : {24'd0, rRxFifo[rRxRdPtr]};
      end

      default: begin
        oPRDATA = 32'd0;
      end
    endcase
  end

endmodule
