`timescale 1ns / 1ps

module tb_ApbSubsystemDmaStream;
  localparam logic [31:0] LP_UART_BASE = 32'h0005_0000;
  localparam logic [31:0] LP_SPI_BASE  = 32'h0003_0000;
  localparam logic [31:0] LP_PLIC_BASE = 32'h000F_0000;
  localparam logic [31:0] LP_SRAM_BASE = 32'h2000_0000;

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
  logic        wDmaDoneIrq;
  logic        wDmaErrorIrq;
  logic [7:0]  wDmaS_TDATA;
  logic        wDmaS_TVALID;
  logic        wDmaS_TREADY;
  logic [7:0]  wDmaM_TDATA;
  logic        wDmaM_TVALID;
  logic        wDmaM_TREADY;
  logic        wDmaM_TLAST;
  logic [31:0] rDma_AWADDR;
  logic        rDma_AWVALID;
  logic        wDma_AWREADY;
  logic [31:0] rDma_WDATA;
  logic [3:0]  rDma_WSTRB;
  logic        rDma_WVALID;
  logic        wDma_WREADY;
  logic [1:0]  wDma_BRESP;
  logic        wDma_BVALID;
  logic        rDma_BREADY;
  logic [31:0] rDma_ARADDR;
  logic        rDma_ARVALID;
  logic        wDma_ARREADY;
  logic [31:0] wDma_RDATA;
  logic [1:0]  wDma_RRESP;
  logic        wDma_RVALID;
  logic        rDma_RREADY;
  logic [31:0] wDmaM_AWADDR;
  logic        wDmaM_AWVALID;
  logic        wDmaM_AWREADY;
  logic [31:0] wDmaM_WDATA;
  logic [3:0]  wDmaM_WSTRB;
  logic        wDmaM_WVALID;
  logic        wDmaM_WREADY;
  logic [1:0]  wDmaM_BRESP;
  logic        wDmaM_BVALID;
  logic        wDmaM_BREADY;
  logic [31:0] wDmaM_ARADDR;
  logic        wDmaM_ARVALID;
  logic        wDmaM_ARREADY;
  logic [31:0] wDmaM_RDATA;
  logic [1:0]  wDmaM_RRESP;
  logic        wDmaM_RVALID;
  logic        wDmaM_RREADY;
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

  DmaAxiLiteAxis #(
    .P_SRAM_BASE  (LP_SRAM_BASE),
    .P_SRAM_BYTES (32'h0000_0400)
  ) uDma (
    .iClk        (rClk),
    .iRstn       (rRstn),
    .iS_AWADDR   (rDma_AWADDR),
    .iS_AWVALID  (rDma_AWVALID),
    .oS_AWREADY  (wDma_AWREADY),
    .iS_WDATA    (rDma_WDATA),
    .iS_WSTRB    (rDma_WSTRB),
    .iS_WVALID   (rDma_WVALID),
    .oS_WREADY   (wDma_WREADY),
    .oS_BRESP    (wDma_BRESP),
    .oS_BVALID   (wDma_BVALID),
    .iS_BREADY   (rDma_BREADY),
    .iS_ARADDR   (rDma_ARADDR),
    .iS_ARVALID  (rDma_ARVALID),
    .oS_ARREADY  (wDma_ARREADY),
    .oS_RDATA    (wDma_RDATA),
    .oS_RRESP    (wDma_RRESP),
    .oS_RVALID   (wDma_RVALID),
    .iS_RREADY   (rDma_RREADY),
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
    .oM_AWADDR   (wDmaM_AWADDR),
    .oM_AWVALID  (wDmaM_AWVALID),
    .iM_AWREADY  (wDmaM_AWREADY),
    .oM_WDATA    (wDmaM_WDATA),
    .oM_WSTRB    (wDmaM_WSTRB),
    .oM_WVALID   (wDmaM_WVALID),
    .iM_WREADY   (wDmaM_WREADY),
    .iM_BRESP    (wDmaM_BRESP),
    .iM_BVALID   (wDmaM_BVALID),
    .oM_BREADY   (wDmaM_BREADY),
    .oM_ARADDR   (wDmaM_ARADDR),
    .oM_ARVALID  (wDmaM_ARVALID),
    .iM_ARREADY  (wDmaM_ARREADY),
    .iM_RDATA    (wDmaM_RDATA),
    .iM_RRESP    (wDmaM_RRESP),
    .iM_RVALID   (wDmaM_RVALID),
    .oM_RREADY   (wDmaM_RREADY)
  );

  AxiLiteSram #(
    .P_ADDR_WIDTH         (8),
    .P_ENABLE_DEBUG_WORDS (1'b0)
  ) uSram (
    .iClk        (rClk),
    .iRstn       (rRstn),
    .iS_AWADDR   (wDmaM_AWADDR),
    .iS_AWVALID  (wDmaM_AWVALID),
    .oS_AWREADY  (wDmaM_AWREADY),
    .iS_WDATA    (wDmaM_WDATA),
    .iS_WSTRB    (wDmaM_WSTRB),
    .iS_WVALID   (wDmaM_WVALID),
    .oS_WREADY   (wDmaM_WREADY),
    .oS_BRESP    (wDmaM_BRESP),
    .oS_BVALID   (wDmaM_BVALID),
    .iS_BREADY   (wDmaM_BREADY),
    .iS_ARADDR   (wDmaM_ARADDR),
    .iS_ARVALID  (wDmaM_ARVALID),
    .oS_ARREADY  (wDmaM_ARREADY),
    .oS_RDATA    (wDmaM_RDATA),
    .oS_RRESP    (wDmaM_RRESP),
    .oS_RVALID   (wDmaM_RVALID),
    .iS_RREADY   (wDmaM_RREADY),
    .iILocalValid(1'b0),
    .iILocalAddr (32'd0),
    .oILocalReady(),
    .oILocalRData(),
    .oILocalError(),
    .oDbgWord0   (),
    .oDbgWord1   (),
    .oDbgWord2   (),
    .oDbgWord3   ()
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
    else if (wDmaM_TVALID && wDmaM_TREADY) begin
      rSpiStreamBytes[rSpiStreamCount] <= wDmaM_TDATA;
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

  task automatic dma_axi_idle;
    begin
      rDma_AWADDR  = 32'd0;
      rDma_AWVALID = 1'b0;
      rDma_WDATA   = 32'd0;
      rDma_WSTRB   = 4'h0;
      rDma_WVALID  = 1'b0;
      rDma_BREADY  = 1'b1;
      rDma_ARADDR  = 32'd0;
      rDma_ARVALID = 1'b0;
      rDma_RREADY  = 1'b1;
    end
  endtask

  task automatic dma_axi_write(input logic [31:0] iAddr, input logic [31:0] iData);
    begin
      @(posedge rClk);
      rDma_AWADDR  <= iAddr;
      rDma_AWVALID <= 1'b1;
      rDma_WDATA   <= iData;
      rDma_WSTRB   <= 4'hF;
      rDma_WVALID  <= 1'b1;

      do begin
        @(posedge rClk);
      end while (!(wDma_AWREADY && wDma_WREADY));

      rDma_AWVALID <= 1'b0;
      rDma_WVALID  <= 1'b0;
      rDma_WSTRB   <= 4'h0;

      do begin
        @(posedge rClk);
      end while (!wDma_BVALID);
    end
  endtask

  task automatic dma_axi_read(input logic [31:0] iAddr, output logic [31:0] oData);
    begin
      @(posedge rClk);
      rDma_ARADDR  <= iAddr;
      rDma_ARVALID <= 1'b1;

      do begin
        @(posedge rClk);
      end while (!wDma_ARREADY);

      rDma_ARVALID <= 1'b0;

      do begin
        @(posedge rClk);
      end while (!wDma_RVALID);

      oData = wDma_RDATA;
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
        dma_axi_read(32'h04, rReadData);

        if (rReadData[1]) begin
          return;
        end
      end

      $fatal(1, "DMA done timeout status=0x%08h state=%0d count=%0d s_valid=%0b s_ready=%0b fifo_empty=%0b",
             rReadData, uDma.rState, uDma.rCountBytes, wDmaS_TVALID, wDmaS_TREADY,
             uDut.wDmaRxStreamFifoEmpty);
    end
  endtask

  task automatic expect_dma_buffer(input logic [31:0] iAddr, input logic [7:0] iData);
    logic [31:0] word_data;
    logic [7:0]  actual;
    begin
      word_data = uSram.rMem[iAddr[9:2]];

      unique case (iAddr[1:0])
        2'd0:    actual = word_data[7:0];
        2'd1:    actual = word_data[15:8];
        2'd2:    actual = word_data[23:16];
        default: actual = word_data[31:24];
      endcase

      if (actual != iData) begin
        $fatal(1, "Subsystem DMA buffer mismatch addr=%0d expected=0x%02h actual=0x%02h",
               iAddr, iData, actual);
      end
    end
  endtask

  initial begin
    apb_idle();
    dma_axi_idle();
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
    dma_axi_write(32'h18, 32'h0000_0003);
    dma_axi_write(32'h0C, LP_SRAM_BASE);
    dma_axi_write(32'h10, 32'd4);
    dma_axi_write(32'h00, 32'h0000_0001);

    uart_send_byte(8'h12);
    uart_send_byte(8'h34);
    uart_send_byte(8'h56);
    uart_send_byte(8'h78);

    wait_dma_done(400);
    expect_dma_buffer(32'd0, 8'h12);
    expect_dma_buffer(32'd1, 8'h34);
    expect_dma_buffer(32'd2, 8'h56);
    expect_dma_buffer(32'd3, 8'h78);

    apb_write(LP_PLIC_BASE + 32'h00, 32'h0000_0020);
    apb_write(LP_PLIC_BASE + 32'h24, 32'd1);
    if (!wExternalIrq) begin
      $fatal(1, "DMA done IRQ did not reach PLIC external IRQ");
    end

    dma_axi_write(32'h1C, 32'h0000_0003);
    apb_write(LP_SPI_BASE + 32'h08, 32'd0);
    apb_write(LP_SPI_BASE + 32'h00, 32'h0000_0020);
    dma_axi_write(32'h08, LP_SRAM_BASE);
    dma_axi_write(32'h10, 32'd4);
    dma_axi_write(32'h00, 32'h0000_0003);

    wait_dma_done(400);

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
