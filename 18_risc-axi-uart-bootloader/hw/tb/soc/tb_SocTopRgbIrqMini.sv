`timescale 1ns / 1ps

module tb_SocTopRgbIrqMini;
  localparam integer LP_BIT_CLKS = 432;
  localparam integer LP_IMAGE_BYTES = 4;

  logic        rClk;
  logic        rRstn;
  logic        rUartRx;
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
  integer      rSpiFrameCount;
  integer      rDoneIrqSeen;
  integer      rPlicRequestSeen;
  integer      rTrapSeen;
  integer      rTrapVectorSeen;

  SocTop #(
    .P_ENABLE_DEBUG  (1'b1),
    .P_ICODE_MEM_FILE("rtl/src/timing_programs/uart_dma_spi_rgb_irq_forward.mem")
  ) uDut (
    .iClk               (rClk),
    .iRstn              (rRstn),
    .iGpioAIn           (16'd0),
    .iGpioBIn           (16'd0),
    .iGpioCIn           (16'd0),
    .iSpiMiso           (1'b1),
    .iI2cSda            (1'b1),
    .iUartRx            (rUartRx),
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

  task automatic wait_clks(input integer iCount);
    integer i;
    begin
      for (i = 0; i < iCount; i = i + 1) begin
        @(posedge rClk);
      end
    end
  endtask

  task automatic send_uart_byte(input logic [7:0] iData);
    integer bit_idx;
    begin
      rUartRx <= 1'b0;
      wait_clks(LP_BIT_CLKS);

      for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
        rUartRx <= iData[bit_idx];
        wait_clks(LP_BIT_CLKS);
      end

      rUartRx <= 1'b1;
      wait_clks(LP_BIT_CLKS);
    end
  endtask

  always @(posedge rClk) begin
    if (!rRstn) begin
      rSpiFrameCount <= 0;
      rDoneIrqSeen   <= 0;
      rPlicRequestSeen <= 0;
      rTrapSeen <= 0;
      rTrapVectorSeen <= 0;
    end
    else begin
      if (uDut.uApbSubsystem.uApbSpi.uSpiMaster.oDone) begin
        rSpiFrameCount <= rSpiFrameCount + 1;
      end

      if (uDut.uApbSubsystem.wDmaDoneIrq) begin
        rDoneIrqSeen <= rDoneIrqSeen + 1;
      end

      if (uDut.uApbSubsystem.uApbPlicLite.wGatewayRequestPulse[5]) begin
        rPlicRequestSeen <= rPlicRequestSeen + 1;
      end

      if (uDut.uCore.wTrapEn) begin
        rTrapSeen <= rTrapSeen + 1;
      end

      if ((wDbgPc >= 32'h0000_0080) && (wDbgPc < 32'h0000_0190)) begin
        rTrapVectorSeen <= rTrapVectorSeen + 1;
      end

    end
  end

  initial begin
    rRstn = 1'b0;
    rUartRx = 1'b1;
    repeat (20) @(posedge rClk);
    rRstn = 1'b1;
    repeat (3000) @(posedge rClk);

    send_uart_byte(8'h12);
    send_uart_byte(8'h34);
    send_uart_byte(8'h56);
    send_uart_byte(8'h78);

    repeat (300000) begin
      @(posedge rClk);

      if (rSpiFrameCount >= LP_IMAGE_BYTES) begin
        $display("SOC_RGB_IRQ_MINI_PASS cycle=%0d retired=%0d irq_seen=%0d gpio=0x%04h pc=0x%08h",
                 wDbgCycleCount, wDbgRetiredCount, rDoneIrqSeen, wGpioAOut, wDbgPc);
        $finish;
      end
    end

    $display("SOC_RGB_IRQ_MINI_TIMEOUT cycle=%0d retired=%0d irq_seen=%0d plic_req=%0d trap_seen=%0d vector_seen=%0d spi_frames=%0d gpio=0x%04h pc=0x%08h sram0=0x%08h sram1=0x%08h sram2=0x%08h sram3=0x%08h ext_irq=%0b plic_pending=0x%08h plic_enable=0x%08h csr_mstatus=0x%08h csr_mie=0x%08h csr_mcause=0x%08h csr_mepc=0x%08h csr_mip=0x%08h irq_pending=%0b",
             wDbgCycleCount, wDbgRetiredCount, rDoneIrqSeen, rPlicRequestSeen, rTrapSeen, rTrapVectorSeen, rSpiFrameCount,
             wGpioAOut, wDbgPc, wDbgSramWord0, wDbgSramWord1, wDbgSramWord2, wDbgSramWord3,
             uDut.wExternalIrq,
             uDut.uApbSubsystem.uApbPlicLite.rPending,
             uDut.uApbSubsystem.uApbPlicLite.rEnable,
             uDut.uCore.wCsrMstatus,
             uDut.uCore.wCsrMie,
             uDut.uCore.wCsrMcause,
             uDut.uCore.wCsrMepc,
             uDut.uCore.wMip,
             uDut.uCore.wInterruptPending);
    $fatal(1, "RGB IRQ mini scenario did not reach SPI transmit");
  end
endmodule
