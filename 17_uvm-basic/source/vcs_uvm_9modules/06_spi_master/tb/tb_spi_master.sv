`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_spi_master;
  import uvm_pkg::*;
  import tb_spi_pkg::*;

  logic iClk;

  spi_master_if spi_if(.iClk(iClk));

  spi_master dut (
    .iClk    (iClk),
    .iTick   (spi_if.iTick),
    .iRst    (spi_if.iRst),
    .iStart  (spi_if.iStart),
    .iCpol   (spi_if.iCpol),
    .iCpha   (spi_if.iCpha),
    .iTxData (spi_if.iTxData),
    .iMiso   (spi_if.iMiso),
    .oRxData (spi_if.oRxData),
    .oBusy   (spi_if.oBusy),
    .oDone   (spi_if.oDone),
    .oSclk   (spi_if.oSclk),
    .oCsN    (spi_if.oCsN),
    .oMosi   (spi_if.oMosi)
  );

  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  initial begin
    uvm_config_db#(spi_master_vif_t)::set(null, "*", "spi_master_vif", spi_if);
    run_test("spi_master_test");
  end

`ifdef FSDB
  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_spi_master);
  end
`endif
endmodule
