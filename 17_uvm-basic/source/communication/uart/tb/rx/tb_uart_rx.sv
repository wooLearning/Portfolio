`timescale 1ns / 1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import tb_uart_rx_pkg::*;

module tb_uart_rx;

  logic iClk;

  uart_rx_if #(
    .DATA_BITS(DATA_BITS),
    .OVERSAMPLE(OVERSAMPLE)
  ) uart_if (
    .iClk(iClk)
  );

  uart_rx #(
    .DATA_BITS(DATA_BITS),
    .OVERSAMPLE(OVERSAMPLE),
    .TICK_TIMEOUT_CYCLES(TICK_TIMEOUT_CYCLES)
  ) dut (
    .iClk(uart_if.iClk),
    .iRst(uart_if.iRst),
    .iTick16x(uart_if.iTick16x),
    .iRx(uart_if.iRx),
    .oRxData(uart_if.oRxData),
    .oRxValid(uart_if.oRxValid),
    .oRxBusy(uart_if.oRxBusy),
    .oFrameError(uart_if.oFrameError)
  );

  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  initial begin
    uart_if.iRst     = 1'b1;
    uart_if.iTick16x = 1'b0;
    uart_if.iRx      = 1'b1;
  end

  initial begin
    uvm_config_db#(uart_rx_vif_t)::set(null, "*", "uart_vif", uart_if);
    run_test("uart_rx_test");
  end

`ifdef FSDB
  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_uart_rx);
  end
`endif
endmodule
