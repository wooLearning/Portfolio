`timescale 1ns/1ps

module tb_sb_minimal;

  logic        clk;
  logic        rst;
  logic        start;
  logic        mode_i2c;
  logic        read_en;
  logic [1:0]  spi_mode;
  logic [1:0]  reg_sel;
  logic [7:0]  tx_data;
  logic [7:0]  rx_data;
  logic        busy;
  logic        done;
  logic        ack_error;
  logic [15:0] digits;

  sb_minimal_top dut (
    .iClk    (clk),
    .iRst    (rst),
    .iStart  (start),
    .iModeI2c(mode_i2c),
    .iRead   (read_en),
    .iSpiMode(spi_mode),
    .iRegSel (reg_sel),
    .iTxData (tx_data),
    .oRxData (rx_data),
    .oBusy   (busy),
    .oDone   (done),
    .oAckError(ack_error),
    .oDigits (digits)
  );

  always #5 clk = ~clk;

  task automatic kick_start;
    begin
      @(negedge clk);
      start = 1'b1;
      @(negedge clk);
      start = 1'b0;
    end
  endtask

  task automatic wait_done;
    int timeout_cycles;
    begin
      timeout_cycles = 0;
      while (!done && (timeout_cycles < 5000)) begin
        @(posedge clk);
        timeout_cycles++;
      end

      if (!done) begin
        $fatal(1, "Timed out waiting for transaction completion");
      end

      repeat (2) @(posedge clk);
    end
  endtask

  task automatic expect_digits(
    input logic [15:0] exp_digits,
    input string       label
  );
    begin
      if (digits !== exp_digits) begin
        $fatal(1, "%s: expected digits %h, got %h", label, exp_digits, digits);
      end
      else begin
        $display("[%0t] PASS %s digits=%h", $time, label, digits);
      end
    end
  endtask

  task automatic spi_write_check(
    input logic [1:0]  mode_sel,
    input logic [1:0]  addr_sel,
    input logic [7:0]  wr_data,
    input logic [15:0] exp_digits,
    input logic [7:0]  exp_rx_data,
    input string       label
  );
    begin
      mode_i2c = 1'b0;
      read_en  = 1'b0;
      spi_mode = mode_sel;
      reg_sel  = addr_sel;
      tx_data  = wr_data;
      kick_start();
      wait_done();
      expect_digits(exp_digits, label);

      if (rx_data !== exp_rx_data) begin
        $fatal(1, "%s: expected SPI rx %h, got %h", label, exp_rx_data, rx_data);
      end
    end
  endtask

  task automatic i2c_write_check(
    input logic [1:0]  addr_sel,
    input logic [7:0]  wr_data,
    input logic [15:0] exp_digits,
    input string       label
  );
    begin
      mode_i2c = 1'b1;
      read_en  = 1'b0;
      reg_sel  = addr_sel;
      tx_data  = wr_data;
      kick_start();
      wait_done();
      expect_digits(exp_digits, label);

      if (ack_error) begin
        $fatal(1, "%s: unexpected ACK error after I2C write", label);
      end
    end
  endtask

  task automatic i2c_read_check(
    input logic [1:0]  addr_sel,
    input logic [7:0]  exp_rx_data,
    input logic [15:0] exp_digits,
    input string       label
  );
    begin
      mode_i2c = 1'b1;
      read_en  = 1'b1;
      reg_sel  = addr_sel;
      tx_data  = 8'h00;
      kick_start();
      wait_done();
      expect_digits(exp_digits, label);

      if (rx_data !== exp_rx_data) begin
        $fatal(1, "%s: expected I2C rx %h, got %h", label, exp_rx_data, rx_data);
      end

      if (ack_error) begin
        $fatal(1, "%s: unexpected ACK error after I2C read", label);
      end
    end
  endtask

  initial begin
    clk      = 1'b0;
    rst      = 1'b0;
    start    = 1'b0;
    mode_i2c = 1'b0;
    read_en  = 1'b0;
    spi_mode = 2'b00;
    reg_sel  = 2'b00;
    tx_data  = 8'h00;

    $dumpfile("tb_sb_minimal.vcd");
    $dumpvars(0, tb_sb_minimal);

    rst = 1'b1;
    repeat (4) @(negedge clk);
    rst = 1'b0;
    repeat (4) @(negedge clk);

    expect_digits(16'h0000, "reset");

    spi_write_check(2'b00, 2'b00, 8'h05, 16'h0005, 8'h00, "spi write reg0=0x05");
    spi_write_check(2'b01, 2'b01, 8'h16, 16'h0065, 8'h00, "spi write reg1=0x16");
    spi_write_check(2'b10, 2'b10, 8'h27, 16'h0765, 8'h00, "spi write reg2=0x27");
    spi_write_check(2'b11, 2'b11, 8'h38, 16'h8765, 8'h00, "spi write reg3=0x38");
    spi_write_check(2'b10, 2'b10, 8'h2A, 16'h8A65, 8'h07, "spi overwrite reg2 old=0x07");
    spi_write_check(2'b00, 2'b00, 8'h0C, 16'h8A6C, 8'h05, "spi overwrite reg0 old=0x05");
    spi_write_check(2'b11, 2'b01, 8'h2D, 16'h8ADC, 8'h06, "spi mode3 write reg1=0x2D");

    i2c_write_check(2'b00, 8'h01, 16'h8AD1, "i2c write reg0=0x01");
    i2c_write_check(2'b01, 8'h02, 16'h8A21, "i2c write reg1=0x02");
    i2c_write_check(2'b10, 8'h03, 16'h8321, "i2c write reg2=0x03");
    i2c_write_check(2'b11, 8'h04, 16'h4321, "i2c write reg3=0x04");

    i2c_read_check(2'b00, 8'h01, 16'h4321, "i2c read reg0");
    i2c_read_check(2'b01, 8'h02, 16'h4321, "i2c read reg1");
    i2c_read_check(2'b10, 8'h03, 16'h4321, "i2c read reg2");
    i2c_read_check(2'b11, 8'h04, 16'h4321, "i2c read reg3");

    $display("[%0t] All minimal single-board loopback checks passed.", $time);
    #100;
    $finish;
  end

endmodule
