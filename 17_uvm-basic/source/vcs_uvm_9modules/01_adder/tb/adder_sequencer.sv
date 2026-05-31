`ifndef ADDER_SEQUENCER_SV
`define ADDER_SEQUENCER_SV

class adder_sequencer extends uvm_sequencer #(adder_seq_item);
  `uvm_component_utils(adder_sequencer)

  function new(string name = "adder_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif
