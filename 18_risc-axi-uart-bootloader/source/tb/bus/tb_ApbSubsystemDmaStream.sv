`timescale 1ns / 1ps

module tb_ApbSubsystemDmaStream;
  localparam logic [31:0] LP_UART_BASE = 32'h4005_0000;
  localparam logic [31:0] LP_DMA_BASE  = 32'h4006_0000;
  localparam logic [31:0] LP_SPI_BASE  = 32'h4003_0000;
  localparam logic [31:0] LP_PLIC_BASE = 32'h400F_0000;

  logic        rClk;
  logic        rRstn;
  logic        rPSEL;
  logic        rPENABLE;
  logic        rPWRITE;
  logic [31:0] rPADDR;
  logic [31:0] rPWDATA;
  logic [3:0]  rPSTRB;
  logic [31:0] wPRDATA;
  logic        wPREADY;
  logic        wPSLVERR;
  logic [15:0] wGpioAOut;
  logic [15:0] wGpioADir;
  logic [15:0] wGpioBOut;
  logic [15:0] wGpioBDir;
  logic        rSpiMiso;
  logic        wSpiSclk;
  logic        wSpiMosi;
  logic [3:0]  wSpiCsN;
  logic        rI2cSda;
  logic        wI2cSclDriveLow;
  logic        wI2cSdaDriveLow;
  logic        rUartRx;
  logic        wUartTx;
  logic        wTimerIrq;
  logic        wExternalIrq;
  logic [31:0] rReadData;
  logic [7:0]  rSpiBytes [0:7];
  logic [7:0]  rSpiStreamBytes [0:7];
  logic [7:0]  rSpiShift;
  integer      rSpiBitCount;
  integer      rSpiByteCount;
  integer      rSpiStreamCount;
  integer      idx;

  ApbSubsystem uDut (
    .iPclk          (rClk),
    .iPresetn       (rRstn),
    .iPSEL          (rPSEL),
    .iPENABLE       (rPENABLE),
    .iPWRITE        (rPWRITE),
    .iPADDR         (rPADDR),
    .iPWDATA        (rPWDATA),
    .iPSTRB         (rPSTRB),
    .iPeripheralIrq (8'd0),
    .iGpioAIn       (16'd0),
    .iGpioBIn       (16'd0),
    .iGpioCIn       (16'd0),
    .iSpiMiso       (rSpiMiso),
    .iI2cSda        (rI2cSda),
    .iUartRx        (rUartRx),
    .oGpioAOut      (wGpioAOut),
    .oGpioADir      (wGpioADir),
    .oGpioBOut      (wGpioBOut),
    .oGpioBDir      (wGpioBDir),
    .oSpiSclk       (wSpiSclk),
    .oSpiMosi       (wSpiMosi),
    .oSpiCsN        (wSpiCsN),
    .oI2cSclDriveLow(wI2cSclDriveLow),
    .oI2cSdaDriveLow(wI2cSdaDriveLow),
    .oUartTx        (wUartTx),
    .oPRDATA        (wPRDATA),
    .oPREADY        (wPREADY),
    .oPSLVERR       (wPSLVERR),
    .oTimerIrq      (wTimerIrq),
    .oExternalIrq   (wExternalIrq)
  );

  initial begin
    rClk = 1'b0;
    forever #5 rClk = ~rClk;
  end

  always @(posedge wSpiSclk) begin
    if (!wSpiCsN[0]) begin
      rSpiShift = {rSpiShift[6:0], wSpiMosi};

      if (rSpiBitCount == 7) begin
        rSpiBytes[rSpiByteCount] = {rSpiShift[6:0], wSpiMosi};
        rSpiByteCount = rSpiByteCount + 1;
        rSpiBitCount = 0;
      end
      else begin
        rSpiBitCount = rSpiBitCount + 1;
      end
    end
  end

  always @(negedge wSpiCsN[0]) begin
    rSpiShift = {7'd0, wSpiMosi};
    rSpiBitCount = 1;
  end

  always_ff @(posedge rClk or negedge rRstn) begin
    if (!rRstn) begin
      rSpiStreamCount <= 0;
    end
    else if (uDut.wDmaTxStreamValid && uDut.wDmaTxStreamReady) begin
      rSpiStreamBytes[rSpiStreamCount] <= uDut.wDmaTxStreamData;
      rSpiStreamCount <= rSpiStreamCount + 1;
    end
  end

  task automatic apb_idle;
    begin
      rPSEL    = 1'b0;
      rPENABLE = 1'b0;
      rPWRITE  = 1'b0;
      rPADDR   = 32'd0;
      rPWDATA  = 32'd0;
      rPSTRB   = 4'h0;
    end
  endtask

  task automatic apb_write(input logic [31:0] iAddr, input logic [31:0] iData);
    begin
      @(posedge rClk);
      rPSEL    <= 1'b1;
      rPENABLE <= 1'b0;
      rPWRITE  <= 1'b1;
      rPADDR   <= iAddr;
      rPWDATA  <= iData;
      rPSTRB   <= 4'hF;
      @(posedge rClk);
      rPENABLE <= 1'b1;
      @(posedge rClk);
      rPSEL    <= 1'b0;
      rPENABLE <= 1'b0;
      rPWRITE  <= 1'b0;
      rPSTRB   <= 4'h0;
    end
  endtask

  task automatic apb_read(input logic [31:0] iAddr, output logic [31:0] oData);
    begin
      @(posedge rClk);
      rPSEL    <= 1'b1;
      rPENABLE <= 1'b0;
      rPWRITE  <= 1'b0;
      rPADDR   <= iAddr;
      rPSTRB   <= 4'h0;
      @(posedge rClk);
      rPENABLE <= 1'b1;
      @(posedge rClk);
      oData = wPRDATA;
      rPSEL    <= 1'b0;
      rPENABLE <= 1'b0;
    end
  endtask

  task automatic uart_send_byte(input logic [7:0] iData);
    integer bit_idx;
    begin
      rUartRx <= 1'b0;
      repeat (16) @(posedge rClk);

      for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
        rUartRx <= iData[bit_idx];
        repeat (16) @(posedge rClk);
      end

      rUartRx <= 1'b1;
      repeat (24) @(posedge rClk);
    end
  endtask

  task automatic wait_dma_done(input integer iTimeout);
    integer timeout_idx;
    begin
      for (timeout_idx = 0; timeout_idx < iTimeout; timeout_idx = timeout_idx + 1) begin
        @(posedge rClk);
        apb_read(LP_DMA_BASE + 32'h04, rReadData);

        if (rReadData[1]) begin
          return;
        end
      end

      $fatal(1, "DMA done timeout status=0x%08h", rReadData);
    end
  endtask

  task automatic expect_dma_buffer(input logic [31:0] iAddr, input logic [7:0] iData);
    begin
      apb_write(LP_DMA_BASE + 32'h14, iAddr);
      repeat (2) @(posedge rClk);
      apb_read(LP_DMA_BASE + 32'h18, rReadData);

      if (rReadData[7:0] != iData) begin
        $fatal(1, "Subsystem DMA buffer mismatch addr=%0d expected=0x%02h actual=0x%02h",
               iAddr, iData, rReadData[7:0]);
      end
    end
  endtask

  initial begin
    apb_idle();
    rRstn = 1'b0;
    rSpiMiso = 1'b1;
    rI2cSda = 1'b1;
    rUartRx = 1'b1;
    rSpiShift = 8'd0;
    rSpiBitCount = 0;
    rSpiByteCount = 0;
    repeat (5) @(posedge rClk);
    rRstn = 1'b1;
    repeat (4) @(posedge rClk);

    apb_write(LP_UART_BASE + 32'h08, 32'd0);
    apb_write(LP_UART_BASE + 32'h00, 32'h0000_0010);
    apb_write(LP_DMA_BASE + 32'h14, 32'd0);
    apb_write(LP_DMA_BASE + 32'h08, 32'd4);
    apb_write(LP_DMA_BASE + 32'h00, 32'h0000_0003);

    uart_send_byte(8'h12);
    uart_send_byte(8'h34);
    uart_send_byte(8'h56);
    uart_send_byte(8'h78);

    wait_dma_done(40);
    expect_dma_buffer(32'd0, 8'h12);
    expect_dma_buffer(32'd1, 8'h34);
    expect_dma_buffer(32'd2, 8'h56);
    expect_dma_buffer(32'd3, 8'h78);

    apb_write(LP_PLIC_BASE + 32'h00, 32'h0000_0020);
    apb_write(LP_PLIC_BASE + 32'h24, 32'd1);
    if (!wExternalIrq) begin
      $fatal(1, "DMA done IRQ did not reach PLIC external IRQ");
    end

    apb_write(LP_DMA_BASE + 32'h10, 32'h0000_0002);
    apb_write(LP_SPI_BASE + 32'h08, 32'd0);
    apb_write(LP_SPI_BASE + 32'h00, 32'h0000_0020);
    apb_write(LP_DMA_BASE + 32'h14, 32'd0);
    apb_write(LP_DMA_BASE + 32'h08, 32'd4);
    apb_write(LP_DMA_BASE + 32'h00, 32'h0000_0007);

    wait_dma_done(40);

    repeat (3000) @(posedge rClk);
    if (rSpiStreamCount < 4) begin
      $fatal(1, "DMA emitted too few bytes to SPI stream count=%0d", rSpiStreamCount);
    end

    if ((rSpiStreamBytes[0] != 8'h12) || (rSpiStreamBytes[1] != 8'h34) ||
        (rSpiStreamBytes[2] != 8'h56) || (rSpiStreamBytes[3] != 8'h78)) begin
      $fatal(1, "DMA-to-SPI stream mismatch got=%02h %02h %02h %02h",
             rSpiStreamBytes[0], rSpiStreamBytes[1],
             rSpiStreamBytes[2], rSpiStreamBytes[3]);
    end

    if (rSpiByteCount < 4) begin
      $fatal(1, "SPI serial interface emitted too few frames count=%0d", rSpiByteCount);
    end

    $display("APB_SUBSYSTEM_DMA_STREAM_PASS uart_to_dma=12_34_56_78 dma_to_spi=%02h_%02h_%02h_%02h spi_frames=%0d external_irq=%0b",
             rSpiStreamBytes[0], rSpiStreamBytes[1],
             rSpiStreamBytes[2], rSpiStreamBytes[3], rSpiByteCount, wExternalIrq);
    $finish;
  end

endmodule
