`ifndef RAM_TEST_SV
`define RAM_TEST_SV

class ram_test extends uvm_test;
  `uvm_component_utils(ram_test)

  ram_env env;

  function new(string name = "ram_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ram_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    ram_sequence seq;

    phase.raise_objection(this);

    seq = ram_sequence::type_id::create("seq");
    seq.start(env.agt.sequencer);

    repeat (5) @(posedge env.agt.monitor.ram_vif.iClk);
    phase.drop_objection(this);
  endtask

endclass

`endif
