`timescale 1ns / 1ps

module tb_SocTopUartLoader;
  localparam integer LP_BIT_CLKS = 432;
  localparam integer LP_PACKET_BYTES = 372;

  logic        rClk;
  logic        rRstn;
  logic        rUartRx;
  logic [7:0]  rPacket [0:LP_PACKET_BYTES-1];
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
  integer      i;

  SocTop #(
    .P_ENABLE_DEBUG  (1'b1),
    .P_ICODE_MEM_FILE("rtl/src/timing_programs/uart_loader.mem")
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
    integer j;
    begin
      for (j = 0; j < iCount; j = j + 1) begin
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

  initial begin
    $readmemh("../build/sw/current/ram_led_app_loader_packet.hex", rPacket);
  end

  initial begin
    rRstn = 1'b0;
    rUartRx = 1'b1;
    repeat (20) @(posedge rClk);
    rRstn = 1'b1;
    repeat (3000) @(posedge rClk);

    for (i = 0; i < LP_PACKET_BYTES; i = i + 1) begin
      send_uart_byte(rPacket[i]);
    end

    repeat (100000) begin
      @(posedge rClk);

      if ((wGpioAOut == 16'h00A5) &&
          (wDbgPc >= address_map_pkg::RAM_APP_BASE) &&
          (wDbgSramWord0 == 32'hA550_0001) &&
          (wDbgSramWord1 == address_map_pkg::RAM_APP_BASE) &&
          (wDbgSramWord2 == 32'hABCD_1234) &&
          (wDbgSramWord3 == 32'h0000_0000)) begin
        $display("SOC_UART_LOADER_PASS cycle=%0d retired=%0d pc=0x%08h gpio=0x%04h sram0=0x%08h sram1=0x%08h sram2=0x%08h sram3=0x%08h",
                 wDbgCycleCount,
                 wDbgRetiredCount,
                 wDbgPc,
                 wGpioAOut,
                 wDbgSramWord0,
                 wDbgSramWord1,
                 wDbgSramWord2,
                 wDbgSramWord3);
        $finish;
      end
    end

    $display("SOC_UART_LOADER_TIMEOUT cycle=%0d retired=%0d pc=0x%08h gpio=0x%04h sram0=0x%08h sram1=0x%08h sram2=0x%08h sram3=0x%08h",
             wDbgCycleCount,
             wDbgRetiredCount,
             wDbgPc,
             wGpioAOut,
             wDbgSramWord0,
             wDbgSramWord1,
             wDbgSramWord2,
             wDbgSramWord3);
    $fatal(1, "UART loader did not jump to RAM LED app");
  end

endmodule
