`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: SocFpgaTop
Role: FPGA-board top wrapper for SocTop
Summary:
  - Keeps SocTop as the existing simulation/debug top
  - Exposes board-usable GPIO, SPI, I2C, and UART pins
  - Removes wide debug buses from the FPGA top-level I/O
StateDescription:
  - No additional state; all state remains inside SocTop
[MODULE_INFO_END]
*/
module SocFpgaTop #(
  parameter string P_ICODE_MEM_FILE = "rtl/src/timing_programs/uart_loader.mem"
) (
  input  logic        iClk100M,
  input  logic        iReset,
  input  logic [15:0] iSw,
  input  logic [3:0]  iBtn,
  output logic [15:0] oLed,
  inout  wire  [15:0] ioGpioB,
  input  logic        iSpiMiso,
  output logic        oSpiSclk,
  output logic        oSpiMosi,
  output logic [3:0]  oSpiCsN,
  inout  wire         ioI2cScl,
  inout  wire         ioI2cSda,
  input  logic        iUartRx,
  output logic        oUartTx
);

  logic        wRstn;
  logic        wSocClk;
  logic        rSocClkDiv;
  logic [15:0] wGpioADir;
  logic [15:0] wGpioBIn;
  logic [15:0] wGpioBOut;
  logic [15:0] wGpioBDir;
  logic [3:0]  wBtnSync;
  logic [15:0] wGpioCIn;
  logic        wI2cSclDriveLow;
  logic        wI2cSdaDriveLow;
  logic        wSocUartRx;
  logic        wSocUartTx;
  logic [31:0] wDbgPc;
  logic        wDbgDone;
  logic [31:0] wDbgSramWord0;
  logic [31:0] wDbgSramWord1;
  logic [31:0] wDbgSramWord2;
  logic [31:0] wDbgSramWord3;
  logic [63:0] wDbgCycleCount;
  logic [63:0] wDbgRetiredCount;
  logic [63:0] wDbgIbusWaitCount;
  logic [63:0] wDbgDbusWaitCount;
  logic [63:0] wDbgDbusReadAddrWaitCount;
  logic [63:0] wDbgDbusReadDataWaitCount;
  logic [63:0] wDbgDbusWriteAddrWaitCount;
  logic [63:0] wDbgDbusWriteDataWaitCount;
  logic [63:0] wDbgDbusWriteRespWaitCount;
  logic [31:0] wDbgIbufHitCount;
  logic [31:0] wDbgIbufMissCount;
  logic [31:0] wDbgIbufBurstCount;

  assign wRstn = ~iReset;
  assign wGpioBIn = {ioGpioB[15:2], 2'b00};
  assign wGpioCIn = {12'd0, wBtnSync};
  assign wSocUartRx = iSw[8] ? ioGpioB[1] : iUartRx;
  assign oUartTx = wSocUartTx;
  assign ioGpioB[1] = 1'bz;

  OBUFT uPeerUartTxBuf (
    .I (wSocUartTx),
    .T (1'b0),
    .O (ioGpioB[0])
  );

  genvar gGpioB;
  generate
    for (gGpioB = 2; gGpioB < 16; gGpioB = gGpioB + 1) begin : g_gpio_b_iobuf
      assign ioGpioB[gGpioB] = wGpioBDir[gGpioB] ? wGpioBOut[gGpioB] : 1'bz;
    end
  endgenerate

  assign ioI2cScl = wI2cSclDriveLow ? 1'b0 : 1'bz;
  assign ioI2cSda = wI2cSdaDriveLow ? 1'b0 : 1'bz;

  always_ff @(posedge iClk100M or negedge wRstn) begin
    if (!wRstn) begin
      rSocClkDiv <= 1'b0;
    end
    else begin
      rSocClkDiv <= ~rSocClkDiv;
    end
  end

  BUFG uSocClkBuf (
    .I (rSocClkDiv),
    .O (wSocClk)
  );

  ButtonGpioSync #(
    .P_WIDTH(4)
  ) uButtonGpioSync (
    .iClk     (wSocClk),
    .iRstn    (wRstn),
    .iBtnRaw  (iBtn),
    .oBtnSync (wBtnSync)
  );

  SocTop #(
    .P_ENABLE_DEBUG (1'b0),
    .P_ICODE_PROGRAM(4),
    .P_ICODE_MEM_FILE(P_ICODE_MEM_FILE)
  ) uSocTop (
    .iClk              (wSocClk),
    .iRstn             (wRstn),
    .iGpioAIn          (iSw),
    .iGpioBIn          (wGpioBIn),
    .iGpioCIn          (wGpioCIn),
    .iSpiMiso          (iSpiMiso),
    .iI2cSda           (ioI2cSda),
    .iUartRx           (wSocUartRx),
    .oGpioAOut         (oLed),
    .oGpioADir         (wGpioADir),
    .oGpioBOut         (wGpioBOut),
    .oGpioBDir         (wGpioBDir),
    .oSpiSclk          (oSpiSclk),
    .oSpiMosi          (oSpiMosi),
    .oSpiCsN           (oSpiCsN),
    .oI2cSclDriveLow         (wI2cSclDriveLow),
    .oI2cSdaDriveLow         (wI2cSdaDriveLow),
    .oUartTx           (wSocUartTx),
    .oDbgPc            (wDbgPc),
    .oDbgDone          (wDbgDone),
    .oDbgSramWord0     (wDbgSramWord0),
    .oDbgSramWord1     (wDbgSramWord1),
    .oDbgSramWord2     (wDbgSramWord2),
    .oDbgSramWord3     (wDbgSramWord3),
    .oDbgCycleCount    (wDbgCycleCount),
    .oDbgRetiredCount  (wDbgRetiredCount),
    .oDbgIbusWaitCount (wDbgIbusWaitCount),
    .oDbgDbusWaitCount (wDbgDbusWaitCount),
    .oDbgDbusReadAddrWaitCount (wDbgDbusReadAddrWaitCount),
    .oDbgDbusReadDataWaitCount (wDbgDbusReadDataWaitCount),
    .oDbgDbusWriteAddrWaitCount(wDbgDbusWriteAddrWaitCount),
    .oDbgDbusWriteDataWaitCount(wDbgDbusWriteDataWaitCount),
    .oDbgDbusWriteRespWaitCount(wDbgDbusWriteRespWaitCount),
    .oDbgIbufHitCount  (wDbgIbufHitCount),
    .oDbgIbufMissCount (wDbgIbufMissCount),
    .oDbgIbufBurstCount(wDbgIbufBurstCount)
  );

endmodule
