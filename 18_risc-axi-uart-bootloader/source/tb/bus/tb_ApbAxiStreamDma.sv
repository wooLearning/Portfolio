`timescale 1ns / 1ps

module tb_ApbAxiStreamDma;
  localparam integer LP_BUFFER_BYTES = 64;
  localparam logic [7:0] LP_ADDR_CTRL      = 8'h00;
  localparam logic [7:0] LP_ADDR_STATUS    = 8'h04;
  localparam logic [7:0] LP_ADDR_LEN_BYTES = 8'h08;
  localparam logic [7:0] LP_ADDR_COUNT     = 8'h0C;
  localparam logic [7:0] LP_ADDR_CLEAR     = 8'h10;
  localparam logic [7:0] LP_ADDR_BUF_ADDR  = 8'h14;
  localparam logic [7:0] LP_ADDR_BUF_DATA  = 8'h18;

  logic        rClk;
  logic        rRstn;
  logic        rPSEL;
  logic        rPENABLE;
  logic        rPWRITE;
  logic [11:0] rPADDR;
  logic [31:0] rPWDATA;
  logic [3:0]  rPSTRB;
  logic [31:0] wPRDATA;
  logic        wPREADY;
  logic        wPSLVERR;
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
  logic [31:0] rReadData;
  logic [7:0]  rRxData [0:15];
  logic        rCovRxBasic;
  logic        rCovTxBasic;
  logic        rCovBackpressure;
  logic        rCovOffset;
  logic        rCovDebugAccess;
  logic        rCovRangeError;
  logic        rCovEarlyLastError;
  logic        rCovClearStatus;
  integer      rRxCount;
  integer      rSeed;
  integer      idx;

  ApbAxiStreamDma #(
    .P_BUFFER_BYTES(LP_BUFFER_BYTES)
  ) uDut (
    .iPclk     (rClk),
    .iPresetn  (rRstn),
    .iPSEL     (rPSEL),
    .iPENABLE  (rPENABLE),
    .iPWRITE   (rPWRITE),
    .iPADDR    (rPADDR),
    .iPWDATA   (rPWDATA),
    .iPSTRB    (rPSTRB),
    .oPRDATA   (wPRDATA),
    .oPREADY   (wPREADY),
    .oPSLVERR  (wPSLVERR),
    .oDoneIrq  (wDoneIrq),
    .oErrorIrq (wErrorIrq),
    .iS_TDATA  (rS_TDATA),
    .iS_TVALID (rS_TVALID),
    .oS_TREADY (wS_TREADY),
    .iS_TLAST  (rS_TLAST),
    .oM_TDATA  (wM_TDATA),
    .oM_TVALID (wM_TVALID),
    .iM_TREADY (rM_TREADY),
    .oM_TLAST  (wM_TLAST)
  );

  initial begin
    rClk = 1'b0;
    forever #5 rClk = ~rClk;
  end

  task automatic apb_idle;
    begin
      rPSEL    = 1'b0;
      rPENABLE = 1'b0;
      rPWRITE  = 1'b0;
      rPADDR   = 12'd0;
      rPWDATA  = 32'd0;
      rPSTRB   = 4'h0;
    end
  endtask

  task automatic apb_write(input logic [11:0] iAddr, input logic [31:0] iData);
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

  task automatic apb_read(input logic [11:0] iAddr, output logic [31:0] oData);
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

  task automatic clear_status;
    begin
      apb_write({4'd0, LP_ADDR_CLEAR}, 32'h0000_0006);
      repeat (2) @(posedge rClk);
    end
  endtask

  task automatic dma_start(
    input logic        iDirection,
    input logic [31:0] iAddr,
    input logic [31:0] iLen
  );
    begin
      clear_status();
      apb_write({4'd0, LP_ADDR_BUF_ADDR}, iAddr);
      apb_write({4'd0, LP_ADDR_LEN_BYTES}, iLen);
      apb_write({4'd0, LP_ADDR_CTRL}, {29'd0, iDirection, 1'b1, 1'b1});
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

  task automatic send_stream_byte(
    input logic [7:0] iData,
    input logic       iLast,
    input integer     iIdleCycles
  );
    integer idle_idx;
    begin
      for (idle_idx = 0; idle_idx < iIdleCycles; idle_idx = idle_idx + 1) begin
        @(posedge rClk);
      end

      rS_TDATA  <= iData;
      rS_TVALID <= 1'b1;
      rS_TLAST  <= iLast;

      do begin
        @(posedge rClk);
      end while (!wS_TREADY);

      rS_TVALID <= 1'b0;
      rS_TLAST  <= 1'b0;
      rS_TDATA  <= 8'd0;
    end
  endtask

  task automatic expect_buffer_byte(input logic [31:0] iAddr, input logic [7:0] iExpected);
    logic [31:0] read_data;
    begin
      apb_write({4'd0, LP_ADDR_BUF_ADDR}, iAddr);
      repeat (2) @(posedge rClk);
      apb_read({4'd0, LP_ADDR_BUF_DATA}, read_data);

      if (read_data[7:0] != iExpected) begin
        $fatal(1, "Buffer byte mismatch addr=%0d expected=0x%02h actual=0x%02h",
               iAddr, iExpected, read_data[7:0]);
      end
    end
  endtask

  task automatic capture_tx(input integer iLen);
    begin
      rRxCount = 0;

      while (rRxCount < iLen) begin
        @(posedge rClk);
        rM_TREADY <= (($urandom(rSeed) % 4) != 0);

        if (wM_TVALID && rM_TREADY) begin
          rRxData[rRxCount] = wM_TDATA;

          if ((rRxCount == (iLen - 1)) != wM_TLAST) begin
            $fatal(1, "TLAST mismatch beat=%0d len=%0d last=%0b",
                   rRxCount, iLen, wM_TLAST);
          end

          rRxCount = rRxCount + 1;
        end
      end

      rM_TREADY <= 1'b1;
    end
  endtask

  initial begin
    rSeed = 32'h1234_5678;
    apb_idle();
    rRstn = 1'b0;
    rS_TDATA = 8'd0;
    rS_TVALID = 1'b0;
    rS_TLAST = 1'b0;
    rM_TREADY = 1'b1;
    rCovRxBasic = 1'b0;
    rCovTxBasic = 1'b0;
    rCovBackpressure = 1'b0;
    rCovOffset = 1'b0;
    rCovDebugAccess = 1'b0;
    rCovRangeError = 1'b0;
    rCovEarlyLastError = 1'b0;
    rCovClearStatus = 1'b0;

    repeat (5) @(posedge rClk);
    rRstn = 1'b1;
    repeat (2) @(posedge rClk);

    apb_read({4'd0, LP_ADDR_STATUS}, rReadData);
    if ((rReadData[0] != 1'b0) || (rReadData[1] != 1'b0) || (rReadData[2] != 1'b0)) begin
      $fatal(1, "Reset status is not clean status=0x%08h", rReadData);
    end

    dma_start(1'b0, 32'd0, 32'd8);
    for (idx = 0; idx < 8; idx = idx + 1) begin
      send_stream_byte(8'hA0 + idx[7:0], idx == 7, idx % 3);
    end
    wait_done(80);
    rCovRxBasic = 1'b1;

    apb_read({4'd0, LP_ADDR_COUNT}, rReadData);
    if (rReadData != 32'd8) begin
      $fatal(1, "RX count mismatch count=%0d", rReadData);
    end

    for (idx = 0; idx < 8; idx = idx + 1) begin
      expect_buffer_byte(idx[31:0], 8'hA0 + idx[7:0]);
    end

    dma_start(1'b1, 32'd0, 32'd8);
    capture_tx(8);
    wait_done(80);
    rCovTxBasic = 1'b1;
    rCovBackpressure = 1'b1;

    for (idx = 0; idx < 8; idx = idx + 1) begin
      if (rRxData[idx] != (8'hA0 + idx[7:0])) begin
        $fatal(1, "TX stream mismatch beat=%0d expected=0x%02h actual=0x%02h",
               idx, 8'hA0 + idx[7:0], rRxData[idx]);
      end
    end

    dma_start(1'b0, 32'd16, 32'd4);
    send_stream_byte(8'h11, 1'b0, 0);
    send_stream_byte(8'h22, 1'b0, 1);
    send_stream_byte(8'h33, 1'b0, 0);
    send_stream_byte(8'h44, 1'b1, 2);
    wait_done(80);
    expect_buffer_byte(32'd16, 8'h11);
    expect_buffer_byte(32'd19, 8'h44);
    rCovOffset = 1'b1;

    apb_write({4'd0, LP_ADDR_BUF_ADDR}, 32'd20);
    apb_write({4'd0, LP_ADDR_BUF_DATA}, 32'h0000_005A);
    expect_buffer_byte(32'd20, 8'h5A);
    rCovDebugAccess = 1'b1;

    dma_start(1'b0, 32'd60, 32'd8);
    wait_error(20);
    apb_read({4'd0, LP_ADDR_STATUS}, rReadData);
    if (!rReadData[2]) begin
      $fatal(1, "Range error status bit missing status=0x%08h", rReadData);
    end
    rCovRangeError = 1'b1;

    dma_start(1'b0, 32'd24, 32'd4);
    send_stream_byte(8'hDE, 1'b1, 0);
    wait_error(20);
    rCovEarlyLastError = 1'b1;

    clear_status();
    apb_read({4'd0, LP_ADDR_STATUS}, rReadData);
    if (rReadData[2] || wErrorIrq || wDoneIrq) begin
      $fatal(1, "Status clear failed status=0x%08h done=%0b error=%0b",
             rReadData, wDoneIrq, wErrorIrq);
    end
    rCovClearStatus = 1'b1;

    if (!(rCovRxBasic && rCovTxBasic && rCovBackpressure && rCovOffset &&
          rCovDebugAccess && rCovRangeError && rCovEarlyLastError && rCovClearStatus)) begin
      $fatal(1, "Coverage flags incomplete");
    end

    $display("AXI_STREAM_DMA_FULLCOVERAGE_PASS rx=%0b tx=%0b backpressure=%0b offset=%0b debug=%0b range_error=%0b early_last=%0b clear=%0b",
             rCovRxBasic, rCovTxBasic, rCovBackpressure, rCovOffset,
             rCovDebugAccess, rCovRangeError, rCovEarlyLastError, rCovClearStatus);
    $finish;
  end

endmodule
