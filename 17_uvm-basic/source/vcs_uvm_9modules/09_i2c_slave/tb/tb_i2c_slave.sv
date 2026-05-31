`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_i2c_slave;
  import uvm_pkg::*;
  import tb_i2c_pkg::*;

  logic iClk;

  i2c_slave_if i2c_if(.iClk(iClk));

  i2c_slave dut (
    .iClk     (iClk),
    .iRst     (i2c_if.iRst),
    .iOwnAddr (i2c_if.iOwnAddr),
    .iTxData  (i2c_if.iTxData),
    .iScl     (i2c_if.scl_line),
    .iSda     (i2c_if.sda_line),
    .oRxData  (i2c_if.oRxData),
    .oRxValid (i2c_if.oRxValid),
    .oTxnDone (i2c_if.oTxnDone),
    .oTxnRead (i2c_if.oTxnRead),
    .oSdaOe   (i2c_if.oSdaOe)
  );

  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  initial begin
    uvm_config_db#(i2c_slave_vif_t)::set(null, "*", "i2c_slave_vif", i2c_if);
    run_test("i2c_slave_test");
  end

`ifdef FSDB
  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_i2c_slave);
  end
`endif
endmodule
