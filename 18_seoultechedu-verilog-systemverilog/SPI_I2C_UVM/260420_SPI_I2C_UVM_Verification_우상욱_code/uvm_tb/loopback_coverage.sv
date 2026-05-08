class loopback_coverage extends uvm_subscriber #(loopback_seq_item);
  `uvm_component_utils(loopback_coverage)

  virtual loopback_uvm_if vif;
  loopback_seq_item item;
  loop_protocol_e cov_protocol;
  bit             cov_read_en;
  bit [1:0]       cov_spi_mode;
  bit [1:0]       cov_reg_sel;
  bit             cov_ack_error;
  bit             cov_overwrite;
  bit             cov_protocol_switch;
  bit             cov_reset_event;
  bit [1:0]       cov_data_class;
  bit             reg_written[4];
  bit             first_transfer_after_reset;
  bit             has_prev_protocol;
  loop_protocol_e prev_protocol;

  covergroup loopback_cg;
    cp_protocol: coverpoint cov_protocol;
    cp_read_en: coverpoint cov_read_en {bins write = {0}; bins read = {1};}
    cp_spi_mode: coverpoint cov_spi_mode {
      bins mode0 = {2'b00};
      bins mode1 = {2'b01};
      bins mode2 = {2'b10};
      bins mode3 = {2'b11};
    }
    cp_reg_sel: coverpoint cov_reg_sel {
      bins reg0 = {2'b00};
      bins reg1 = {2'b01};
      bins reg2 = {2'b10};
      bins reg3 = {2'b11};
    }
    // In the internal singleboard loopback DUT, all four I2C slave addresses
    // are permanently present, so a NACK cannot be produced by this topology.
    cp_ack_error: coverpoint cov_ack_error iff (cov_protocol == LOOP_I2C) {
      bins ack_ok = {0};
      ignore_bins nack_unreachable = {1};
    }
    cp_overwrite: coverpoint cov_overwrite {bins fresh = {0}; bins overwrite = {1};}
    cp_protocol_switch: coverpoint cov_protocol_switch {bins no = {0}; bins yes = {1};}
    cp_reset_event: coverpoint cov_reset_event {bins normal = {0}; bins post_reset = {1};}
    cp_data_class: coverpoint cov_data_class {
      bins zero = {2'b00};
      bins low = {2'b01};
      bins mid = {2'b10};
      bins high = {2'b11};
    }
    cx_protocol_reg: cross cp_protocol, cp_reg_sel;
    cx_protocol_rw: cross cp_protocol, cp_read_en {
      // SPI is modeled as write-only in this DUT. Readback is observed on SPI
      // writes, but there is no standalone SPI read transaction.
      ignore_bins spi_read = binsof(cp_protocol) intersect {LOOP_SPI} &&
                             binsof(cp_read_en) intersect {1};
    }
    cx_spi_mode_reg: cross cp_spi_mode, cp_reg_sel;
    cx_protocol_reset: cross cp_protocol, cp_reset_event;
    cx_overwrite_reg: cross cp_overwrite, cp_reg_sel;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    loopback_cg = new();
    foreach (reg_written[idx]) reg_written[idx] = 1'b0;
    first_transfer_after_reset = 1'b1;
    has_prev_protocol = 1'b0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual loopback_uvm_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "loopback_uvm_if를 찾지 못했습니다.")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit prev_rst;

    prev_rst = 1'b1;
    forever begin
      @(vif.mon_cb);
      if (!vif.mon_cb.rst && prev_rst) begin
        first_transfer_after_reset = 1'b1;
      end
      if (vif.mon_cb.rst) begin
        has_prev_protocol = 1'b0;
      end
      prev_rst = vif.mon_cb.rst;
    end
  endtask

  function bit [1:0] classify_data(bit [7:0] data);
    if (data[3:0] == 4'h0) return 2'b00;
    else if (data[3:0] inside {[4'h1:4'h5]}) return 2'b01;
    else if (data[3:0] inside {[4'h6:4'hA]}) return 2'b10;
    else return 2'b11;
  endfunction

  virtual function void write(loopback_seq_item t);
    this.item = t;
    cov_protocol        = t.protocol;
    cov_read_en         = t.read_en;
    cov_spi_mode        = t.spi_mode;
    cov_reg_sel         = t.reg_sel;
    cov_ack_error       = t.obs_ack_error;
    cov_overwrite       = (!t.read_en) && reg_written[t.reg_sel];
    cov_protocol_switch = has_prev_protocol && (t.protocol != prev_protocol);
    cov_reset_event     = first_transfer_after_reset;
    cov_data_class      = classify_data(t.read_en ? t.obs_rx_data : t.tx_data);
    loopback_cg.sample();

    if (!t.read_en) reg_written[t.reg_sel] = 1'b1;
    first_transfer_after_reset = 1'b0;
    has_prev_protocol = 1'b1;
    prev_protocol = t.protocol;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("Loopback coverage = %.1f%%", loopback_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
