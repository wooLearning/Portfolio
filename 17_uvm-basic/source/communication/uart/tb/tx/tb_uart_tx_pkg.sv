`ifndef TB_UART_TX_PKG_SV
`define TB_UART_TX_PKG_SV

`include "uvm_macros.svh"

package tb_uart_tx_pkg;
  import uvm_pkg::*;

  parameter int DATA_BITS  = 8;
  parameter int OVERSAMPLE = 16;
  parameter int TICK_TIMEOUT_CYCLES = 32;

  typedef virtual uart_tx_if #(DATA_BITS, OVERSAMPLE) uart_tx_vif_t;

  `uvm_analysis_imp_decl(_exp)
  `uvm_analysis_imp_decl(_obs)

  `include "uart_tx_types.sv"
  `include "uart_tx_seq_item.sv"
  `include "uart_tx_obs_item.sv"
  `include "uart_tx_sequence.sv"
  `include "uart_tx_sequencer.sv"
  `include "uart_tx_driver.sv"
  `include "uart_tx_monitor.sv"
  `include "uart_tx_scoreboard.sv"
  `include "uart_tx_coverage.sv"
  `include "uart_tx_agent.sv"
  `include "uart_tx_env.sv"
  `include "uart_tx_test.sv"
endpackage

`endif
