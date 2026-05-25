`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_spi_slave;
  import uvm_pkg::*;
  import tb_spi_pkg::*;

  logic iClk;

  spi_slave_if spi_if(.iClk(iClk));

  spi_slave dut (
    .iClk     (iClk),
    .iRst     (spi_if.iRst),
    .iCpol    (spi_if.iCpol),
    .iCpha    (spi_if.iCpha),
    .iSclk    (spi_if.iSclk),
    .iCsN     (spi_if.iCsN),
    .iMosi    (spi_if.iMosi),
    .iTxData  (spi_if.iTxData),
    .oRxData  (spi_if.oRxData),
    .oRxValid (spi_if.oRxValid),
    .oMiso    (spi_if.oMiso),
    .oMisoOe  (spi_if.oMisoOe)
  );

  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  initial begin
    uvm_config_db#(spi_slave_vif_t)::set(null, "*", "spi_slave_vif", spi_if);
    run_test("spi_slave_test");
  end
endmodule
