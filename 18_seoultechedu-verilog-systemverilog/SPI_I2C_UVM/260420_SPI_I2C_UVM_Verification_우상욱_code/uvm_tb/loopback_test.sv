class loopback_base_test extends uvm_test;
  `uvm_component_utils(loopback_base_test)

  loopback_env            env;
  virtual loopback_uvm_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = loopback_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual loopback_uvm_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "test에서 loopback_uvm_if를 찾지 못했습니다.")
    end
  endfunction

  task wait_for_reset_done();
    while (vif.mon_cb.rst) @(vif.mon_cb);
    repeat (8) @(vif.mon_cb);
  endtask

  task check_reset_state();
    if (vif.mon_cb.digits !== 16'h0000) begin
      `uvm_fatal(get_type_name(),
                 $sformatf("reset 이후 digits 값이 0이 아닙니다: 0x%04h", vif.mon_cb.digits))
    end
    `uvm_info(get_type_name(), "reset 이후 digits=0x0000 확인", UVM_LOW)
  endtask

  virtual task post_scenario_checks();
  endtask

  task start_sequence(loopback_base_sequence seq);
    seq.start(env.agt.sqr);
  endtask

  virtual task run_scenario();
  endtask

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    wait_for_reset_done();
    check_reset_state();
    run_scenario();
    post_scenario_checks();
    // Give the monitor time to publish the last completed transaction.
    repeat (8) @(vif.mon_cb);
    phase.drop_objection(this);
  endtask
endclass

class loopback_smoke_test extends loopback_base_test;
  `uvm_component_utils(loopback_smoke_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_scenario();
    loopback_smoke_sequence seq;
    seq = loopback_smoke_sequence::type_id::create("seq");
    start_sequence(seq);
  endtask
endclass

class loopback_full_test extends loopback_base_test;
  `uvm_component_utils(loopback_full_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_scenario();
    loopback_full_sequence seq;
    seq = loopback_full_sequence::type_id::create("seq");
    start_sequence(seq);
  endtask
endclass

class loopback_random_test extends loopback_base_test;
  `uvm_component_utils(loopback_random_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_scenario();
    loopback_random_sequence seq;
    seq = loopback_random_sequence::type_id::create("seq");
    seq.num_transactions = 40;
    start_sequence(seq);
  endtask
endclass

class loopback_reset_recovery_test extends loopback_base_test;
  `uvm_component_utils(loopback_reset_recovery_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_scenario();
    loopback_reset_sequence seq;
    seq = loopback_reset_sequence::type_id::create("seq");
    start_sequence(seq);
  endtask

  virtual task post_scenario_checks();
    if (vif.mon_cb.digits !== 16'h0720) begin
      `uvm_fatal(get_type_name(),
                 $sformatf("reset recovery 후 최종 digits mismatch: 0x%04h",
                           vif.mon_cb.digits))
    end
  endtask
endclass

class loopback_comprehensive_test extends loopback_base_test;
  `uvm_component_utils(loopback_comprehensive_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_scenario();
    loopback_comprehensive_sequence seq;
    seq = loopback_comprehensive_sequence::type_id::create("seq");
    seq.random_transactions = 64;
    start_sequence(seq);
  endtask

  virtual task post_scenario_checks();
    if (vif.mon_cb.digits !== 16'h0720) begin
      `uvm_fatal(get_type_name(),
                 $sformatf("comprehensive 종료 후 최종 digits mismatch: 0x%04h",
                           vif.mon_cb.digits))
    end
  endtask
endclass

class loopback_run_test extends loopback_comprehensive_test;
  `uvm_component_utils(loopback_run_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
