`ifndef RAM_COVERAGE_SV
`define RAM_COVERAGE_SV

class ram_coverage extends uvm_subscriber #(ram_seq_item);
  `uvm_component_utils(ram_coverage)

  ram_seq_item item;

  covergroup ram_cg;
    option.per_instance = 1;

    cp_cmd : coverpoint item.iWea {
      bins write = {1'b1};
      bins read  = {1'b0};
    }

    cp_addr : coverpoint item.iAddr {
      bins first = {0};
      bins last  = {DEPTH - 1};
      bins misc  = default;
    }

    cp_wdata : coverpoint item.iWData iff (item.iWea) {
      bins zero = {'0};
      bins ones = {'1};
      bins misc = default;
    }

    cp_rdata : coverpoint item.oRData iff (!item.iWea) {
      bins zero = {'0};
      bins ones = {'1};
      bins misc = default;
    }

    cross_cmd_addr : cross cp_cmd, cp_addr;
  endgroup

  function new(string name = "ram_coverage", uvm_component parent);
    super.new(name, parent);
    ram_cg = new();
  endfunction

  function void write(ram_seq_item t);
    item = t;
    ram_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("RAM_COV",
              $sformatf("Functional coverage = %0.2f%%", ram_cg.get_coverage()),
              UVM_LOW)
  endfunction

endclass

`endif
