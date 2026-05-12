`ifndef TB_FIFO_PKG_SV
`define TB_FIFO_PKG_SV

`include "uvm_macros.svh"

package tb_fifo_pkg;
  import uvm_pkg::*;

  parameter int DATA_WIDTH = 64;
  parameter int DEPTH      = 4;
  parameter int ADDR_WIDTH = $clog2(DEPTH);

  `include "fifo_seq_item.sv"
  `include "fifo_sequence.sv"
  `include "fifo_sequencer.sv"
  `include "fifo_driver.sv"
  `include "fifo_monitor.sv"
  `include "fifo_scoreboard.sv"
  `include "fifo_coverage.sv"
  `include "fifo_agent.sv"
  `include "fifo_env.sv"
  `include "fifo_test.sv"
endpackage

`endif
