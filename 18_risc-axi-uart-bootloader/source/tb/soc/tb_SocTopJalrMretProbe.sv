`timescale 1ns / 1ps

module tb_SocTopJalrMretProbe;
  logic        rClk;
  logic        rRstn;
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
  logic [15:0] wGpioAOut;
  logic [15:0] wGpioADir;
  logic [15:0] wGpioBOut;
  logic [15:0] wGpioBDir;
  logic        wSpiSclk;
  logic        wSpiMosi;
  logic [3:0]  wSpiCsN;
  logic        wI2cSclDriveLow;
  logic        wI2cSdaDriveLow;
  logic        wUartTx;

  SocTop #(
    .P_ENABLE_DEBUG  (1'b1),
    .P_ICODE_MEM_FILE("rtl/src/timing_programs/jalr_mret_probe.mem")
  ) uDut (
    .iClk               (rClk),
    .iRstn              (rRstn),
    .iGpioAIn           (16'd0),
    .iGpioBIn           (16'd0),
    .iGpioCIn           (16'd0),
    .iSpiMiso           (1'b1),
    .iI2cSda            (1'b1),
    .iUartRx            (1'b1),
    .oGpioAOut          (wGpioAOut),
    .oGpioADir          (wGpioADir),
    .oGpioBOut          (wGpioBOut),
    .oGpioBDir          (wGpioBDir),
    .oSpiSclk           (wSpiSclk),
    .oSpiMosi           (wSpiMosi),
    .oSpiCsN            (wSpiCsN),
    .oI2cSclDriveLow    (wI2cSclDriveLow),
    .oI2cSdaDriveLow    (wI2cSdaDriveLow),
    .oUartTx            (wUartTx),
    .oDbgPc             (wDbgPc),
    .oDbgDone           (wDbgDone),
    .oDbgSramWord0      (wDbgSramWord0),
    .oDbgSramWord1      (wDbgSramWord1),
    .oDbgSramWord2      (wDbgSramWord2),
    .oDbgSramWord3      (wDbgSramWord3),
    .oDbgCycleCount     (wDbgCycleCount),
    .oDbgRetiredCount   (wDbgRetiredCount),
    .oDbgIbusWaitCount  (wDbgIbusWaitCount),
    .oDbgDbusWaitCount  (wDbgDbusWaitCount),
    .oDbgDbusReadAddrWaitCount (wDbgDbusReadAddrWaitCount),
    .oDbgDbusReadDataWaitCount (wDbgDbusReadDataWaitCount),
    .oDbgDbusWriteAddrWaitCount(wDbgDbusWriteAddrWaitCount),
    .oDbgDbusWriteDataWaitCount(wDbgDbusWriteDataWaitCount),
    .oDbgDbusWriteRespWaitCount(wDbgDbusWriteRespWaitCount),
    .oDbgIbufHitCount   (wDbgIbufHitCount),
    .oDbgIbufMissCount  (wDbgIbufMissCount),
    .oDbgIbufBurstCount (wDbgIbufBurstCount)
  );

  initial begin
    rClk = 1'b0;
    forever #5 rClk = ~rClk;
  end

  initial begin
    rRstn = 1'b0;
    repeat (10) @(posedge rClk);
    rRstn = 1'b1;
  end

  initial begin
    wait (rRstn);

    repeat (3000) begin
      @(posedge rClk);

      if ((wGpioADir == 16'hFFFF) && (wGpioAOut == 16'h55AA)) begin
        $display("SOC_JALR_MRET_PROBE_PASS cycle=%0d retired=%0d pc=0x%08h gpio=0x%04h mcause=0x%08h mepc=0x%08h",
                 wDbgCycleCount,
                 wDbgRetiredCount,
                 wDbgPc,
                 wGpioAOut,
                 uDut.uCore.wCsrMcause,
                 uDut.uCore.wCsrMepc);
        $finish;
      end
    end

    $display("SOC_JALR_MRET_PROBE_TIMEOUT cycle=%0d retired=%0d pc=0x%08h gpio_dir=0x%04h gpio=0x%04h mtvec=0x%08h mcause=0x%08h mepc=0x%08h mstatus=0x%08h",
             wDbgCycleCount,
             wDbgRetiredCount,
             wDbgPc,
             wGpioADir,
             wGpioAOut,
             uDut.uCore.wCsrMtvec,
             uDut.uCore.wCsrMcause,
             uDut.uCore.wCsrMepc,
             uDut.uCore.wCsrMstatus);
    $fatal(1, "JALR/MRET probe did not reach pass loop");
  end
endmodule
