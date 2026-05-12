`timescale 1ns / 1ps

`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_adder_pkg::*;

module tb_adder();

  adder_if #(DATA_WIDTH) aif();

  adder #(.DATA_WIDTH(DATA_WIDTH)) dut (
    .iA(aif.iA),
    .iB(aif.iB),
    .oY(aif.oY)
  );

  initial begin
    uvm_config_db#(virtual adder_if)::set(null, "*", "adder_vif", aif);
    run_test("adder_test");
  end

  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_adder);
  end
  
endmodule
