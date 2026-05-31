`timescale 1ns / 1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import tb_fifo_pkg::*;

module tb_fifo;

  logic iClk;

  fifo_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) fif (
    .iClk(iClk)
  );

  sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) dut (
    .iClk(fif.iClk),
    .iRstn(fif.iRstn),
    .iWrEn(fif.iWrEn),
    .iRdEn(fif.iRdEn),
    .iWrData(fif.iWrData),
    .oRdData(fif.oRdData),
    .oFull(fif.oFull),
    .oEmpty(fif.oEmpty),
    .oCount(fif.oCount)
  );

  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  initial begin
    fif.iRstn   = 1'b0;
    fif.iWrEn   = 1'b0;
    fif.iRdEn   = 1'b0;
    fif.iWrData = '0;

    repeat (2) @(posedge iClk);
    fif.iRstn = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual fifo_if)::set(null, "*", "fifo_vif", fif);
    run_test("fifo_test");
  end

  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_fifo);
  end
endmodule
