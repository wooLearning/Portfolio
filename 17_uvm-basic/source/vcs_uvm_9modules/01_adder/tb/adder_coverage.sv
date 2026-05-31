`ifndef ADDER_COVERAGE_SV
`define ADDER_COVERAGE_SV

class adder_coverage extends uvm_subscriber #(adder_seq_item);
  `uvm_component_utils(adder_coverage)

  adder_seq_item item;

  covergroup adder_cg;
    option.per_instance = 1;

    cp_iA : coverpoint item.iA {
      bins zero = {0};
      bins max  = {'1};
      bins misc = default;
    }

    cp_iB : coverpoint item.iB {
      bins zero = {0};
      bins max  = {'1};
      bins misc = default;
    }

    cp_carry : coverpoint item.oY[DATA_WIDTH] {
      bins no_carry = {0};
      bins carry    = {1};
    }

    cross_iA_iB : cross cp_iA, cp_iB;
  endgroup

  function new(string name = "adder_coverage", uvm_component parent);
    super.new(name, parent);
    adder_cg = new();
  endfunction

  function void write(adder_seq_item t);
    item = t;
    adder_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("ADDER_COV", $sformatf("Functional coverage = %0.2f%%", adder_cg.get_coverage()), UVM_LOW)
  endfunction

endclass

`endif
