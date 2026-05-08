`ifndef LOOPBACK_UVM_PKG_SV
`define LOOPBACK_UVM_PKG_SV

package loopback_uvm_pkg;

`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_exp)
`uvm_analysis_imp_decl(_act)

`include "loopback_seq_item.sv"
`include "loopback_sequence.sv"
`include "loopback_driver.sv"
`include "loopback_monitor.sv"
`include "loopback_coverage.sv"
`include "loopback_scoreboard.sv"
`include "loopback_env.sv"
`include "loopback_test.sv"

endpackage

`endif
