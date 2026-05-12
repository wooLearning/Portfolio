`ifndef ADDER_TEST_SV
`define ADDER_TEST_SV

class adder_test extends uvm_test;
  `uvm_component_utils(adder_test)

  adder_env env;

  function new(string name = "adder_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = adder_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    adder_sequence seq;

    phase.raise_objection(this);

    seq = adder_sequence::type_id::create("seq");
    seq.start(env.agt.sequencer);

    #10;
    phase.drop_objection(this);
  endtask

endclass

`endif
