`ifndef TB_UART_RX_PKG_SV
`define TB_UART_RX_PKG_SV

`include "uvm_macros.svh"

package tb_uart_rx_pkg;
  import uvm_pkg::*;

  parameter int DATA_BITS  = 8;
  parameter int OVERSAMPLE = 16;
  parameter int TICK_TIMEOUT_CYCLES = 32;

  typedef virtual uart_rx_if #(DATA_BITS, OVERSAMPLE) uart_rx_vif_t;

  `uvm_analysis_imp_decl(_exp)
  `uvm_analysis_imp_decl(_obs)
  `uvm_analysis_imp_decl(_ser)

  `include "uart_rx_types.sv"
  `include "uart_rx_seq_item.sv"
  `include "uart_rx_obs_item.sv"
  `include "uart_rx_serial_item.sv"
  `include "uart_rx_sequence.sv"
  `include "uart_rx_sequencer.sv"
  `include "uart_rx_driver.sv"
  `include "uart_rx_monitor.sv"
  `include "uart_rx_scoreboard.sv"
  `include "uart_rx_coverage.sv"
  `include "uart_rx_agent.sv"
  `include "uart_rx_env.sv"
  `include "uart_rx_test.sv"
endpackage

`endif
