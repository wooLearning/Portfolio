class loopback_sequencer extends uvm_sequencer #(loopback_seq_item);
  `uvm_component_utils(loopback_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class loopback_agent extends uvm_agent;
  `uvm_component_utils(loopback_agent)

  loopback_sequencer            sqr;
  loopback_driver                   drv;
  loopback_monitor                  mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = loopback_sequencer::type_id::create("sqr", this);
    drv = loopback_driver::type_id::create("drv", this);
    mon = loopback_monitor::type_id::create("mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass

class loopback_env extends uvm_env;
  `uvm_component_utils(loopback_env)

  loopback_agent      agt;
  loopback_scoreboard scb;
  loopback_coverage   cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = loopback_agent::type_id::create("agt", this);
    scb = loopback_scoreboard::type_id::create("scb", this);
    cov = loopback_coverage::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.drv.exp_ap.connect(scb.exp_imp);
    agt.mon.ap.connect(scb.act_imp);
    agt.mon.ap.connect(cov.analysis_export);
  endfunction
endclass
