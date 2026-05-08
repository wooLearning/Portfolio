class loopback_base_sequence extends uvm_sequence #(loopback_seq_item);
  `uvm_object_utils(loopback_base_sequence)

  bit [3:0] reg_model[4];
  bit [1:0] current_spi_mode;

  function new(string name = "loopback_base_sequence");
    super.new(name);
  endfunction

  function void reset_model();
    foreach (reg_model[idx]) reg_model[idx] = 4'h0;
    current_spi_mode = 2'b00;
  endfunction

  function bit [15:0] model_digits();
    return {reg_model[3], reg_model[2], reg_model[1], reg_model[0]};
  endfunction

  task send_tx(loop_protocol_e protocol,
               bit             read_en,
               bit [1:0]       spi_mode,
               bit [1:0]       reg_sel,
               bit [7:0]       tx_data,
               bit [15:0]      exp_digits,
               bit [7:0]       exp_rx_data,
               bit             exp_ack_error = 1'b0);
    loopback_seq_item item;

    item = loopback_seq_item::type_id::create("item");
    start_item(item);
    item.protocol      = protocol;
    item.read_en       = read_en;
    item.spi_mode      = spi_mode;
    item.reg_sel       = reg_sel;
    item.tx_data       = tx_data;
    item.compare_en    = 1'b1;
    item.inject_reset  = 1'b0;
    item.reset_delay_cycles = 0;
    item.exp_digits    = exp_digits;
    item.exp_rx_data   = exp_rx_data;
    item.exp_ack_error = exp_ack_error;
    finish_item(item);
  endtask

  task send_reset_abort_tx(loop_protocol_e protocol,
                           bit             read_en,
                           bit [1:0]       spi_mode,
                           bit [1:0]       reg_sel,
                           bit [7:0]       tx_data,
                           int unsigned    reset_delay_cycles);
    loopback_seq_item item;

    item = loopback_seq_item::type_id::create("item");
    start_item(item);
    item.protocol          = protocol;
    item.read_en           = read_en;
    item.spi_mode          = spi_mode;
    item.reg_sel           = reg_sel;
    item.tx_data           = tx_data;
    item.compare_en        = 1'b0;
    item.inject_reset      = 1'b1;
    item.reset_delay_cycles = reset_delay_cycles;
    item.exp_digits        = model_digits();
    item.exp_rx_data       = 8'h00;
    item.exp_ack_error     = 1'b0;
    finish_item(item);
  endtask

  task model_spi_write(bit [1:0] spi_mode, bit [1:0] reg_sel, bit [7:0] tx_data);
    bit [7:0] exp_rx_data;
    current_spi_mode   = spi_mode;
    exp_rx_data        = {4'h0, reg_model[reg_sel]};
    reg_model[reg_sel] = tx_data[3:0];
    send_tx(LOOP_SPI, 1'b0, spi_mode, reg_sel, tx_data, model_digits(), exp_rx_data);
  endtask

  task model_i2c_write(bit [1:0] reg_sel, bit [7:0] tx_data);
    reg_model[reg_sel] = tx_data[3:0];
    send_tx(LOOP_I2C, 1'b0, current_spi_mode, reg_sel, tx_data, model_digits(), 8'h00);
  endtask

  task model_i2c_read(bit [1:0] reg_sel);
    send_tx(LOOP_I2C, 1'b1, current_spi_mode, reg_sel, 8'h00, model_digits(),
            {4'h0, reg_model[reg_sel]});
  endtask
endclass

class loopback_smoke_sequence extends loopback_base_sequence;
  `uvm_object_utils(loopback_smoke_sequence)

  function new(string name = "loopback_smoke_sequence");
    super.new(name);
  endfunction

  virtual task body();
    reset_model();
    model_spi_write(2'b00, 2'b00, 8'h05);
    model_spi_write(2'b01, 2'b01, 8'h16);
    model_spi_write(2'b10, 2'b10, 8'h27);
    model_spi_write(2'b11, 2'b11, 8'h38);
    model_spi_write(2'b10, 2'b10, 8'h2A);
    model_spi_write(2'b00, 2'b00, 8'h0C);
    model_spi_write(2'b11, 2'b01, 8'h2D);

    model_i2c_write(2'b00, 8'h01);
    model_i2c_write(2'b01, 8'h02);
    model_i2c_write(2'b10, 8'h03);
    model_i2c_write(2'b11, 8'h04);

    model_i2c_read(2'b00);
    model_i2c_read(2'b01);
    model_i2c_read(2'b10);
    model_i2c_read(2'b11);
  endtask
endclass

class loopback_full_sequence extends loopback_base_sequence;
  `uvm_object_utils(loopback_full_sequence)

  bit do_model_reset;

  function new(string name = "loopback_full_sequence");
    super.new(name);
    do_model_reset = 1'b1;
  endfunction

  virtual task body();
    bit [3:0] data_nibble;
    bit [7:0] tx_data;
    bit [1:0] mode_sel;
    bit [1:0] reg_sel;

    if (do_model_reset) reset_model();

    for (int mode = 0; mode < 4; mode++) begin
      for (int reg_idx = 0; reg_idx < 4; reg_idx++) begin
        data_nibble = (mode * 4 + reg_idx + 1) & 4'hF;
        tx_data     = {4'h8, data_nibble};
        mode_sel    = mode;
        reg_sel     = reg_idx;
        model_spi_write(mode_sel, reg_sel, tx_data);
      end
    end

    for (int reg_idx = 0; reg_idx < 4; reg_idx++) begin
      data_nibble = 4'hD - reg_idx;
      tx_data     = {4'h6, data_nibble};
      mode_sel    = (3 - reg_idx) % 4;
      reg_sel     = reg_idx;
      model_spi_write(mode_sel, reg_sel, tx_data);
    end

    for (int reg_idx = 0; reg_idx < 4; reg_idx++) begin
      data_nibble = (reg_idx + 1) & 4'hF;
      tx_data     = {4'h3, data_nibble};
      reg_sel     = reg_idx;
      model_i2c_write(reg_sel, tx_data);
    end

    for (int reg_idx = 0; reg_idx < 4; reg_idx++) begin
      reg_sel = reg_idx;
      model_i2c_read(reg_sel);
    end
  endtask
endclass

class loopback_random_sequence extends loopback_base_sequence;
  `uvm_object_utils(loopback_random_sequence)

  int num_transactions;
  bit do_model_reset;

  function new(string name = "loopback_random_sequence");
    super.new(name);
    num_transactions = 32;
    do_model_reset = 1'b1;
  endfunction

  virtual task body();
    loop_protocol_e protocol;
    bit             read_en;
    bit [1:0]       spi_mode;
    bit [1:0]       reg_sel;
    bit [7:0]       tx_data;

    if (do_model_reset) reset_model();

    repeat (num_transactions) begin
      if (!std::randomize(protocol, read_en, spi_mode, reg_sel, tx_data) with {
            if (protocol == LOOP_SPI) read_en == 1'b0;
          }) begin
        `uvm_fatal(get_type_name(), "loopback_random_sequence randomization failed")
      end

      if (protocol == LOOP_SPI) begin
        model_spi_write(spi_mode, reg_sel, tx_data);
      end
      else if (read_en) begin
        model_i2c_read(reg_sel);
      end
      else begin
        model_i2c_write(reg_sel, tx_data);
      end
    end
  endtask
endclass

class loopback_negative_sequence extends loopback_base_sequence;
  `uvm_object_utils(loopback_negative_sequence)

  bit do_model_reset;

  function new(string name = "loopback_negative_sequence");
    super.new(name);
    do_model_reset = 1'b1;
  endfunction

  virtual task body();
    if (do_model_reset) reset_model();

    // Repeated overwrite and protocol switching on the same register.
    model_spi_write(2'b00, 2'b01, 8'h11);
    model_spi_write(2'b10, 2'b01, 8'h1E);
    model_i2c_write(2'b01, 8'h02);
    model_i2c_read(2'b01);

    // Abort SPI in-flight, then re-establish state.
    send_reset_abort_tx(LOOP_SPI, 1'b0, 2'b11, 2'b10, 8'h3A, 2);

    reset_model();
    model_spi_write(2'b01, 2'b11, 8'h0D);
    model_i2c_write(2'b11, 8'h04);
    model_i2c_read(2'b11);

    // Abort I2C in-flight after a protocol switch.
    send_reset_abort_tx(LOOP_I2C, 1'b0, current_spi_mode, 2'b00, 8'h05, 3);
  endtask
endclass

class loopback_reset_sequence extends loopback_base_sequence;
  `uvm_object_utils(loopback_reset_sequence)

  function new(string name = "loopback_reset_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Synchronize DUT state first so the recovery scenario starts cleanly
    // after full/random/negative sequences in the integrated run_test flow.
    send_reset_abort_tx(LOOP_SPI, 1'b0, 2'b00, 2'b00, 8'h00, 0);
    reset_model();
    model_spi_write(2'b00, 2'b00, 8'h05);
    send_reset_abort_tx(LOOP_I2C, 1'b0, current_spi_mode, 2'b11, 8'h04, 4);
    reset_model();
    model_i2c_write(2'b01, 8'h02);
    model_spi_write(2'b10, 2'b10, 8'h27);
    model_i2c_read(2'b01);
  endtask
endclass

class loopback_comprehensive_sequence extends loopback_base_sequence;
  `uvm_object_utils(loopback_comprehensive_sequence)

  int random_transactions;

  function new(string name = "loopback_comprehensive_sequence");
    super.new(name);
    random_transactions = 64;
  endfunction

  virtual task body();
    loopback_full_sequence     full_seq;
    loopback_random_sequence   random_seq;
    loopback_negative_sequence negative_seq;
    loopback_reset_sequence    reset_seq;

    full_seq = loopback_full_sequence::type_id::create("full_seq");
    random_seq = loopback_random_sequence::type_id::create("random_seq");
    negative_seq = loopback_negative_sequence::type_id::create("negative_seq");
    reset_seq = loopback_reset_sequence::type_id::create("reset_seq");

    full_seq.start(m_sequencer);

    foreach (full_seq.reg_model[idx]) random_seq.reg_model[idx] = full_seq.reg_model[idx];
    random_seq.current_spi_mode = full_seq.current_spi_mode;
    random_seq.do_model_reset = 1'b0;
    random_seq.num_transactions = random_transactions;
    random_seq.start(m_sequencer);

    foreach (random_seq.reg_model[idx]) negative_seq.reg_model[idx] = random_seq.reg_model[idx];
    negative_seq.current_spi_mode = random_seq.current_spi_mode;
    negative_seq.do_model_reset = 1'b0;
    negative_seq.start(m_sequencer);

    reset_seq.start(m_sequencer);
  endtask
endclass
