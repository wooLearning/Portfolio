class loopback_driver extends uvm_driver #(loopback_seq_item);
  `uvm_component_utils(loopback_driver)

  virtual loopback_uvm_if vif;
  uvm_analysis_port #(loopback_seq_item) exp_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    exp_ap = new("exp_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual loopback_uvm_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "loopback_uvm_if를 찾지 못했습니다.")
    end
  endfunction

  task wait_reset_release();
    while (vif.mon_cb.rst) @(vif.mon_cb);
    repeat (4) @(vif.drv_cb);
  endtask

  task bus_init();
    vif.drv_cb.rst      <= 1'b0;
    vif.drv_cb.start    <= 1'b0;
    vif.drv_cb.mode_i2c <= 1'b0;
    vif.drv_cb.read_en  <= 1'b0;
    vif.drv_cb.spi_mode <= '0;
    vif.drv_cb.reg_sel  <= '0;
    vif.drv_cb.tx_data  <= '0;
  endtask

  task pulse_start();
    @(vif.drv_cb);
    vif.drv_cb.start <= 1'b1;
    @(vif.drv_cb);
    vif.drv_cb.start <= 1'b0;
  endtask

  task wait_done(loopback_seq_item item);
    int timeout_cycles;
    timeout_cycles = 0;
    while (!vif.mon_cb.done && (timeout_cycles < 5000)) begin
      @(vif.mon_cb);
      timeout_cycles++;
    end
    if (!vif.mon_cb.done) begin
      `uvm_fatal(get_type_name(),
                 $sformatf("done 대기 중 타임아웃 발생: %s", item.convert2string()))
    end
    repeat (2) @(vif.drv_cb);
  endtask

  task drive_transfer(loopback_seq_item item);
    loopback_seq_item exp_item;

    @(vif.drv_cb);
    vif.drv_cb.mode_i2c <= (item.protocol == LOOP_I2C);
    vif.drv_cb.read_en  <= item.read_en;
    vif.drv_cb.spi_mode <= item.spi_mode;
    vif.drv_cb.reg_sel  <= item.reg_sel;
    vif.drv_cb.tx_data  <= item.tx_data;

    if (item.compare_en) begin
      $cast(exp_item, item.clone());
      exp_ap.write(exp_item);
    end

    pulse_start();
    if (item.inject_reset) begin
      repeat (item.reset_delay_cycles) @(vif.drv_cb);
      vif.drv_cb.rst <= 1'b1;
      repeat (4) @(vif.drv_cb);
      vif.drv_cb.rst <= 1'b0;
      bus_init();
      wait_reset_release();
    end
    else begin
      wait_done(item);
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    loopback_seq_item item;

    bus_init();
    wait_reset_release();
    `uvm_info(get_type_name(), "리셋 해제 후 Loopback 시퀀스를 시작합니다.", UVM_MEDIUM)

    forever begin
      seq_item_port.get_next_item(item);
      drive_transfer(item);
      seq_item_port.item_done();
    end
  endtask
endclass
