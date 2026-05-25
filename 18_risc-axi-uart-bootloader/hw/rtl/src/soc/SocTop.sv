`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: SocTop
Role: AXI-Lite based RISC-V MCU top with APB peripherals and AXI-Stream DMA
Summary:
  - Uses a local ICode ROM fast path for instruction fetch
  - Converts core DBus local ports into an AXI-Lite master
  - Uses AXI-Lite SRAM/peripheral address windows for DBus access
  - Routes DMA control as a direct AXI-Lite slave and bridges other peripherals to APB
  - Keeps bulk data movement in the DMA AXI-Lite master path
StateDescription:
  - Performance counters update once per clock after reset
[MODULE_INFO_END]
*/
module SocTop #(
  parameter bit P_ENABLE_DEBUG = 1'b1,
  parameter integer P_ICODE_PROGRAM = 4,
  parameter bit P_DBUS_PRE_READY = 1'b1,
  parameter string P_ICODE_MEM_FILE = "rtl/src/timing_programs/link_demo.mem"
) (
  input  logic        iClk,
  input  logic        iRstn,
  input  logic [15:0] iGpioAIn,
  input  logic [15:0] iGpioBIn,
  input  logic [15:0] iGpioCIn,
  input  logic        iSpiMiso,
  input  logic        iI2cSda,
  input  logic        iUartRx,
  output logic [15:0] oGpioAOut,
  output logic [15:0] oGpioADir,
  output logic [15:0] oGpioBOut,
  output logic [15:0] oGpioBDir,
  output logic        oSpiSclk,
  output logic        oSpiMosi,
  output logic [3:0]  oSpiCsN,
  output logic        oI2cSclDriveLow,
  output logic        oI2cSdaDriveLow,
  output logic        oUartTx,
  output logic [31:0] oDbgPc,
  output logic        oDbgDone,
  output logic [31:0] oDbgSramWord0,
  output logic [31:0] oDbgSramWord1,
  output logic [31:0] oDbgSramWord2,
  output logic [31:0] oDbgSramWord3,
  output logic [63:0] oDbgCycleCount,
  output logic [63:0] oDbgRetiredCount,
  output logic [63:0] oDbgIbusWaitCount,
  output logic [63:0] oDbgDbusWaitCount,
  output logic [63:0] oDbgDbusReadAddrWaitCount,
  output logic [63:0] oDbgDbusReadDataWaitCount,
  output logic [63:0] oDbgDbusWriteAddrWaitCount,
  output logic [63:0] oDbgDbusWriteDataWaitCount,
  output logic [63:0] oDbgDbusWriteRespWaitCount,
  output logic [31:0] oDbgIbufHitCount,
  output logic [31:0] oDbgIbufMissCount,
  output logic [31:0] oDbgIbufBurstCount
);

  logic        wCoreIBusValid;
  logic [31:0] wCoreIBusAddr;
  logic        wCoreIBusReady;
  logic [31:0] wCoreIBusRData;
  logic        wCoreIBusError;
  logic        wCoreIBusIsramSel;
  logic        wRomIBusReady;
  logic [31:0] wRomIBusRData;
  logic        wRomIBusError;
  logic [31:0] wIsramIBusAddr;
  logic        wIsramIBusReady;
  logic [31:0] wIsramIBusRData;
  logic        wIsramIBusError;
  logic        wCoreDBusValid;
  logic        wCoreDBusWrite;
  logic [31:0] wCoreDBusAddr;
  logic [1:0]  wCoreDBusSize;
  logic [31:0] wCoreDBusWData;
  logic        wCoreDBusReady;
  logic [31:0] wCoreDBusRData;
  logic        wCoreDBusError;
  logic        wDbgLoadUseStall;
  logic        wDbgBusWaitStall;
  logic        wDbgRetireValid;
  logic [1:0]  wDbgForwardA;
  logic [1:0]  wDbgForwardB;
  logic        wDbgExPcRedirectEn;
  logic        wDbgTrapEn;
  rv32i_pkg::exc_cause_e wDbgTrapCause;
  logic [31:0] wDbgMtvec;
  logic [31:0] wDbgMepc;
  logic [31:0] wDbgMcause;
  logic [31:0] wDbgMtval;

  logic [31:0] wDBusAWADDR;
  logic        wDBusAWVALID;
  logic        wDBusAWREADY;
  logic [31:0] wDBusWDATA;
  logic [3:0]  wDBusWSTRB;
  logic        wDBusWVALID;
  logic        wDBusWREADY;
  logic [1:0]  wDBusBRESP;
  logic        wDBusBVALID;
  logic        wDBusBREADY;
  logic [31:0] wDBusARADDR;
  logic        wDBusARVALID;
  logic        wDBusARREADY;
  logic [31:0] wDBusRDATA;
  logic [1:0]  wDBusRRESP;
  logic        wDBusRVALID;
  logic        wDBusRREADY;

  logic [31:0] wIsramAWADDR;
  logic        wIsramAWVALID;
  logic        wIsramAWREADY;
  logic [31:0] wIsramWDATA;
  logic [3:0]  wIsramWSTRB;
  logic        wIsramWVALID;
  logic        wIsramWREADY;
  logic [1:0]  wIsramBRESP;
  logic        wIsramBVALID;
  logic        wIsramBREADY;
  logic [31:0] wIsramARADDR;
  logic        wIsramARVALID;
  logic        wIsramARREADY;
  logic [31:0] wIsramRDATA;
  logic [1:0]  wIsramRRESP;
  logic        wIsramRVALID;
  logic        wIsramRREADY;

  logic [31:0] wSramAWADDR;
  logic        wSramAWVALID;
  logic        wSramAWREADY;
  logic [31:0] wSramWDATA;
  logic [3:0]  wSramWSTRB;
  logic        wSramWVALID;
  logic        wSramWREADY;
  logic [1:0]  wSramBRESP;
  logic        wSramBVALID;
  logic        wSramBREADY;
  logic [31:0] wSramARADDR;
  logic        wSramARVALID;
  logic        wSramARREADY;
  logic [31:0] wSramRDATA;
  logic [1:0]  wSramRRESP;
  logic        wSramRVALID;
  logic        wSramRREADY;

  logic [31:0] wDmaCtrlAWADDR;
  logic        wDmaCtrlAWVALID;
  logic        wDmaCtrlAWREADY;
  logic [31:0] wDmaCtrlWDATA;
  logic [3:0]  wDmaCtrlWSTRB;
  logic        wDmaCtrlWVALID;
  logic        wDmaCtrlWREADY;
  logic [1:0]  wDmaCtrlBRESP;
  logic        wDmaCtrlBVALID;
  logic        wDmaCtrlBREADY;
  logic [31:0] wDmaCtrlARADDR;
  logic        wDmaCtrlARVALID;
  logic        wDmaCtrlARREADY;
  logic [31:0] wDmaCtrlRDATA;
  logic [1:0]  wDmaCtrlRRESP;
  logic        wDmaCtrlRVALID;
  logic        wDmaCtrlRREADY;

  logic [31:0] wDmaAWADDR;
  logic        wDmaAWVALID;
  logic        wDmaAWREADY;
  logic [31:0] wDmaWDATA;
  logic [3:0]  wDmaWSTRB;
  logic        wDmaWVALID;
  logic        wDmaWREADY;
  logic [1:0]  wDmaBRESP;
  logic        wDmaBVALID;
  logic        wDmaBREADY;
  logic [31:0] wDmaARADDR;
  logic        wDmaARVALID;
  logic        wDmaARREADY;
  logic [31:0] wDmaRDATA;
  logic [1:0]  wDmaRRESP;
  logic        wDmaRVALID;
  logic        wDmaRREADY;

  logic [31:0] wArbSramAWADDR;
  logic        wArbSramAWVALID;
  logic        wArbSramAWREADY;
  logic [31:0] wArbSramWDATA;
  logic [3:0]  wArbSramWSTRB;
  logic        wArbSramWVALID;
  logic        wArbSramWREADY;
  logic [1:0]  wArbSramBRESP;
  logic        wArbSramBVALID;
  logic        wArbSramBREADY;
  logic [31:0] wArbSramARADDR;
  logic        wArbSramARVALID;
  logic        wArbSramARREADY;
  logic [31:0] wArbSramRDATA;
  logic [1:0]  wArbSramRRESP;
  logic        wArbSramRVALID;
  logic        wArbSramRREADY;

  logic [31:0] wPeriphAWADDR;
  logic        wPeriphAWVALID;
  logic        wPeriphAWREADY;
  logic [31:0] wPeriphWDATA;
  logic [3:0]  wPeriphWSTRB;
  logic        wPeriphWVALID;
  logic        wPeriphWREADY;
  logic [1:0]  wPeriphBRESP;
  logic        wPeriphBVALID;
  logic        wPeriphBREADY;
  logic [31:0] wPeriphARADDR;
  logic        wPeriphARVALID;
  logic        wPeriphARREADY;
  logic [31:0] wPeriphRDATA;
  logic [1:0]  wPeriphRRESP;
  logic        wPeriphRVALID;
  logic        wPeriphRREADY;

  logic        wPSEL;
  logic        wPENABLE;
  logic        wPWRITE;
  logic [31:0] wPADDR;
  logic [31:0] wPWDATA;
  logic [3:0]  wPSTRB;
  logic [31:0] wPRDATA;
  logic        wPREADY;
  logic        wPSLVERR;
  logic        wTimerIrq;
  logic        wExternalIrq;
  logic        wDmaDoneIrq;
  logic        wDmaErrorIrq;
  logic [7:0]  wDmaS_TDATA;
  logic        wDmaS_TVALID;
  logic        wDmaS_TREADY;
  logic [7:0]  wDmaM_TDATA;
  logic        wDmaM_TVALID;
  logic        wDmaM_TREADY;
  logic        wDmaM_TLAST;

  assign wCoreIBusIsramSel =
    address_map_pkg::in_range(wCoreIBusAddr, axi_lite_pkg::ISRAM_BASE, axi_lite_pkg::ISRAM_SIZE);
  assign wIsramIBusAddr = wCoreIBusAddr - axi_lite_pkg::ISRAM_BASE;
  assign wCoreIBusReady = wCoreIBusIsramSel ? wIsramIBusReady : wRomIBusReady;
  assign wCoreIBusRData = wCoreIBusIsramSel ? wIsramIBusRData : wRomIBusRData;
  assign wCoreIBusError = wCoreIBusIsramSel ? wIsramIBusError : wRomIBusError;

  assign oDbgDone =
    P_ENABLE_DEBUG &&
    (oDbgSramWord0 == 32'h0000_F2D9) &&
    (oDbgSramWord1 == 32'h0000_F234) &&
    (oDbgSramWord2 == 32'hF234_00A5) &&
    (oDbgSramWord3 == 32'hFFFF_F234);
    
  Rv32Core uCore (
    .iClk               (iClk),
    .iRstn              (iRstn),
    .oIBusValid         (wCoreIBusValid),
    .oIBusAddr          (wCoreIBusAddr),
    .iIBusReady         (wCoreIBusReady),
    .iIBusRData         (wCoreIBusRData),
    .iIBusError         (wCoreIBusError),
    .oDBusValid         (wCoreDBusValid),
    .oDBusWrite         (wCoreDBusWrite),
    .oDBusAddr          (wCoreDBusAddr),
    .oDBusSize          (wCoreDBusSize),
    .oDBusWData         (wCoreDBusWData),
    .iDBusReady         (wCoreDBusReady),
    .iDBusRData         (wCoreDBusRData),
    .iDBusError         (wCoreDBusError),
    .iSoftwareIrq       (1'b0),
    .iTimerIrq          (wTimerIrq),
    .iExternalIrq       (wExternalIrq),
    .oDbgPc             (oDbgPc),
    .oDbgLoadUseStall   (wDbgLoadUseStall),
    .oDbgBusWaitStall   (wDbgBusWaitStall),
    .oDbgRetireValid    (wDbgRetireValid),
    .oDbgForwardA       (wDbgForwardA),
    .oDbgForwardB       (wDbgForwardB),
    .oDbgExPcRedirectEn (wDbgExPcRedirectEn),
    .oDbgTrapEn         (wDbgTrapEn),
    .oDbgTrapCause      (wDbgTrapCause),
    .oDbgMtvec          (wDbgMtvec),
    .oDbgMepc           (wDbgMepc),
    .oDbgMcause         (wDbgMcause),
    .oDbgMtval          (wDbgMtval)
  );

  IcodeLocalRom #(
    .P_ADDR_WIDTH (address_map_pkg::BOOT_ROM_WORD_ADDR_WIDTH),
    .P_MEM_FILE   (P_ICODE_MEM_FILE),
    .P_SYNC_READ  (1'b1)
  ) uIcodeLocalRom (
    .iClk           (iClk),
    .iRstn          (iRstn),
    .iLocalValid    (wCoreIBusValid && !wCoreIBusIsramSel),
    .iLocalAddr     (wCoreIBusAddr),
    .oLocalReady    (wRomIBusReady),
    .oLocalRData    (wRomIBusRData),
    .oLocalError    (wRomIBusError),
    .oDbgHitCount   (oDbgIbufHitCount),
    .oDbgMissCount  (oDbgIbufMissCount),
    .oDbgBurstCount (oDbgIbufBurstCount)
  );

  AxiLiteMasterAdapter #(
    .P_READ_ONLY (1'b0),
    .P_PRE_READY (P_DBUS_PRE_READY)
  ) uDBusMaster (
    .iClk          (iClk),
    .iRstn         (iRstn),
    .iLocalValid   (wCoreDBusValid),
    .iLocalWrite   (wCoreDBusWrite),
    .iLocalAddr    (wCoreDBusAddr),
    .iLocalSize    (wCoreDBusSize),
    .iLocalWData   (wCoreDBusWData),
    .oLocalReady   (wCoreDBusReady),
    .oLocalRData   (wCoreDBusRData),
    .oLocalError   (wCoreDBusError),
    .oM_AWADDR     (wDBusAWADDR),
    .oM_AWVALID    (wDBusAWVALID),
    .iM_AWREADY    (wDBusAWREADY),
    .oM_WDATA      (wDBusWDATA),
    .oM_WSTRB      (wDBusWSTRB),
    .oM_WVALID     (wDBusWVALID),
    .iM_WREADY     (wDBusWREADY),
    .iM_BRESP      (wDBusBRESP),
    .iM_BVALID     (wDBusBVALID),
    .oM_BREADY     (wDBusBREADY),
    .oM_ARADDR     (wDBusARADDR),
    .oM_ARVALID    (wDBusARVALID),
    .iM_ARREADY    (wDBusARREADY),
    .iM_RDATA      (wDBusRDATA),
    .iM_RRESP      (wDBusRRESP),
    .iM_RVALID     (wDBusRVALID),
    .oM_RREADY     (wDBusRREADY)
  );

  AxiLiteInterconnect1x4 uAxiLiteInterconnect (
    .iClk        (iClk),
    .iRstn       (iRstn),
    .iM_AWADDR   (wDBusAWADDR),
    .iM_AWVALID  (wDBusAWVALID),
    .oM_AWREADY  (wDBusAWREADY),
    .iM_WDATA    (wDBusWDATA),
    .iM_WSTRB    (wDBusWSTRB),
    .iM_WVALID   (wDBusWVALID),
    .oM_WREADY   (wDBusWREADY),
    .oM_BRESP    (wDBusBRESP),
    .oM_BVALID   (wDBusBVALID),
    .iM_BREADY   (wDBusBREADY),
    .iM_ARADDR   (wDBusARADDR),
    .iM_ARVALID  (wDBusARVALID),
    .oM_ARREADY  (wDBusARREADY),
    .oM_RDATA    (wDBusRDATA),
    .oM_RRESP    (wDBusRRESP),
    .oM_RVALID   (wDBusRVALID),
    .iM_RREADY   (wDBusRREADY),
    .oS0_AWADDR  (wIsramAWADDR),
    .oS0_AWVALID (wIsramAWVALID),
    .iS0_AWREADY (wIsramAWREADY),
    .oS0_WDATA   (wIsramWDATA),
    .oS0_WSTRB   (wIsramWSTRB),
    .oS0_WVALID  (wIsramWVALID),
    .iS0_WREADY  (wIsramWREADY),
    .iS0_BRESP   (wIsramBRESP),
    .iS0_BVALID  (wIsramBVALID),
    .oS0_BREADY  (wIsramBREADY),
    .oS0_ARADDR  (wIsramARADDR),
    .oS0_ARVALID (wIsramARVALID),
    .iS0_ARREADY (wIsramARREADY),
    .iS0_RDATA   (wIsramRDATA),
    .iS0_RRESP   (wIsramRRESP),
    .iS0_RVALID  (wIsramRVALID),
    .oS0_RREADY  (wIsramRREADY),
    .oS1_AWADDR  (wSramAWADDR),
    .oS1_AWVALID (wSramAWVALID),
    .iS1_AWREADY (wSramAWREADY),
    .oS1_WDATA   (wSramWDATA),
    .oS1_WSTRB   (wSramWSTRB),
    .oS1_WVALID  (wSramWVALID),
    .iS1_WREADY  (wSramWREADY),
    .iS1_BRESP   (wSramBRESP),
    .iS1_BVALID  (wSramBVALID),
    .oS1_BREADY  (wSramBREADY),
    .oS1_ARADDR  (wSramARADDR),
    .oS1_ARVALID (wSramARVALID),
    .iS1_ARREADY (wSramARREADY),
    .iS1_RDATA   (wSramRDATA),
    .iS1_RRESP   (wSramRRESP),
    .iS1_RVALID  (wSramRVALID),
    .oS1_RREADY  (wSramRREADY),
    .oS2_AWADDR  (wDmaCtrlAWADDR),
    .oS2_AWVALID (wDmaCtrlAWVALID),
    .iS2_AWREADY (wDmaCtrlAWREADY),
    .oS2_WDATA   (wDmaCtrlWDATA),
    .oS2_WSTRB   (wDmaCtrlWSTRB),
    .oS2_WVALID  (wDmaCtrlWVALID),
    .iS2_WREADY  (wDmaCtrlWREADY),
    .iS2_BRESP   (wDmaCtrlBRESP),
    .iS2_BVALID  (wDmaCtrlBVALID),
    .oS2_BREADY  (wDmaCtrlBREADY),
    .oS2_ARADDR  (wDmaCtrlARADDR),
    .oS2_ARVALID (wDmaCtrlARVALID),
    .iS2_ARREADY (wDmaCtrlARREADY),
    .iS2_RDATA   (wDmaCtrlRDATA),
    .iS2_RRESP   (wDmaCtrlRRESP),
    .iS2_RVALID  (wDmaCtrlRVALID),
    .oS2_RREADY  (wDmaCtrlRREADY),
    .oS3_AWADDR  (wPeriphAWADDR),
    .oS3_AWVALID (wPeriphAWVALID),
    .iS3_AWREADY (wPeriphAWREADY),
    .oS3_WDATA   (wPeriphWDATA),
    .oS3_WSTRB   (wPeriphWSTRB),
    .oS3_WVALID  (wPeriphWVALID),
    .iS3_WREADY  (wPeriphWREADY),
    .iS3_BRESP   (wPeriphBRESP),
    .iS3_BVALID  (wPeriphBVALID),
    .oS3_BREADY  (wPeriphBREADY),
    .oS3_ARADDR  (wPeriphARADDR),
    .oS3_ARVALID (wPeriphARVALID),
    .iS3_ARREADY (wPeriphARREADY),
    .iS3_RDATA   (wPeriphRDATA),
    .iS3_RRESP   (wPeriphRRESP),
    .iS3_RVALID  (wPeriphRVALID),
    .oS3_RREADY  (wPeriphRREADY)
  );

  AxiLiteSram #(
    .P_ADDR_WIDTH          (address_map_pkg::ISRAM_WORD_ADDR_WIDTH),
    .P_ENABLE_DEBUG_WORDS  (1'b0)
  ) uAxiLiteIsram (
    .iClk        (iClk),
    .iRstn       (iRstn),
    .iS_AWADDR   (wIsramAWADDR),
    .iS_AWVALID  (wIsramAWVALID),
    .oS_AWREADY  (wIsramAWREADY),
    .iS_WDATA    (wIsramWDATA),
    .iS_WSTRB    (wIsramWSTRB),
    .iS_WVALID   (wIsramWVALID),
    .oS_WREADY   (wIsramWREADY),
    .oS_BRESP    (wIsramBRESP),
    .oS_BVALID   (wIsramBVALID),
    .iS_BREADY   (wIsramBREADY),
    .iS_ARADDR   (wIsramARADDR),
    .iS_ARVALID  (wIsramARVALID),
    .oS_ARREADY  (wIsramARREADY),
    .oS_RDATA    (wIsramRDATA),
    .oS_RRESP    (wIsramRRESP),
    .oS_RVALID   (wIsramRVALID),
    .iS_RREADY   (wIsramRREADY),
    .iILocalValid(wCoreIBusValid && wCoreIBusIsramSel),
    .iILocalAddr (wIsramIBusAddr),
    .oILocalReady(wIsramIBusReady),
    .oILocalRData(wIsramIBusRData),
    .oILocalError(wIsramIBusError),
    .oDbgWord0   (),
    .oDbgWord1   (),
    .oDbgWord2   (),
    .oDbgWord3   ()
  );

  AxiLiteArbiter2x1 uSramArbiter (
    .iClk        (iClk),
    .iRstn       (iRstn),
    .iM0_AWADDR  (wSramAWADDR),
    .iM0_AWVALID (wSramAWVALID),
    .oM0_AWREADY (wSramAWREADY),
    .iM0_WDATA   (wSramWDATA),
    .iM0_WSTRB   (wSramWSTRB),
    .iM0_WVALID  (wSramWVALID),
    .oM0_WREADY  (wSramWREADY),
    .oM0_BRESP   (wSramBRESP),
    .oM0_BVALID  (wSramBVALID),
    .iM0_BREADY  (wSramBREADY),
    .iM0_ARADDR  (wSramARADDR),
    .iM0_ARVALID (wSramARVALID),
    .oM0_ARREADY (wSramARREADY),
    .oM0_RDATA   (wSramRDATA),
    .oM0_RRESP   (wSramRRESP),
    .oM0_RVALID  (wSramRVALID),
    .iM0_RREADY  (wSramRREADY),
    .iM1_AWADDR  (wDmaAWADDR),
    .iM1_AWVALID (wDmaAWVALID),
    .oM1_AWREADY (wDmaAWREADY),
    .iM1_WDATA   (wDmaWDATA),
    .iM1_WSTRB   (wDmaWSTRB),
    .iM1_WVALID  (wDmaWVALID),
    .oM1_WREADY  (wDmaWREADY),
    .oM1_BRESP   (wDmaBRESP),
    .oM1_BVALID  (wDmaBVALID),
    .iM1_BREADY  (wDmaBREADY),
    .iM1_ARADDR  (wDmaARADDR),
    .iM1_ARVALID (wDmaARVALID),
    .oM1_ARREADY (wDmaARREADY),
    .oM1_RDATA   (wDmaRDATA),
    .oM1_RRESP   (wDmaRRESP),
    .oM1_RVALID  (wDmaRVALID),
    .iM1_RREADY  (wDmaRREADY),
    .oS_AWADDR   (wArbSramAWADDR),
    .oS_AWVALID  (wArbSramAWVALID),
    .iS_AWREADY  (wArbSramAWREADY),
    .oS_WDATA    (wArbSramWDATA),
    .oS_WSTRB    (wArbSramWSTRB),
    .oS_WVALID   (wArbSramWVALID),
    .iS_WREADY   (wArbSramWREADY),
    .iS_BRESP    (wArbSramBRESP),
    .iS_BVALID   (wArbSramBVALID),
    .oS_BREADY   (wArbSramBREADY),
    .oS_ARADDR   (wArbSramARADDR),
    .oS_ARVALID  (wArbSramARVALID),
    .iS_ARREADY  (wArbSramARREADY),
    .iS_RDATA    (wArbSramRDATA),
    .iS_RRESP    (wArbSramRRESP),
    .iS_RVALID   (wArbSramRVALID),
    .oS_RREADY   (wArbSramRREADY)
  );

  AxiLiteSram #(
    .P_ADDR_WIDTH          (address_map_pkg::DSRAM_WORD_ADDR_WIDTH),
    .P_ENABLE_DEBUG_WORDS  (P_ENABLE_DEBUG)
  ) uAxiLiteSram (
    .iClk       (iClk),
    .iRstn      (iRstn),
    .iS_AWADDR  (wArbSramAWADDR),
    .iS_AWVALID (wArbSramAWVALID),
    .oS_AWREADY (wArbSramAWREADY),
    .iS_WDATA   (wArbSramWDATA),
    .iS_WSTRB   (wArbSramWSTRB),
    .iS_WVALID  (wArbSramWVALID),
    .oS_WREADY  (wArbSramWREADY),
    .oS_BRESP   (wArbSramBRESP),
    .oS_BVALID  (wArbSramBVALID),
    .iS_BREADY  (wArbSramBREADY),
    .iS_ARADDR  (wArbSramARADDR),
    .iS_ARVALID (wArbSramARVALID),
    .oS_ARREADY (wArbSramARREADY),
    .oS_RDATA   (wArbSramRDATA),
    .oS_RRESP   (wArbSramRRESP),
    .oS_RVALID  (wArbSramRVALID),
    .iS_RREADY  (wArbSramRREADY),
    .iILocalValid(1'b0),
    .iILocalAddr (32'd0),
    .oILocalReady(),
    .oILocalRData(),
    .oILocalError(),
    .oDbgWord0  (oDbgSramWord0),
    .oDbgWord1  (oDbgSramWord1),
    .oDbgWord2  (oDbgSramWord2),
    .oDbgWord3  (oDbgSramWord3)
  );

  DmaAxiLiteAxis #(
    .P_SRAM_BASE  (address_map_pkg::DSRAM_BASE),
    .P_SRAM_BYTES (address_map_pkg::DSRAM_SIZE)
  ) uDmaAxiLiteAxis (
    .iClk        (iClk),
    .iRstn       (iRstn),
    .iS_AWADDR   (wDmaCtrlAWADDR),
    .iS_AWVALID  (wDmaCtrlAWVALID),
    .oS_AWREADY  (wDmaCtrlAWREADY),
    .iS_WDATA    (wDmaCtrlWDATA),
    .iS_WSTRB    (wDmaCtrlWSTRB),
    .iS_WVALID   (wDmaCtrlWVALID),
    .oS_WREADY   (wDmaCtrlWREADY),
    .oS_BRESP    (wDmaCtrlBRESP),
    .oS_BVALID   (wDmaCtrlBVALID),
    .iS_BREADY   (wDmaCtrlBREADY),
    .iS_ARADDR   (wDmaCtrlARADDR),
    .iS_ARVALID  (wDmaCtrlARVALID),
    .oS_ARREADY  (wDmaCtrlARREADY),
    .oS_RDATA    (wDmaCtrlRDATA),
    .oS_RRESP    (wDmaCtrlRRESP),
    .oS_RVALID   (wDmaCtrlRVALID),
    .iS_RREADY   (wDmaCtrlRREADY),
    .oDoneIrq    (wDmaDoneIrq),
    .oErrorIrq   (wDmaErrorIrq),
    .iS_TDATA    (wDmaS_TDATA),
    .iS_TVALID   (wDmaS_TVALID),
    .oS_TREADY   (wDmaS_TREADY),
    .iS_TLAST    (1'b0),
    .oM_TDATA    (wDmaM_TDATA),
    .oM_TVALID   (wDmaM_TVALID),
    .iM_TREADY   (wDmaM_TREADY),
    .oM_TLAST    (wDmaM_TLAST),
    .oM_AWADDR   (wDmaAWADDR),
    .oM_AWVALID  (wDmaAWVALID),
    .iM_AWREADY  (wDmaAWREADY),
    .oM_WDATA    (wDmaWDATA),
    .oM_WSTRB    (wDmaWSTRB),
    .oM_WVALID   (wDmaWVALID),
    .iM_WREADY   (wDmaWREADY),
    .iM_BRESP    (wDmaBRESP),
    .iM_BVALID   (wDmaBVALID),
    .oM_BREADY   (wDmaBREADY),
    .oM_ARADDR   (wDmaARADDR),
    .oM_ARVALID  (wDmaARVALID),
    .iM_ARREADY  (wDmaARREADY),
    .iM_RDATA    (wDmaRDATA),
    .iM_RRESP    (wDmaRRESP),
    .iM_RVALID   (wDmaRVALID),
    .oM_RREADY   (wDmaRREADY)
  );

  AxiLiteToApbBridge uAxiLiteToApbBridge (
    .iClk       (iClk),
    .iRstn      (iRstn),
    .iS_AWADDR  (wPeriphAWADDR),
    .iS_AWVALID (wPeriphAWVALID),
    .oS_AWREADY (wPeriphAWREADY),
    .iS_WDATA   (wPeriphWDATA),
    .iS_WSTRB   (wPeriphWSTRB),
    .iS_WVALID  (wPeriphWVALID),
    .oS_WREADY  (wPeriphWREADY),
    .oS_BRESP   (wPeriphBRESP),
    .oS_BVALID  (wPeriphBVALID),
    .iS_BREADY  (wPeriphBREADY),
    .iS_ARADDR  (wPeriphARADDR),
    .iS_ARVALID (wPeriphARVALID),
    .oS_ARREADY (wPeriphARREADY),
    .oS_RDATA   (wPeriphRDATA),
    .oS_RRESP   (wPeriphRRESP),
    .oS_RVALID  (wPeriphRVALID),
    .iS_RREADY  (wPeriphRREADY),
    .oPSEL      (wPSEL),
    .oPENABLE   (wPENABLE),
    .oPWRITE    (wPWRITE),
    .oPADDR     (wPADDR),
    .oPWDATA    (wPWDATA),
    .oPSTRB     (wPSTRB),
    .iPRDATA    (wPRDATA),
    .iPREADY    (wPREADY),
    .iPSLVERR   (wPSLVERR)
  );

  ApbSubsystem uApbSubsystem (
    .iPclk          (iClk),
    .iPresetn       (iRstn),
    .iPSEL          (wPSEL),
    .iPENABLE       (wPENABLE),
    .iPWRITE        (wPWRITE),
    .iPADDR         (wPADDR),
    .iPWDATA        (wPWDATA),
    .iPSTRB         (wPSTRB),
    .iPeripheralIrq (8'd0),
    .iGpioAIn       (iGpioAIn),
    .iGpioBIn       (iGpioBIn),
    .iGpioCIn       (iGpioCIn),
    .iSpiMiso       (iSpiMiso),
    .iI2cSda        (iI2cSda),
    .iUartRx        (iUartRx),
    .oGpioAOut      (oGpioAOut),
    .oGpioADir      (oGpioADir),
    .oGpioBOut      (oGpioBOut),
    .oGpioBDir      (oGpioBDir),
    .oSpiSclk       (oSpiSclk),
    .oSpiMosi       (oSpiMosi),
    .oSpiCsN        (oSpiCsN),
    .oI2cSclDriveLow(oI2cSclDriveLow),
    .oI2cSdaDriveLow(oI2cSdaDriveLow),
    .oUartTx        (oUartTx),
    .oPRDATA        (wPRDATA),
    .oPREADY        (wPREADY),
    .oPSLVERR       (wPSLVERR),
    .oTimerIrq      (wTimerIrq),
    .oExternalIrq   (wExternalIrq),
    .iDmaDoneIrq    (wDmaDoneIrq),
    .iDmaErrorIrq   (wDmaErrorIrq),
    .oDmaS_TDATA    (wDmaS_TDATA),
    .oDmaS_TVALID   (wDmaS_TVALID),
    .iDmaS_TREADY   (wDmaS_TREADY),
    .iDmaM_TDATA    (wDmaM_TDATA),
    .iDmaM_TVALID   (wDmaM_TVALID),
    .oDmaM_TREADY   (wDmaM_TREADY)
  );

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      oDbgCycleCount    <= 64'd0;
      oDbgRetiredCount  <= 64'd0;
      oDbgIbusWaitCount <= 64'd0;
      oDbgDbusWaitCount <= 64'd0;
      oDbgDbusReadAddrWaitCount  <= 64'd0;
      oDbgDbusReadDataWaitCount  <= 64'd0;
      oDbgDbusWriteAddrWaitCount <= 64'd0;
      oDbgDbusWriteDataWaitCount <= 64'd0;
      oDbgDbusWriteRespWaitCount <= 64'd0;
    end
    else begin
      oDbgCycleCount <= oDbgCycleCount + 64'd1;

      if (wDbgRetireValid) begin
        oDbgRetiredCount <= oDbgRetiredCount + 64'd1;
      end

      if (wCoreIBusValid && !wCoreIBusReady) begin
        oDbgIbusWaitCount <= oDbgIbusWaitCount + 64'd1;
      end

      if (wCoreDBusValid && !wCoreDBusReady) begin
        oDbgDbusWaitCount <= oDbgDbusWaitCount + 64'd1;
      end

      if (wDBusARVALID && !wDBusARREADY) begin
        oDbgDbusReadAddrWaitCount <= oDbgDbusReadAddrWaitCount + 64'd1;
      end

      if (wDBusRREADY && !wDBusRVALID && !(wDBusARVALID && !wDBusARREADY)) begin
        oDbgDbusReadDataWaitCount <= oDbgDbusReadDataWaitCount + 64'd1;
      end

      if (wDBusAWVALID && !wDBusAWREADY) begin
        oDbgDbusWriteAddrWaitCount <= oDbgDbusWriteAddrWaitCount + 64'd1;
      end

      if (wDBusWVALID && !wDBusWREADY) begin
        oDbgDbusWriteDataWaitCount <= oDbgDbusWriteDataWaitCount + 64'd1;
      end

      if (wDBusBREADY && !wDBusBVALID &&
          !(wDBusAWVALID && !wDBusAWREADY) &&
          !(wDBusWVALID && !wDBusWREADY)) begin
        oDbgDbusWriteRespWaitCount <= oDbgDbusWriteRespWaitCount + 64'd1;
      end
    end
  end

endmodule
