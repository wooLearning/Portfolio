`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: SocStressFpgaTop
Role: FPGA timing wrapper for the SocTop stress/readmemh program
Summary:
  - Instantiates SocTop with P_ICODE_PROGRAM=3
  - Uses the board clock directly so timing reports measure the SoC clock path
  - Keeps debug buses internal while preserving representative board I/O
StateDescription:
  - No additional state; all benchmark state is inside SocTop
[MODULE_INFO_END]
*/
module SocStressFpgaTop (
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
  logic [15:0] wGpioADir;
  logic [15:0] wGpioBIn;
  logic [15:0] wGpioBOut;
  logic [15:0] wGpioBDir;
  logic [15:0] wGpioCIn;
  logic        wI2cSclDriveLow;
  logic        wI2cSdaDriveLow;
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
  assign wGpioBIn = ioGpioB;
  assign wGpioCIn = {12'd0, iBtn};

  genvar gGpioB;
  generate
    for (gGpioB = 0; gGpioB < 16; gGpioB = gGpioB + 1) begin : g_gpio_b_iobuf
      assign ioGpioB[gGpioB] = wGpioBDir[gGpioB] ? wGpioBOut[gGpioB] : 1'bz;
    end
  endgenerate

  assign ioI2cScl = wI2cSclDriveLow ? 1'b0 : 1'bz;
  assign ioI2cSda = wI2cSdaDriveLow ? 1'b0 : 1'bz;

  SocTop #(
    .P_ENABLE_DEBUG  (1'b0),
    .P_ICODE_PROGRAM (3)
  ) uSocTop (
    .iClk              (iClk100M),
    .iRstn             (wRstn),
    .iGpioAIn          (iSw),
    .iGpioBIn          (wGpioBIn),
    .iGpioCIn          (wGpioCIn),
    .iSpiMiso          (iSpiMiso),
    .iI2cSda           (ioI2cSda),
    .iUartRx           (iUartRx),
    .oGpioAOut         (oLed),
    .oGpioADir         (wGpioADir),
    .oGpioBOut         (wGpioBOut),
    .oGpioBDir         (wGpioBDir),
    .oSpiSclk          (oSpiSclk),
    .oSpiMosi          (oSpiMosi),
    .oSpiCsN           (oSpiCsN),
    .oI2cSclDriveLow         (wI2cSclDriveLow),
    .oI2cSdaDriveLow         (wI2cSdaDriveLow),
    .oUartTx           (oUartTx),
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
