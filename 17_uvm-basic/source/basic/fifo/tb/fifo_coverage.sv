`ifndef FIFO_COVERAGE_SV
`define FIFO_COVERAGE_SV

class fifo_coverage extends uvm_subscriber #(fifo_seq_item);
  `uvm_component_utils(fifo_coverage)

  fifo_seq_item item;

  covergroup fifo_cg;
    option.per_instance = 1;

    cp_cmd : coverpoint {item.iWrEn, item.iRdEn} {
      bins idle     = {2'b00};
      bins write    = {2'b10};
      bins read     = {2'b01};
      bins wr_rd    = {2'b11};
    }

    cp_full : coverpoint item.oFull {
      bins not_full = {0};
      bins full     = {1};
    }

    cp_empty : coverpoint item.oEmpty {
      bins not_empty = {0};
      bins empty     = {1};
    }

    cp_count : coverpoint item.oCount {
      bins zero = {0};
      bins full = {DEPTH};
      bins mid  = {[1:DEPTH-1]};
    }

    cross_cmd_status : cross cp_cmd, cp_count;
  endgroup

  function new(string name = "fifo_coverage", uvm_component parent);
    super.new(name, parent);
    fifo_cg = new();
  endfunction

  function void write(fifo_seq_item t);
    item = t;
    fifo_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("FIFO_COV",
              $sformatf("Functional coverage = %0.2f%%", fifo_cg.get_coverage()),
              UVM_LOW)
  endfunction
endclass

`endif
