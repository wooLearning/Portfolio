class loopback_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(loopback_scoreboard)

  uvm_analysis_imp_exp #(loopback_seq_item, loopback_scoreboard) exp_imp;
  uvm_analysis_imp_act #(loopback_seq_item, loopback_scoreboard) act_imp;

  loopback_seq_item exp_q[$];
  int match_count;
  int error_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    exp_imp = new("exp_imp", this);
    act_imp = new("act_imp", this);
  endfunction

  function void write_exp(loopback_seq_item t);
    loopback_seq_item item;
    $cast(item, t.clone());
    exp_q.push_back(item);
  endfunction

  function void compare_items(loopback_seq_item exp_item, loopback_seq_item act_item);
    string prefix;
    prefix = $sformatf("protocol=%s read=%0b reg=%0d", exp_item.protocol_name(),
                       exp_item.read_en, exp_item.reg_sel);

    if (exp_item.protocol != act_item.protocol) begin
      `uvm_error(get_type_name(), $sformatf("%s protocol mismatch", prefix))
      error_count++;
    end
    else if (exp_item.read_en != act_item.read_en) begin
      `uvm_error(get_type_name(), $sformatf("%s read mismatch", prefix))
      error_count++;
    end
    else if ((exp_item.protocol == LOOP_SPI) && (exp_item.spi_mode != act_item.spi_mode)) begin
      `uvm_error(get_type_name(), $sformatf("%s spi_mode mismatch exp=%0d act=%0d", prefix,
                                            exp_item.spi_mode, act_item.spi_mode))
      error_count++;
    end
    else if (exp_item.reg_sel != act_item.reg_sel) begin
      `uvm_error(get_type_name(), $sformatf("%s reg mismatch exp=%0d act=%0d", prefix,
                                            exp_item.reg_sel, act_item.reg_sel))
      error_count++;
    end
    else if (exp_item.exp_digits != act_item.obs_digits) begin
      `uvm_error(get_type_name(),
                 $sformatf("%s digits mismatch exp=0x%04h act=0x%04h", prefix,
                           exp_item.exp_digits, act_item.obs_digits))
      error_count++;
    end
    else if (exp_item.exp_ack_error != act_item.obs_ack_error) begin
      `uvm_error(get_type_name(),
                 $sformatf("%s ack mismatch exp=%0b act=%0b", prefix,
                           exp_item.exp_ack_error, act_item.obs_ack_error))
      error_count++;
    end
    else if (!exp_item.exp_ack_error &&
             (((exp_item.protocol == LOOP_SPI) ||
               ((exp_item.protocol == LOOP_I2C) && exp_item.read_en)) &&
              (exp_item.exp_rx_data != act_item.obs_rx_data))) begin
      `uvm_error(get_type_name(),
                 $sformatf("%s rx mismatch exp=0x%02h act=0x%02h", prefix,
                           exp_item.exp_rx_data, act_item.obs_rx_data))
      error_count++;
    end
    else begin
      match_count++;
      `uvm_info(get_type_name(), $sformatf("scoreboard match: %s", prefix), UVM_LOW)
    end
  endfunction

  function void write_act(loopback_seq_item t);
    loopback_seq_item exp_item;

    if (exp_q.size() == 0) begin
      `uvm_error(get_type_name(), $sformatf("actual item이 먼저 도착했습니다: %s",
                                            t.convert2string()))
      error_count++;
      return;
    end

    exp_item = exp_q.pop_front();
    compare_items(exp_item, t);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("Loopback scoreboard summary: match=%0d error=%0d pending=%0d",
                        match_count, error_count, exp_q.size()), UVM_NONE)
    if (exp_q.size() != 0) begin
      `uvm_error(get_type_name(),
                 $sformatf("비교되지 않은 expected item이 %0d개 남았습니다.", exp_q.size()))
    end
  endfunction
endclass
