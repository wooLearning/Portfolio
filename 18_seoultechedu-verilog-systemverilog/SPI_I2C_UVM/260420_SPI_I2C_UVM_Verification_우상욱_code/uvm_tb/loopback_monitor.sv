class loopback_monitor extends uvm_monitor;
  `uvm_component_utils(loopback_monitor)

  virtual loopback_uvm_if vif;
  uvm_analysis_port #(loopback_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual loopback_uvm_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "loopback_uvm_if를 찾지 못했습니다.")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit prev_done;
    prev_done = 1'b0;

    while (vif.mon_cb.rst) @(vif.mon_cb);

    forever begin
      loopback_seq_item item;
      @(vif.mon_cb);

      if (vif.mon_cb.done && !prev_done) begin
        bit             cap_mode_i2c;
        bit             cap_read_en;
        bit [1:0]       cap_spi_mode;
        bit [1:0]       cap_reg_sel;
        bit [7:0]       cap_tx_data;

        // Match the original directed TB behavior: capture the command at the
        // completion edge, then wait two clocks before checking the result.
        cap_mode_i2c = vif.mon_cb.mode_i2c;
        cap_read_en  = vif.mon_cb.read_en;
        cap_spi_mode = vif.mon_cb.spi_mode;
        cap_reg_sel  = vif.mon_cb.reg_sel;
        cap_tx_data  = vif.mon_cb.tx_data;
        repeat (2) @(vif.mon_cb);

        item = loopback_seq_item::type_id::create("item");
        item.protocol      = cap_mode_i2c ? LOOP_I2C : LOOP_SPI;
        item.read_en       = cap_read_en;
        item.spi_mode      = cap_spi_mode;
        item.reg_sel       = cap_reg_sel;
        item.tx_data       = cap_tx_data;
        item.obs_digits    = vif.mon_cb.digits;
        item.obs_rx_data   = vif.mon_cb.rx_data;
        item.obs_ack_error = vif.mon_cb.ack_error;
        ap.write(item);
      end

      prev_done = vif.mon_cb.done;
    end
  endtask
endclass
