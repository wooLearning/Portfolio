`timescale 1ns / 1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import tb_ram_pkg::*;

module tb_ram;

  logic iClk;

  ram_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) rif (
    .iClk(iClk)
  );

  ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) dut (
    .iClk(rif.iClk),
    .iRstn(rif.iRstn),
    .iCs(rif.iCs),
    .iWea(rif.iWea),
    .iAddr(rif.iAddr),
    .iWData(rif.iWData),
    .oRData(rif.oRData)
  );

  ram_sva #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_ram_sva (
    .iClk(rif.iClk),
    .iRstn(rif.iRstn),
    .iCs(rif.iCs),
    .iWea(rif.iWea),
    .iAddr(rif.iAddr),
    .iWData(rif.iWData),
    .oRData(rif.oRData)
  );

  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  initial begin
    rif.iRstn  = 1'b0;
    rif.iCs    = 1'b0;
    rif.iWea   = 1'b0;
    rif.iAddr  = '0;
    rif.iWData = '0;

    repeat (2) @(posedge iClk);
    rif.iRstn = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual ram_if)::set(null, "*", "ram_vif", rif);
    run_test("ram_test");
  end

  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_ram);
  end

endmodule
