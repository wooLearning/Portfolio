`timescale 1ns / 1ps

import uvm_pkg::*;
import loopback_uvm_pkg::*;

module tb_loopback_uvm;
  logic clk;

  loopback_uvm_if vif (clk);

  sb_minimal_top dut (
      .iClk    (clk),
      .iRst    (vif.rst),
      .iStart  (vif.start),
      .iModeI2c(vif.mode_i2c),
      .iRead   (vif.read_en),
      .iSpiMode(vif.spi_mode),
      .iRegSel (vif.reg_sel),
      .iTxData (vif.tx_data),
      .oRxData (vif.rx_data),
      .oBusy   (vif.busy),
      .oDone   (vif.done),
      .oAckError(vif.ack_error),
      .oDigits (vif.digits)
  );

  always #5 clk = ~clk;

  initial begin
    clk          = 1'b0;
    vif.rst      = 1'b1;
    vif.start    = 1'b0;
    vif.mode_i2c = 1'b0;
    vif.read_en  = 1'b0;
    vif.spi_mode = '0;
    vif.reg_sel  = '0;
    vif.tx_data  = '0;

    repeat (4) @(negedge clk);
    vif.rst = 1'b0;
  end

  initial begin
    uvm_config_db#(virtual loopback_uvm_if)::set(null, "*", "vif", vif);
    run_test();
  end

  initial begin
    $dumpfile("tb_loopback_uvm.vcd");
    $dumpvars(0, tb_loopback_uvm.dut);
  end
endmodule
