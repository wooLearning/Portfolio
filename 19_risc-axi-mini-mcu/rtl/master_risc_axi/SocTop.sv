`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: SocTop
Role: AXI-Lite based RISC-V MCU top with APB peripherals and AXI-Stream DMA
Summary:
  - Uses a local ICode ROM fast path for instruction fetch
  - Converts core DBus local ports into an AXI-Lite master
  - Uses AXI-Lite ROM/SRAM/peripheral address windows
  - Bridges the peripheral AXI-Lite window to APB for timer/GPIO/SPI/UART/I2C/PLIC/DMA control
  - Keeps bulk data movement in the AXI-Stream DMA path
StateDescription:
  - Performance counters update once per clock after reset
[MODULE_INFO_END]
*/
module SocTop #(
  parameter bit P_ENABLE_DEBUG = 1'b1,
  parameter integer P_ICODE_PROGRAM = 4,
  parameter bit P_DBUS_PRE_READY = 1'b1,
  parameter string P_ICODE_MEM_FILE = "src/timing_programs/link_demo.mem"
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

  logic [31:0] wRomAWADDR;
  logic        wRomAWVALID;
  logic        wRomAWREADY;
  logic [31:0] wRomWDATA;
  logic [3:0]  wRomWSTRB;
  logic        wRomWVALID;
  logic        wRomWREADY;
  logic [1:0]  wRomBRESP;
  logic        wRomBVALID;
  logic        wRomBREADY;
  logic [31:0] wRomARADDR;
  logic        wRomARVALID;
  logic        wRomARREADY;
  logic [31:0] wRomRDATA;
  logic [1:0]  wRomRRESP;
  logic        wRomRVALID;
  logic        wRomRREADY;

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
    .P_ADDR_WIDTH (12),
    .P_MEM_FILE   (P_ICODE_MEM_FILE),
    .P_SYNC_READ  (1'b1)
  ) uIcodeLocalRom (
    .iClk           (iClk),
    .iRstn          (iRstn),
    .iLocalValid    (wCoreIBusValid),
    .iLocalAddr     (wCoreIBusAddr),
    .oLocalReady    (wCoreIBusReady),
    .oLocalRData    (wCoreIBusRData),
    .oLocalError    (wCoreIBusError),
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

  AxiLiteInterconnect1x3 uAxiLiteInterconnect (
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
    .oS0_AWADDR  (wRomAWADDR),
    .oS0_AWVALID (wRomAWVALID),
    .iS0_AWREADY (wRomAWREADY),
    .oS0_WDATA   (wRomWDATA),
    .oS0_WSTRB   (wRomWSTRB),
    .oS0_WVALID  (wRomWVALID),
    .iS0_WREADY  (wRomWREADY),
    .iS0_BRESP   (wRomBRESP),
    .iS0_BVALID  (wRomBVALID),
    .oS0_BREADY  (wRomBREADY),
    .oS0_ARADDR  (wRomARADDR),
    .oS0_ARVALID (wRomARVALID),
    .iS0_ARREADY (wRomARREADY),
    .iS0_RDATA   (wRomRDATA),
    .iS0_RRESP   (wRomRRESP),
    .iS0_RVALID  (wRomRVALID),
    .oS0_RREADY  (wRomRREADY),
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
    .oS2_AWADDR  (wPeriphAWADDR),
    .oS2_AWVALID (wPeriphAWVALID),
    .iS2_AWREADY (wPeriphAWREADY),
    .oS2_WDATA   (wPeriphWDATA),
    .oS2_WSTRB   (wPeriphWSTRB),
    .oS2_WVALID  (wPeriphWVALID),
    .iS2_WREADY  (wPeriphWREADY),
    .iS2_BRESP   (wPeriphBRESP),
    .iS2_BVALID  (wPeriphBVALID),
    .oS2_BREADY  (wPeriphBREADY),
    .oS2_ARADDR  (wPeriphARADDR),
    .oS2_ARVALID (wPeriphARVALID),
    .iS2_ARREADY (wPeriphARREADY),
    .iS2_RDATA   (wPeriphRDATA),
    .iS2_RRESP   (wPeriphRRESP),
    .iS2_RVALID  (wPeriphRVALID),
    .oS2_RREADY  (wPeriphRREADY)
  );

  AxiLiteRom #(
    .P_ADDR_WIDTH (12),
    .P_MEM_FILE   (P_ICODE_MEM_FILE)
  ) uDataRom (
    .iClk       (iClk),
    .iRstn      (iRstn),
    .iS_AWADDR  (wRomAWADDR),
    .iS_AWVALID (wRomAWVALID),
    .oS_AWREADY (wRomAWREADY),
    .iS_WDATA   (wRomWDATA),
    .iS_WSTRB   (wRomWSTRB),
    .iS_WVALID  (wRomWVALID),
    .oS_WREADY  (wRomWREADY),
    .oS_BRESP   (wRomBRESP),
    .oS_BVALID  (wRomBVALID),
    .iS_BREADY  (wRomBREADY),
    .iS_ARADDR  (wRomARADDR),
    .iS_ARVALID (wRomARVALID),
    .oS_ARREADY (wRomARREADY),
    .oS_RDATA   (wRomRDATA),
    .oS_RRESP   (wRomRRESP),
    .oS_RVALID  (wRomRVALID),
    .iS_RREADY  (wRomRREADY)
  );

  AxiLiteSram #(
    .P_ADDR_WIDTH          (12),
    .P_ENABLE_DEBUG_WORDS  (P_ENABLE_DEBUG)
  ) uAxiLiteSram (
    .iClk       (iClk),
    .iRstn      (iRstn),
    .iS_AWADDR  (wSramAWADDR),
    .iS_AWVALID (wSramAWVALID),
    .oS_AWREADY (wSramAWREADY),
    .iS_WDATA   (wSramWDATA),
    .iS_WSTRB   (wSramWSTRB),
    .iS_WVALID  (wSramWVALID),
    .oS_WREADY  (wSramWREADY),
    .oS_BRESP   (wSramBRESP),
    .oS_BVALID  (wSramBVALID),
    .iS_BREADY  (wSramBREADY),
    .iS_ARADDR  (wSramARADDR),
    .iS_ARVALID (wSramARVALID),
    .oS_ARREADY (wSramARREADY),
    .oS_RDATA   (wSramRDATA),
    .oS_RRESP   (wSramRRESP),
    .oS_RVALID  (wSramRVALID),
    .iS_RREADY  (wSramRREADY),
    .oDbgWord0  (oDbgSramWord0),
    .oDbgWord1  (oDbgSramWord1),
    .oDbgWord2  (oDbgSramWord2),
    .oDbgWord3  (oDbgSramWord3)
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
    .oExternalIrq   (wExternalIrq)
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
