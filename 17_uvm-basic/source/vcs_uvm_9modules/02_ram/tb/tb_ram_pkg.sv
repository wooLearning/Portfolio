`ifndef TB_RAM_PKG_SV
`define TB_RAM_PKG_SV

`include "uvm_macros.svh"

package tb_ram_pkg;
  import uvm_pkg::*;

  parameter int DATA_WIDTH = 32;
  parameter int DEPTH      = 16;
  parameter int ADDR_WIDTH = $clog2(DEPTH);

  `include "ram_seq_item.sv"
  `include "ram_sequence.sv"
  `include "ram_sequencer.sv"
  `include "ram_driver.sv"
  `include "ram_monitor.sv"
  `include "ram_agent.sv"
  `include "ram_scoreboard.sv"
  `include "ram_coverage.sv"
  `include "ram_env.sv"
  `include "ram_test.sv"
endpackage

`endif
