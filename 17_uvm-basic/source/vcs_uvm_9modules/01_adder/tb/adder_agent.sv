`ifndef ADDER_AGENT_SV
`define ADDER_AGENT_SV

class adder_agent extends uvm_agent;
  `uvm_component_utils(adder_agent)

  adder_sequencer sequencer;
  adder_driver    driver;
  adder_monitor   monitor;

  function new(string name = "adder_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    sequencer = adder_sequencer::type_id::create("sequencer", this);
    driver    = adder_driver::type_id::create("driver", this);
    monitor   = adder_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    driver.seq_item_port.connect(sequencer.seq_item_export);

  endfunction

endclass

`endif