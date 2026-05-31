`ifndef FIFO_TEST_SV
`define FIFO_TEST_SV

class fifo_test extends uvm_test;
  `uvm_component_utils(fifo_test)

  fifo_env env;

  function new(string name = "fifo_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_sequence seq;

    phase.raise_objection(this);

    seq = fifo_sequence::type_id::create("seq");
    seq.start(env.agt.sequencer);

    repeat (5) @(posedge env.agt.monitor.fifo_vif.iClk);
    phase.drop_objection(this);
  endtask
endclass

`endif
