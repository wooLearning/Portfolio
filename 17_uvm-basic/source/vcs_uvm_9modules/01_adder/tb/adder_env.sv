`ifndef ADDER_ENV_SV
`define ADDER_ENV_SV

class adder_env extends uvm_env;
  `uvm_component_utils(adder_env)
  
  adder_agent agt;
  adder_scoreboard scb;
  adder_coverage cov;

  function new(string name = "adder_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agt = adder_agent::type_id::create("agt", this);
    scb = adder_scoreboard::type_id::create("scb", this);
    cov = adder_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    agt.monitor.send.connect(scb.recv);
    agt.monitor.send.connect(cov.analysis_export);
  endfunction

endclass
`endif
