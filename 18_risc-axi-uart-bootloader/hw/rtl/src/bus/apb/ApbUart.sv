`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbUart
Role: APB wrapper for 8N1 UART TX/RX with small FIFOs
Summary:
  - Exposes CTRL, STATUS, BAUDDIV, TXDATA, and RXDATA registers
  - Keeps legacy TXDATA write plus CTRL.START software flow working
  - Adds TX/RX interrupt enables and TX/RX DMA request enables
  - TXDATA writes enqueue TX FIFO bytes; RXDATA reads pop RX FIFO bytes
StateDescription:
  - UART TX/RX serial state is held in the wrapped UartTx and UartRx modules
  - FIFO pointers/counts track queued TX and received RX bytes
[MODULE_INFO_END]
*/
module ApbUart #(
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
  input  logic        iUartRx,
  output logic        oUartTx,
  output logic [31:0] oPRDATA,
  output logic        oPREADY,
  output logic        oPSLVERR,
  output logic        oTxIrq,
  output logic        oRxIrq,
  output logic        oTxDmaReq,
  output logic        oRxDmaReq,
  output logic [7:0]  oRxM_TDATA,
  output logic        oRxM_TVALID,
  input  logic        iRxM_TREADY
);

  localparam logic [7:0] LP_ADDR_CTRL    = 8'h00;
  localparam logic [7:0] LP_ADDR_STATUS  = 8'h04;
  localparam logic [7:0] LP_ADDR_BAUDDIV = 8'h08;
  localparam logic [7:0] LP_ADDR_TXDATA  = 8'h0C;
  localparam logic [7:0] LP_ADDR_RXDATA  = 8'h10;
  localparam integer LP_CNT_WIDTH = $clog2(P_FIFO_DEPTH + 1);

  logic        wWrite;
  logic        wRead;
  logic        wTxWrite;
  logic        wRxRead;
  logic        wRxStreamPop;
  logic        wRxPop;
  logic        wTxKickPulse;
  logic [15:0] rBaudDiv;
  logic [15:0] rBaudCnt;
  logic        rTick16x;
  logic        rTxIrqEnable;
  logic        rRxIrqEnable;
  logic        rTxDmaEnable;
  logic        rRxDmaEnable;
  logic        rTxDoneSticky;
  logic        rRxValidSticky;
  logic        rRxOverrunSticky;
  logic        rFrameErrorSticky;
  logic        wTxBusy;
  logic        wTxDone;
  logic [7:0]  wRxData;
  logic        wRxValid;
  logic        wRxFrameError;
  logic [7:0]  wTxKickData;
  logic [7:0]  wTxFifoData;
  logic [7:0]  wRxFifoData;
  logic        wTxFifoFull;
  logic        wTxFifoEmpty;
  logic        wTxFifoPushReady;
  logic        wTxFifoPopValid;
  logic        wRxFifoFull;
  logic        wRxFifoEmpty;
  logic        wRxFifoPushReady;
  logic        wRxFifoPopValid;
  logic        wRxPush;
  logic [LP_CNT_WIDTH-1:0] wRxFifoCount;

  assign wWrite       = iPSEL && iPENABLE && iPWRITE;
  assign wRead        = iPSEL && iPENABLE && !iPWRITE;
  assign wTxWrite     = wWrite && (iPADDR[7:0] == LP_ADDR_TXDATA) &&
                        iPSTRB[0] && wTxFifoPushReady;
  assign wRxRead      = wRead && (iPADDR[7:0] == LP_ADDR_RXDATA) && wRxFifoPopValid;
  assign wTxFifoEmpty = !wTxFifoPopValid;
  assign wRxFifoEmpty = !wRxFifoPopValid;
  assign wTxKickPulse = !wTxBusy && wTxFifoPopValid;
  assign wTxKickData  = wTxFifoData;
  assign oPREADY      = 1'b1;
  assign oPSLVERR     = 1'b0;
  assign oTxIrq       = rTxIrqEnable && rTxDoneSticky;
  assign oRxIrq       = rRxIrqEnable && !wRxFifoEmpty;
  assign oTxDmaReq    = rTxDmaEnable && !wTxFifoFull;
  assign oRxDmaReq    = rRxDmaEnable && !wRxFifoEmpty;
  assign oRxM_TDATA   = wRxFifoData;
  assign oRxM_TVALID  = rRxDmaEnable && !wRxFifoEmpty;
  assign wRxStreamPop = oRxM_TVALID && iRxM_TREADY;
  assign wRxPop       = wRxRead || wRxStreamPop;

  assign wRxPush = wRxValid && wRxFifoPushReady;

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rBaudCnt <= 16'd0;
      rTick16x <= 1'b0;
    end
    else begin
      rTick16x <= 1'b0;

      if (rBaudCnt >= rBaudDiv) begin
        rBaudCnt <= 16'd0;
        rTick16x <= 1'b1;
      end
      else begin
        rBaudCnt <= rBaudCnt + 16'd1;
      end
    end
  end

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rBaudDiv          <= 16'd1;
      rTxIrqEnable      <= 1'b0;
      rRxIrqEnable      <= 1'b0;
      rTxDmaEnable      <= 1'b0;
      rRxDmaEnable      <= 1'b0;
      rTxDoneSticky     <= 1'b0;
      rRxValidSticky    <= 1'b0;
      rRxOverrunSticky  <= 1'b0;
      rFrameErrorSticky <= 1'b0;
    end
    else begin
      if (wTxDone) begin
        rTxDoneSticky <= 1'b1;
      end

      if (wRxValid) begin
        rRxValidSticky <= 1'b1;

        if (!wRxFifoPushReady) begin
          rRxOverrunSticky <= 1'b1;
        end
      end

      if (wRxFrameError) begin
        rFrameErrorSticky <= 1'b1;
      end

      if (wTxKickPulse) begin
        rTxDoneSticky <= 1'b0;
      end

      if (wRxPop && (wRxFifoCount == {{(LP_CNT_WIDTH-1){1'b0}}, 1'b1}) && !wRxPush) begin
        rRxValidSticky <= 1'b0;
      end

      if (wWrite) begin
        unique case (iPADDR[7:0])
          LP_ADDR_CTRL: begin
            if (iPSTRB[0]) begin
              rTxIrqEnable <= iPWDATA[1];
              rRxIrqEnable <= iPWDATA[2];
              rTxDmaEnable <= iPWDATA[3];
              rRxDmaEnable <= iPWDATA[4];
            end
          end

          LP_ADDR_STATUS: begin
            if (iPSTRB[0]) begin
              if (iPWDATA[1]) begin
                rTxDoneSticky <= 1'b0;
              end

              if (iPWDATA[2]) begin
                rRxValidSticky <= 1'b0;
              end

              if (iPWDATA[3]) begin
                rRxOverrunSticky <= 1'b0;
              end

              if (iPWDATA[4]) begin
                rFrameErrorSticky <= 1'b0;
              end
            end
          end

          LP_ADDR_BAUDDIV: begin
            rBaudDiv <= iPWDATA[15:0];
          end

          default: begin
          end
        endcase
      end
    end
  end

  ByteFifo #(
    .P_DATA_WIDTH (8),
    .P_DEPTH      (P_FIFO_DEPTH)
  ) uTxFifo (
    .iClk        (iPclk),
    .iRstn       (iPresetn),
    .iPush       (wTxWrite),
    .iPushData   (iPWDATA[7:0]),
    .oPushReady  (wTxFifoPushReady),
    .iPop        (wTxKickPulse),
    .oPopData    (wTxFifoData),
    .oPopValid   (wTxFifoPopValid),
    .oFull       (wTxFifoFull),
    .oEmpty      (),
    .oCount      ()
  );

  ByteFifo #(
    .P_DATA_WIDTH (8),
    .P_DEPTH      (P_FIFO_DEPTH)
  ) uRxFifo (
    .iClk        (iPclk),
    .iRstn       (iPresetn),
    .iPush       (wRxValid),
    .iPushData   (wRxData),
    .oPushReady  (wRxFifoPushReady),
    .iPop        (wRxPop),
    .oPopData    (wRxFifoData),
    .oPopValid   (wRxFifoPopValid),
    .oFull       (wRxFifoFull),
    .oEmpty      (),
    .oCount      (wRxFifoCount)
  );

  UartTx uUartTx (
    .iClk     (iPclk),
    .iRstn    (iPresetn),
    .iTick16x (rTick16x),
    .iData    (wTxKickData),
    .iValid   (wTxKickPulse),
    .oTx      (oUartTx),
    .oBusy    (wTxBusy),
    .oDone    (wTxDone)
  );

  UartRx uUartRx (
    .iClk         (iPclk),
    .iRstn        (iPresetn),
    .iTick16x     (rTick16x),
    .iRx          (iUartRx),
    .oData        (wRxData),
    .oValid       (wRxValid),
    .oFrameError  (wRxFrameError)
  );

  always_comb begin
    oPRDATA = 32'd0;

    unique case (iPADDR[7:0])
      LP_ADDR_CTRL: begin
        oPRDATA = {27'd0, rRxDmaEnable, rTxDmaEnable,
                   rRxIrqEnable, rTxIrqEnable, 1'b0};
      end

      LP_ADDR_STATUS: begin
        oPRDATA = {23'd0, wRxFifoEmpty, wRxFifoFull, wTxFifoEmpty, wTxFifoFull,
                   rFrameErrorSticky, rRxOverrunSticky,
                   (rRxValidSticky || !wRxFifoEmpty), rTxDoneSticky, wTxBusy};
      end

      LP_ADDR_BAUDDIV: begin
        oPRDATA = {16'd0, rBaudDiv};
      end

      LP_ADDR_TXDATA: begin
        oPRDATA = wTxFifoEmpty ? 32'd0 : {24'd0, wTxFifoData};
      end

      LP_ADDR_RXDATA: begin
        oPRDATA = wRxFifoEmpty ? 32'd0 : {24'd0, wRxFifoData};
      end

      default: begin
        oPRDATA = 32'd0;
      end
    endcase
  end

endmodule
