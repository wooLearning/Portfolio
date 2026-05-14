`timescale 1ns / 1ps

/*
 * RGB IRQ SPI 파형 확인용 SoC testbench.
 *
 * 목적:
 *   - 실제 master ROM을 붙인 상태로 PC UART 입력을 짧게 흉내낸다.
 *   - UART로 들어온 RGB byte가 DMA 내부 buffer에 저장된 뒤,
 *     DMA_DONE interrupt를 거쳐 SPI MOSI로 다시 나가는지 파형으로 확인한다.
 *
 * 테스트 payload:
 *   pixel0 = R 0x11, G 0x22, B 0x33
 *   pixel1 = R 0x44, G 0x55, B 0x66
 *
 * 파형에서 보면 좋은 신호:
 *   - rUartRx                          : PC -> master UART RX 입력
 *   - wSpiCsN[0], wSpiSclk, wSpiMosi    : master -> slave SPI 출력
 *   - uDut.uApbSubsystem.wDmaDoneIrq    : DMA 완료 interrupt source
 *   - uDut.wExternalIrq                 : PLIC -> CPU external interrupt
 *   - uDut.uCore.wTrapEn                : CPU trap 진입
 *   - wGpioAOut                         : firmware 진행 상태 LED 값
 */
module tb_SocTopRgbIrqSpiWave;
  localparam integer LP_BIT_CLKS = 432;
  localparam integer LP_IMAGE_BYTES = 6;

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

  logic [7:0] rExpected [0:LP_IMAGE_BYTES-1];
  logic [7:0] rSpiShift;
  logic [7:0] wCapturedByte;
  integer     rSpiBitCount;
  integer     rSpiByteCount;
  integer     rMismatchCount;

  assign wCapturedByte = {rSpiShift[6:0], wSpiMosi};

  SocTop #(
    .P_ENABLE_DEBUG  (1'b1),
    // 이 TB는 6-byte mini frame만 UART로 넣는다.
    // 보드용 12288-byte ROM을 쓰면 firmware가 RX_DONE을 기다리므로 finish까지 가지 않는다.
    .P_ICODE_MEM_FILE("rtl/src/timing_programs/uart_dma_spi_rgb_irq_forward_sim6.mem")
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
      // 8N1 UART 전송: start bit 0, data LSB-first, stop bit 1.
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

  always @(posedge rClk or negedge rRstn) begin
    if (!rRstn) begin
      rSpiShift     <= 8'd0;
      rSpiBitCount  <= 0;
      rSpiByteCount <= 0;
      rMismatchCount <= 0;
    end
    else if (wSpiCsN[0]) begin
      rSpiShift    <= 8'd0;
      rSpiBitCount <= 0;
    end
  end

  always @(posedge wSpiSclk) begin
    if (!wSpiCsN[0]) begin
      // SPI mode 0 기준으로 slave는 SCLK rising edge에서 MOSI를 sample한다.
      rSpiShift <= wCapturedByte;

      if (rSpiBitCount == 7) begin
        $display("SPI_BYTE index=%0d value=0x%02h expected=0x%02h time=%0t",
                 rSpiByteCount, wCapturedByte, rExpected[rSpiByteCount], $time);

        if (wCapturedByte !== rExpected[rSpiByteCount]) begin
          rMismatchCount <= rMismatchCount + 1;
        end

        rSpiByteCount <= rSpiByteCount + 1;
        rSpiBitCount  <= 0;
        rSpiShift     <= 8'd0;
      end
      else begin
        rSpiBitCount <= rSpiBitCount + 1;
      end
    end
  end

  initial begin
    rExpected[0] = 8'h11;
    rExpected[1] = 8'h22;
    rExpected[2] = 8'h33;
    rExpected[3] = 8'h44;
    rExpected[4] = 8'h55;
    rExpected[5] = 8'h66;

    rRstn = 1'b0;
    rUartRx = 1'b1;
    repeat (20) @(posedge rClk);
    rRstn = 1'b1;

    // ROM 초기화와 UART/SPI/PLIC 설정이 끝날 시간을 조금 준다.
    repeat (3000) @(posedge rClk);

    send_uart_byte(rExpected[0]);
    send_uart_byte(rExpected[1]);
    send_uart_byte(rExpected[2]);
    send_uart_byte(rExpected[3]);
    send_uart_byte(rExpected[4]);
    send_uart_byte(rExpected[5]);

    repeat (500000) begin
      @(posedge rClk);

      if (rSpiByteCount >= LP_IMAGE_BYTES) begin
        if (rMismatchCount == 0) begin
          $display("SOC_RGB_IRQ_SPI_WAVE_PASS bytes=%0d gpio=0x%04h pc=0x%08h",
                   rSpiByteCount, wGpioAOut, wDbgPc);
          $finish;
        end
        else begin
          $fatal(1, "SPI byte mismatch count=%0d", rMismatchCount);
        end
      end
    end

    $fatal(1, "SPI waveform test timeout: bytes=%0d gpio=0x%04h pc=0x%08h",
           rSpiByteCount, wGpioAOut, wDbgPc);
  end
endmodule
