`timescale 1ns / 1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import tb_uart_tx_pkg::*;

module tb_uart_tx;

  logic iClk;

  uart_tx_if #(
    .DATA_BITS(DATA_BITS),
    .OVERSAMPLE(OVERSAMPLE)
  ) uart_if (
    .iClk(iClk)
  );

  uart_tx #(
    .DATA_BITS(DATA_BITS),
    .OVERSAMPLE(OVERSAMPLE),
    .TICK_TIMEOUT_CYCLES(TICK_TIMEOUT_CYCLES)
  ) dut (
    .iClk(uart_if.iClk),
    .iRst(uart_if.iRst),
    .iTick16x(uart_if.iTick16x),
    .iTxData(uart_if.iTxData),
    .iTxValid(uart_if.iTxValid),
    .oTxReady(uart_if.oTxReady),
    .oTx(uart_if.oTx),
    .oTxBusy(uart_if.oTxBusy),
    .oTxDone(uart_if.oTxDone)
  );

  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  initial begin
    uart_if.iRst     = 1'b1;
    uart_if.iTick16x = 1'b0;
    uart_if.iTxData  = '0;
    uart_if.iTxValid = 1'b0;
  end

  initial begin
    uvm_config_db#(uart_tx_vif_t)::set(null, "*", "uart_vif", uart_if);
    run_test("uart_tx_test");
  end

`ifdef FSDB
  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_uart_tx);
  end
`endif
endmodule
