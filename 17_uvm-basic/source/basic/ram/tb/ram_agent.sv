`ifndef RAM_AGENT_SV
`define RAM_AGENT_SV

class ram_agent extends uvm_agent;
  `uvm_component_utils(ram_agent)

  ram_sequencer sequencer;
  ram_driver    driver;
  ram_monitor   monitor;

  function new(string name = "ram_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    sequencer = ram_sequencer::type_id::create("sequencer", this);
    driver    = ram_driver::type_id::create("driver", this);
    monitor   = ram_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass

`endif
