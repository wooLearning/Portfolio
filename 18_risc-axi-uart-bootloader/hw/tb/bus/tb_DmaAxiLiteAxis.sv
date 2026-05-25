`timescale 1ns / 1ps

module tb_DmaAxiLiteAxis;
  localparam logic [31:0] LP_SRAM_BASE = 32'h2000_0000;
  localparam logic [31:0] LP_SRAM_SIZE = 32'h0000_0400;

  localparam logic [7:0] LP_ADDR_CTRL       = 8'h00;
  localparam logic [7:0] LP_ADDR_STATUS     = 8'h04;
  localparam logic [7:0] LP_ADDR_SRC_ADDR   = 8'h08;
  localparam logic [7:0] LP_ADDR_DST_ADDR   = 8'h0C;
  localparam logic [7:0] LP_ADDR_LEN_BYTES  = 8'h10;
  localparam logic [7:0] LP_ADDR_COUNT      = 8'h14;
  localparam logic [7:0] LP_ADDR_IRQ_ENABLE = 8'h18;
  localparam logic [7:0] LP_ADDR_IRQ_STATUS = 8'h1C;

  logic        rClk;
  logic        rRstn;
  logic [31:0] rS_AWADDR;
  logic        rS_AWVALID;
  logic        wS_AWREADY;
  logic [31:0] rS_WDATA;
  logic [3:0]  rS_WSTRB;
  logic        rS_WVALID;
  logic        wS_WREADY;
  logic [1:0]  wS_BRESP;
  logic        wS_BVALID;
  logic        rS_BREADY;
  logic [31:0] rS_ARADDR;
  logic        rS_ARVALID;
  logic        wS_ARREADY;
  logic [31:0] wS_RDATA;
  logic [1:0]  wS_RRESP;
  logic        wS_RVALID;
  logic        rS_RREADY;
  logic        wDoneIrq;
  logic        wErrorIrq;
  logic [7:0]  rS_TDATA;
  logic        rS_TVALID;
  logic        wS_TREADY;
  logic        rS_TLAST;
  logic [7:0]  wM_TDATA;
  logic        wM_TVALID;
  logic        rM_TREADY;
  logic        wM_TLAST;
  logic [31:0] wM_AWADDR;
  logic        wM_AWVALID;
  logic        wM_AWREADY;
  logic [31:0] wM_WDATA;
  logic [3:0]  wM_WSTRB;
  logic        wM_WVALID;
  logic        wM_WREADY;
  logic [1:0]  wM_BRESP;
  logic        wM_BVALID;
  logic        wM_BREADY;
  logic [31:0] wM_ARADDR;
  logic        wM_ARVALID;
  logic        wM_ARREADY;
  logic [31:0] wM_RDATA;
  logic [1:0]  wM_RRESP;
  logic        wM_RVALID;
  logic        wM_RREADY;
  logic [31:0] rReadData;
  logic [7:0]  rCaptured [0:7];
  integer      rCaptureCount;
  integer      idx;

  DmaAxiLiteAxis #(
    .P_SRAM_BASE  (LP_SRAM_BASE),
    .P_SRAM_BYTES (LP_SRAM_SIZE)
  ) uDut (
    .iClk       (rClk),
    .iRstn      (rRstn),
    .iS_AWADDR  (rS_AWADDR),
    .iS_AWVALID (rS_AWVALID),
    .oS_AWREADY (wS_AWREADY),
    .iS_WDATA   (rS_WDATA),
    .iS_WSTRB   (rS_WSTRB),
    .iS_WVALID  (rS_WVALID),
    .oS_WREADY  (wS_WREADY),
    .oS_BRESP   (wS_BRESP),
    .oS_BVALID  (wS_BVALID),
    .iS_BREADY  (rS_BREADY),
    .iS_ARADDR  (rS_ARADDR),
    .iS_ARVALID (rS_ARVALID),
    .oS_ARREADY (wS_ARREADY),
    .oS_RDATA   (wS_RDATA),
    .oS_RRESP   (wS_RRESP),
    .oS_RVALID  (wS_RVALID),
    .iS_RREADY  (rS_RREADY),
    .oDoneIrq   (wDoneIrq),
    .oErrorIrq  (wErrorIrq),
    .iS_TDATA   (rS_TDATA),
    .iS_TVALID  (rS_TVALID),
    .oS_TREADY  (wS_TREADY),
    .iS_TLAST   (rS_TLAST),
    .oM_TDATA   (wM_TDATA),
    .oM_TVALID  (wM_TVALID),
    .iM_TREADY  (rM_TREADY),
    .oM_TLAST   (wM_TLAST),
    .oM_AWADDR  (wM_AWADDR),
    .oM_AWVALID (wM_AWVALID),
    .iM_AWREADY (wM_AWREADY),
    .oM_WDATA   (wM_WDATA),
    .oM_WSTRB   (wM_WSTRB),
    .oM_WVALID  (wM_WVALID),
    .iM_WREADY  (wM_WREADY),
    .iM_BRESP   (wM_BRESP),
    .iM_BVALID  (wM_BVALID),
    .oM_BREADY  (wM_BREADY),
    .oM_ARADDR  (wM_ARADDR),
    .oM_ARVALID (wM_ARVALID),
    .iM_ARREADY (wM_ARREADY),
    .iM_RDATA   (wM_RDATA),
    .iM_RRESP   (wM_RRESP),
    .iM_RVALID  (wM_RVALID),
    .oM_RREADY  (wM_RREADY)
  );

  AxiLiteSram #(
    .P_ADDR_WIDTH         (8),
    .P_ENABLE_DEBUG_WORDS (1'b0)
  ) uSram (
    .iClk        (rClk),
    .iRstn       (rRstn),
    .iS_AWADDR   (wM_AWADDR),
    .iS_AWVALID  (wM_AWVALID),
    .oS_AWREADY  (wM_AWREADY),
    .iS_WDATA    (wM_WDATA),
    .iS_WSTRB    (wM_WSTRB),
    .iS_WVALID   (wM_WVALID),
    .oS_WREADY   (wM_WREADY),
    .oS_BRESP    (wM_BRESP),
    .oS_BVALID   (wM_BVALID),
    .iS_BREADY   (wM_BREADY),
    .iS_ARADDR   (wM_ARADDR),
    .iS_ARVALID  (wM_ARVALID),
    .oS_ARREADY  (wM_ARREADY),
    .oS_RDATA    (wM_RDATA),
    .oS_RRESP    (wM_RRESP),
    .oS_RVALID   (wM_RVALID),
    .iS_RREADY   (wM_RREADY),
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

  task automatic axi_idle;
    begin
      rS_AWADDR  = 32'd0;
      rS_AWVALID = 1'b0;
      rS_WDATA   = 32'd0;
      rS_WSTRB   = 4'h0;
      rS_WVALID  = 1'b0;
      rS_BREADY  = 1'b1;
      rS_ARADDR  = 32'd0;
      rS_ARVALID = 1'b0;
      rS_RREADY  = 1'b1;
    end
  endtask

  task automatic axi_write(input logic [31:0] iAddr, input logic [31:0] iData);
    begin
      @(posedge rClk);
      rS_AWADDR  <= iAddr;
      rS_AWVALID <= 1'b1;
      rS_WDATA   <= iData;
      rS_WSTRB   <= 4'hF;
      rS_WVALID  <= 1'b1;

      do begin
        @(posedge rClk);
      end while (!(wS_AWREADY && wS_WREADY));

      rS_AWVALID <= 1'b0;
      rS_WVALID  <= 1'b0;
      rS_WSTRB   <= 4'h0;

      do begin
        @(posedge rClk);
      end while (!wS_BVALID);
    end
  endtask

  task automatic axi_read(input logic [31:0] iAddr, output logic [31:0] oData);
    begin
      @(posedge rClk);
      rS_ARADDR  <= iAddr;
      rS_ARVALID <= 1'b1;

      do begin
        @(posedge rClk);
      end while (!wS_ARREADY);

      rS_ARVALID <= 1'b0;

      do begin
        @(posedge rClk);
      end while (!wS_RVALID);

      oData = wS_RDATA;
    end
  endtask

  task automatic send_stream_byte(input logic [7:0] iData, input logic iLast);
    begin
      rS_TDATA  <= iData;
      rS_TVALID <= 1'b1;
      rS_TLAST  <= iLast;

      do begin
        @(posedge rClk);
      end while (!wS_TREADY);

      rS_TDATA  <= 8'd0;
      rS_TVALID <= 1'b0;
      rS_TLAST  <= 1'b0;
    end
  endtask

  task automatic wait_done(input integer iTimeout);
    integer timeout_idx;
    begin
      for (timeout_idx = 0; timeout_idx < iTimeout; timeout_idx = timeout_idx + 1) begin
        @(posedge rClk);
        if (wDoneIrq) begin
          return;
        end
      end
      $fatal(1, "DMA done timeout");
    end
  endtask

  task automatic wait_error(input integer iTimeout);
    integer timeout_idx;
    begin
      for (timeout_idx = 0; timeout_idx < iTimeout; timeout_idx = timeout_idx + 1) begin
        @(posedge rClk);
        if (wErrorIrq) begin
          return;
        end
      end
      $fatal(1, "DMA error timeout");
    end
  endtask

  initial begin
    axi_idle();
    rRstn = 1'b0;
    rS_TDATA = 8'd0;
    rS_TVALID = 1'b0;
    rS_TLAST = 1'b0;
    rM_TREADY = 1'b1;
    rCaptureCount = 0;

    repeat (5) @(posedge rClk);
    rRstn = 1'b1;
    repeat (2) @(posedge rClk);

    axi_write({24'd0, LP_ADDR_IRQ_ENABLE}, 32'h0000_0003);
    axi_write({24'd0, LP_ADDR_DST_ADDR}, LP_SRAM_BASE + 32'd4);
    axi_write({24'd0, LP_ADDR_LEN_BYTES}, 32'd4);
    axi_write({24'd0, LP_ADDR_CTRL}, 32'h0000_0001);
    send_stream_byte(8'h11, 1'b0);
    send_stream_byte(8'h22, 1'b0);
    send_stream_byte(8'h33, 1'b0);
    send_stream_byte(8'h44, 1'b1);
    wait_done(100);

    if (uSram.rMem[1] != 32'h4433_2211) begin
      $fatal(1, "S2MM aligned write mismatch word=0x%08h", uSram.rMem[1]);
    end

    axi_read({24'd0, LP_ADDR_COUNT}, rReadData);
    if (rReadData != 32'd4) begin
      $fatal(1, "S2MM count mismatch count=%0d", rReadData);
    end

    axi_write({24'd0, LP_ADDR_IRQ_STATUS}, 32'h0000_0003);
    axi_write({24'd0, LP_ADDR_DST_ADDR}, LP_SRAM_BASE + 32'd1);
    axi_write({24'd0, LP_ADDR_LEN_BYTES}, 32'd3);
    axi_write({24'd0, LP_ADDR_CTRL}, 32'h0000_0001);
    send_stream_byte(8'hAA, 1'b0);
    send_stream_byte(8'hBB, 1'b0);
    send_stream_byte(8'hCC, 1'b1);
    wait_done(100);

    if (uSram.rMem[0] != 32'hCCBB_AA00) begin
      $fatal(1, "S2MM unaligned write mismatch word=0x%08h", uSram.rMem[0]);
    end

    uSram.rMem[2] = 32'h8877_6655;
    axi_write({24'd0, LP_ADDR_IRQ_STATUS}, 32'h0000_0003);
    axi_write({24'd0, LP_ADDR_SRC_ADDR}, LP_SRAM_BASE + 32'd8);
    axi_write({24'd0, LP_ADDR_LEN_BYTES}, 32'd4);
    axi_write({24'd0, LP_ADDR_CTRL}, 32'h0000_0003);

    rCaptureCount = 0;
    while (rCaptureCount < 4) begin
      @(posedge rClk);
      if (wM_TVALID && rM_TREADY) begin
        rCaptured[rCaptureCount] = wM_TDATA;
        if ((rCaptureCount == 3) != wM_TLAST) begin
          $fatal(1, "MM2S TLAST mismatch beat=%0d last=%0b", rCaptureCount, wM_TLAST);
        end
        rCaptureCount = rCaptureCount + 1;
      end
    end
    wait_done(20);

    if ((rCaptured[0] != 8'h55) || (rCaptured[1] != 8'h66) ||
        (rCaptured[2] != 8'h77) || (rCaptured[3] != 8'h88)) begin
      $fatal(1, "MM2S data mismatch got=%02h_%02h_%02h_%02h",
             rCaptured[0], rCaptured[1], rCaptured[2], rCaptured[3]);
    end

    axi_write({24'd0, LP_ADDR_IRQ_STATUS}, 32'h0000_0003);
    axi_write({24'd0, LP_ADDR_DST_ADDR}, LP_SRAM_BASE + LP_SRAM_SIZE - 32'd2);
    axi_write({24'd0, LP_ADDR_LEN_BYTES}, 32'd8);
    axi_write({24'd0, LP_ADDR_CTRL}, 32'h0000_0001);
    wait_error(20);
    axi_read({24'd0, LP_ADDR_STATUS}, rReadData);
    if (!rReadData[3]) begin
      $fatal(1, "ADDR_ERROR bit missing status=0x%08h", rReadData);
    end

    for (idx = 0; idx < 4; idx = idx + 1) begin
      @(posedge rClk);
    end

    $display("DMA_AXI_LITE_AXIS_PASS s2mm=1 mm2s=1 unaligned=1 range_error=1");
    $finish;
  end

endmodule
