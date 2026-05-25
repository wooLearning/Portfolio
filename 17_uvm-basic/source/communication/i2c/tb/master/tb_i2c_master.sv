`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_i2c_master;
  import uvm_pkg::*;
  import tb_i2c_pkg::*;

  logic iClk;

  i2c_master_if i2c_if(.iClk(iClk));

  i2c_master dut (
    .iClk       (iClk),
    .iTick      (i2c_if.iTick),
    .iRst       (i2c_if.iRst),
    .iStart     (i2c_if.iStart),
    .iRead      (i2c_if.iRead),
    .iSlaveAddr (i2c_if.iSlaveAddr),
    .iTxData    (i2c_if.iTxData),
    .iSda       (i2c_if.sda_line),
    .oRxData    (i2c_if.oRxData),
    .oBusy      (i2c_if.oBusy),
    .oDone      (i2c_if.oDone),
    .oAckError  (i2c_if.oAckError),
    .oSclOe     (i2c_if.oSclOe),
    .oSdaOe     (i2c_if.oSdaOe)
  );

  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  initial begin
    uvm_config_db#(i2c_master_vif_t)::set(null, "*", "i2c_master_vif", i2c_if);
    run_test("i2c_master_test");
  end
endmodule
