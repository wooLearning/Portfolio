`timescale 1ns / 1ps

module Top (
  input  logic        iClk100M,
  input  logic        iReset,
  input  logic [15:0] iSw,
  input  logic [3:0]  iBtn,
  output logic [15:0] oLed,
  inout  wire  [15:0] ioGpioB,
  input  logic        iSpiMiso,
  input  logic        oSpiSclk,
  output logic        oSpiMosi,
  input  logic [3:0]  oSpiCsN,
  inout  wire         ioI2cScl,
  inout  wire         ioI2cSda,
  input  logic        iUartRx,
  output logic        oUartTx
);

  localparam logic [15:0] LP_UART_DIV_115200 = 16'd53;
  localparam logic [15:0] LP_UART_DIV_921600 = 16'd6;

  logic        wRstn;
  logic [15:0] rBaudDiv;
  logic [15:0] rBaudCnt;
  logic        rTick16x;
  logic [7:0]  wSpiRxData;
  logic        wSpiRxValid;
  logic        wSpiRxReady;
  logic        wSpiOverflow;
  logic [31:0] wSpiRxCount;
  logic        wFifoWrReady;
  logic [7:0]  wFifoRdData;
  logic        wFifoRdValid;
  logic        wFifoRdReady;
  logic        wFifoFull;
  logic        wFifoEmpty;
  logic [14:0] wFifoLevel;
  logic        rUartTxValid;
  logic [7:0]  rUartTxData;
  logic        wUartBusy;
  logic        wUartDone;
  logic        rFifoOverflow;

  assign wRstn = ~iReset;
  assign ioI2cScl = 1'bz;
  assign ioI2cSda = 1'bz;
  assign ioGpioB = 16'hzzzz;
  assign wSpiRxReady = wFifoWrReady;
  assign wFifoRdReady = !wUartBusy && !rUartTxValid && wFifoRdValid;

  always_comb begin
    oLed = {
      wFifoFull,
      rFifoOverflow | wSpiOverflow,
      iSw[15],
      wFifoEmpty,
      wFifoLevel[11:0]
    };
  end

  always_ff @(posedge iClk100M or negedge wRstn) begin
    if (!wRstn) begin
      rBaudDiv <= LP_UART_DIV_115200;
      rBaudCnt <= 16'd0;
      rTick16x <= 1'b0;
    end
    else begin
      rBaudDiv <= iSw[15] ? LP_UART_DIV_921600 : LP_UART_DIV_115200;
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

  always_ff @(posedge iClk100M or negedge wRstn) begin
    if (!wRstn) begin
      rFifoOverflow <= 1'b0;
    end
    else begin
      if (wSpiRxValid && !wFifoWrReady) begin
        rFifoOverflow <= 1'b1;
      end

      if (iBtn[0]) begin
        rFifoOverflow <= 1'b0;
      end
    end
  end

  always_ff @(posedge iClk100M or negedge wRstn) begin
    if (!wRstn) begin
      rUartTxValid <= 1'b0;
      rUartTxData  <= 8'd0;
    end
    else begin
      rUartTxValid <= 1'b0;

      if (wFifoRdReady) begin
        rUartTxData  <= wFifoRdData;
        rUartTxValid <= 1'b1;
      end
    end
  end

  SpiSlaveByteRx uSpiSlaveByteRx (
    .iClk       (iClk100M),
    .iRstn      (wRstn),
    .iSpiSclk   (oSpiSclk),
    .iSpiMosi   (iSpiMiso),
    .iSpiCsN    (oSpiCsN[0]),
    .oSpiMiso   (oSpiMosi),
    .oRxData    (wSpiRxData),
    .oRxValid   (wSpiRxValid),
    .iRxReady   (wSpiRxReady),
    .oOverflow  (wSpiOverflow),
    .oRxCount   (wSpiRxCount)
  );

  ByteFifo #(
    .P_DEPTH(16384)
  ) uByteFifo (
    .iClk      (iClk100M),
    .iRstn     (wRstn),
    .iWrData   (wSpiRxData),
    .iWrValid  (wSpiRxValid),
    .oWrReady  (wFifoWrReady),
    .oRdData   (wFifoRdData),
    .oRdValid  (wFifoRdValid),
    .iRdReady  (wFifoRdReady),
    .oFull     (wFifoFull),
    .oEmpty    (wFifoEmpty),
    .oLevel    (wFifoLevel)
  );

  UartTx uUartTx (
    .iClk     (iClk100M),
    .iRstn    (wRstn),
    .iTick16x (rTick16x),
    .iData    (rUartTxData),
    .iValid   (rUartTxValid),
    .oTx      (oUartTx),
    .oBusy    (wUartBusy),
    .oDone    (wUartDone)
  );

endmodule
