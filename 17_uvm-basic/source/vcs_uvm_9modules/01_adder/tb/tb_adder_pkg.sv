`include "uvm_macros.svh"
package tb_adder_pkg;

  import uvm_pkg::*;
  
  parameter int DATA_WIDTH = 32;
  
  `include "adder_seq_item.sv"
  `include "adder_sequence.sv"
  `include "adder_sequencer.sv"
  `include "adder_driver.sv"
  `include "adder_monitor.sv"
  `include "adder_agent.sv"
  `include "adder_scoreboard.sv"
  `include "adder_coverage.sv"
  `include "adder_env.sv"
  `include "adder_test.sv"
endpackage
