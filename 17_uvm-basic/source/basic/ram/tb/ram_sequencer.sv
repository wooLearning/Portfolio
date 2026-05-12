`ifndef RAM_SEQUENCER_SV
`define RAM_SEQUENCER_SV

class ram_sequencer extends uvm_sequencer #(ram_seq_item);
  `uvm_component_utils(ram_sequencer)

  function new(string name = "ram_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif
