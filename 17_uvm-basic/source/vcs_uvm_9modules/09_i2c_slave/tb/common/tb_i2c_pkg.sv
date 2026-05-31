`ifndef TB_I2C_PKG_SV
`define TB_I2C_PKG_SV

`include "uvm_macros.svh"

package tb_i2c_pkg;
  import uvm_pkg::*;

  typedef virtual i2c_master_if i2c_master_vif_t;
  typedef virtual i2c_slave_if  i2c_slave_vif_t;

  `uvm_analysis_imp_decl(_mst_exp)
  `uvm_analysis_imp_decl(_mst_obs)
  `uvm_analysis_imp_decl(_slv_exp)
  `uvm_analysis_imp_decl(_slv_obs)

  typedef enum int {
    I2C_RESULT_OK,
    I2C_RESULT_ACK_ERROR,
    I2C_RESULT_RESET_ABORT,
    I2C_RESULT_PARTIAL_STOP
  } i2c_result_e;

  typedef enum int {
    I2C_TICK_REGULAR,
    I2C_TICK_IRREGULAR
  } i2c_tick_mode_e;

  typedef enum int {
    I2C_JITTER_NONE,
    I2C_JITTER_EARLY_LATE
  } i2c_jitter_mode_e;

  typedef enum int {
    I2C_RESET_NONE,
    I2C_RESET_START,
    I2C_RESET_ADDR,
    I2C_RESET_DATA,
    I2C_RESET_STOP
  } i2c_reset_phase_e;

  typedef enum int {
    I2C_MON_IDLE,
    I2C_MON_ADDR,
    I2C_MON_ADDR_ACK,
    I2C_MON_WRITE_DATA,
    I2C_MON_WRITE_ACK,
    I2C_MON_READ_DATA,
    I2C_MON_READ_ACK
  } i2c_mon_state_e;

  class i2c_master_seq_item extends uvm_sequence_item;
    `uvm_object_utils(i2c_master_seq_item)

    rand bit [6:0]       addr;
    rand bit             read;
    rand bit [7:0]       tx_data;
    rand bit [7:0]       read_data;
    bit                  addr_ack;
    bit                  data_ack;
    i2c_result_e         expected_result;
    i2c_tick_mode_e      tick_mode;
    i2c_jitter_mode_e    jitter_mode;
    i2c_reset_phase_e    reset_phase;
    int unsigned         item_id;
    bit                  is_window_done;

    function new(string name = "i2c_master_seq_item");
      super.new(name);
      addr = 7'h42;
      read = 1'b0;
      tx_data = 8'h00;
      read_data = 8'h00;
      addr_ack = 1'b1;
      data_ack = 1'b1;
      expected_result = I2C_RESULT_OK;
      tick_mode = I2C_TICK_REGULAR;
      jitter_mode = I2C_JITTER_NONE;
      reset_phase = I2C_RESET_NONE;
      item_id = 0;
      is_window_done = 1'b0;
    endfunction

    function void do_copy(uvm_object rhs);
      i2c_master_seq_item rhs_;

      if (!$cast(rhs_, rhs)) begin
        `uvm_fatal("I2C_MST_ITEM", "do_copy cast failed")
      end

      super.do_copy(rhs);
      addr = rhs_.addr;
      read = rhs_.read;
      tx_data = rhs_.tx_data;
      read_data = rhs_.read_data;
      addr_ack = rhs_.addr_ack;
      data_ack = rhs_.data_ack;
      expected_result = rhs_.expected_result;
      tick_mode = rhs_.tick_mode;
      jitter_mode = rhs_.jitter_mode;
      reset_phase = rhs_.reset_phase;
      item_id = rhs_.item_id;
      is_window_done = rhs_.is_window_done;
    endfunction
  endclass

  class i2c_master_obs_item extends uvm_sequence_item;
    `uvm_object_utils(i2c_master_obs_item)

    bit [6:0] addr;
    bit       read;
    bit [7:0] data;
    bit [7:0] rx_data;
    bit       ack_error;
    bit       saw_done;
    bit       addr_valid;
    bit       data_valid;
    bit       addr_ack;
    bit       data_ack;

    function new(string name = "i2c_master_obs_item");
      super.new(name);
    endfunction
  endclass

  class i2c_slave_seq_item extends uvm_sequence_item;
    `uvm_object_utils(i2c_slave_seq_item)

    rand bit [6:0]       own_addr;
    rand bit [6:0]       bus_addr;
    rand bit             read;
    rand bit [7:0]       write_data;
    rand bit [7:0]       tx_data;
    bit                  master_ack;
    i2c_result_e         expected_result;
    i2c_tick_mode_e      tick_mode;
    i2c_jitter_mode_e    jitter_mode;
    i2c_reset_phase_e    reset_phase;
    int unsigned         item_id;
    bit                  is_window_done;

    function new(string name = "i2c_slave_seq_item");
      super.new(name);
      own_addr = 7'h42;
      bus_addr = 7'h42;
      read = 1'b0;
      write_data = 8'h00;
      tx_data = 8'h00;
      master_ack = 1'b0;
      expected_result = I2C_RESULT_OK;
      tick_mode = I2C_TICK_REGULAR;
      jitter_mode = I2C_JITTER_NONE;
      reset_phase = I2C_RESET_NONE;
      item_id = 0;
      is_window_done = 1'b0;
    endfunction

    function void do_copy(uvm_object rhs);
      i2c_slave_seq_item rhs_;

      if (!$cast(rhs_, rhs)) begin
        `uvm_fatal("I2C_SLV_ITEM", "do_copy cast failed")
      end

      super.do_copy(rhs);
      own_addr = rhs_.own_addr;
      bus_addr = rhs_.bus_addr;
      read = rhs_.read;
      write_data = rhs_.write_data;
      tx_data = rhs_.tx_data;
      master_ack = rhs_.master_ack;
      expected_result = rhs_.expected_result;
      tick_mode = rhs_.tick_mode;
      jitter_mode = rhs_.jitter_mode;
      reset_phase = rhs_.reset_phase;
      item_id = rhs_.item_id;
      is_window_done = rhs_.is_window_done;
    endfunction
  endclass

  class i2c_slave_obs_item extends uvm_sequence_item;
    `uvm_object_utils(i2c_slave_obs_item)

    bit [7:0] rx_data;
    bit [7:0] write_data;
    bit [7:0] read_data;
    bit       txn_read;
    bit       saw_rx_valid;
    bit       saw_txn_done;
    bit       addr_valid;
    bit       data_valid;
    bit       read_data_valid;
    bit [6:0] bus_addr;

    function new(string name = "i2c_slave_obs_item");
      super.new(name);
    endfunction
  endclass

  class i2c_master_sequence extends uvm_sequence #(i2c_master_seq_item);
    `uvm_object_utils(i2c_master_sequence)

    string seq_name;

    function new(string name = "i2c_master_sequence");
      super.new(name);
      seq_name = "all";
    endfunction

    task automatic send(bit [6:0] addr,
                        bit read,
                        bit [7:0] tx_data,
                        bit [7:0] read_data,
                        bit addr_ack = 1'b1,
                        bit data_ack = 1'b1,
                        i2c_result_e result = I2C_RESULT_OK,
                        i2c_reset_phase_e reset_phase = I2C_RESET_NONE,
                        i2c_tick_mode_e tick_mode = I2C_TICK_REGULAR,
                        i2c_jitter_mode_e jitter_mode = I2C_JITTER_NONE);
      i2c_master_seq_item item;

      item = i2c_master_seq_item::type_id::create("item");
      start_item(item);
      item.addr = addr;
      item.read = read;
      item.tx_data = tx_data;
      item.read_data = read_data;
      item.addr_ack = addr_ack;
      item.data_ack = data_ack;
      item.expected_result = result;
      item.reset_phase = reset_phase;
      item.tick_mode = tick_mode;
      item.jitter_mode = jitter_mode;
      finish_item(item);
    endtask

    task body();
      if ((seq_name == "smoke") || (seq_name == "all")) begin
        send(7'h42, 1'b0, 8'ha5, 8'h00);
      end

      if ((seq_name == "directed") || (seq_name == "all")) begin
        send(7'h42, 1'b0, 8'h00, 8'h00);
        send(7'h42, 1'b0, 8'hff, 8'h00);
        send(7'h42, 1'b1, 8'h00, 8'h5a);
        send(7'h42, 1'b1, 8'h00, 8'ha5);
      end

      if ((seq_name == "error") || (seq_name == "all")) begin
        send(7'h42, 1'b0, 8'h55, 8'h00, 1'b0, 1'b1, I2C_RESULT_ACK_ERROR);
        send(7'h42, 1'b0, 8'haa, 8'h00, 1'b1, 1'b0, I2C_RESULT_ACK_ERROR);
      end

      if ((seq_name == "reset") || (seq_name == "all")) begin
        send(7'h42, 1'b0, 8'hc3, 8'h00, 1'b1, 1'b1,
             I2C_RESULT_RESET_ABORT, I2C_RESET_DATA);
      end

      if ((seq_name == "jitter") || (seq_name == "all")) begin
        send(7'h42, 1'b1, 8'h00, 8'h3c, 1'b1, 1'b1,
             I2C_RESULT_OK, I2C_RESET_NONE, I2C_TICK_IRREGULAR, I2C_JITTER_EARLY_LATE);
      end

      if ((seq_name == "corner") || (seq_name == "all")) begin
        send(7'h42, 1'b0, 8'h00, 8'h00);
        send(7'h42, 1'b0, 8'hff, 8'h00);
        send(7'h42, 1'b1, 8'h00, 8'h00);
        send(7'h42, 1'b1, 8'h00, 8'hff);
        send(7'h42, 1'b1, 8'h00, 8'haa);
        send(7'h42, 1'b0, 8'h7e, 8'h00, 1'b0, 1'b1, I2C_RESULT_ACK_ERROR);
        send(7'h42, 1'b0, 8'h81, 8'h00, 1'b1, 1'b0, I2C_RESULT_ACK_ERROR);
        send(7'h42, 1'b0, 8'h5a, 8'h00, 1'b1, 1'b1,
             I2C_RESULT_RESET_ABORT, I2C_RESET_DATA);
      end

      if ((seq_name == "byte_sweep") || (seq_name == "all")) begin
        bit [7:0] data;

        for (int unsigned i = 0; i < 256; i++) begin
          data = i[7:0];
          send(7'h42, 1'b0, data, 8'h00);
        end

        for (int unsigned i = 0; i < 256; i++) begin
          data = i[7:0];
          send(7'h42, 1'b1, 8'h00, data);
        end
      end

      if (seq_name == "full_random") begin
        int unsigned count;

        if (!$value$plusargs("I2C_MASTER_RANDOM_COUNT=%d", count)) begin
          count = 512;
        end

        for (int unsigned i = 0; i < count; i++) begin
          bit read;
          bit [7:0] tx_data;
          bit [7:0] read_data;
          i2c_tick_mode_e tick_mode;
          i2c_jitter_mode_e jitter_mode;

          read = $urandom_range(0, 1);
          tx_data = $urandom_range(0, 255);
          read_data = $urandom_range(0, 255);
          tick_mode = i2c_tick_mode_e'($urandom_range(0, 1));
          jitter_mode = i2c_jitter_mode_e'($urandom_range(0, 1));

          send(7'h42, read, tx_data, read_data, 1'b1, 1'b1,
               I2C_RESULT_OK, I2C_RESET_NONE, tick_mode, jitter_mode);
        end
      end
    endtask
  endclass

  class i2c_slave_sequence extends uvm_sequence #(i2c_slave_seq_item);
    `uvm_object_utils(i2c_slave_sequence)

    string seq_name;

    function new(string name = "i2c_slave_sequence");
      super.new(name);
      seq_name = "all";
    endfunction

    task automatic send(bit [6:0] own_addr,
                        bit [6:0] bus_addr,
                        bit read,
                        bit [7:0] write_data,
                        bit [7:0] tx_data,
                        i2c_result_e result = I2C_RESULT_OK,
                        i2c_reset_phase_e reset_phase = I2C_RESET_NONE,
                        i2c_tick_mode_e tick_mode = I2C_TICK_REGULAR,
                        i2c_jitter_mode_e jitter_mode = I2C_JITTER_NONE);
      i2c_slave_seq_item item;

      item = i2c_slave_seq_item::type_id::create("item");
      start_item(item);
      item.own_addr = own_addr;
      item.bus_addr = bus_addr;
      item.read = read;
      item.write_data = write_data;
      item.tx_data = tx_data;
      item.expected_result = result;
      item.reset_phase = reset_phase;
      item.tick_mode = tick_mode;
      item.jitter_mode = jitter_mode;
      finish_item(item);
    endtask

    task body();
      if ((seq_name == "smoke") || (seq_name == "all")) begin
        send(7'h42, 7'h42, 1'b0, 8'ha5, 8'h00);
      end

      if ((seq_name == "directed") || (seq_name == "all")) begin
        send(7'h42, 7'h42, 1'b0, 8'h00, 8'h00);
        send(7'h42, 7'h42, 1'b0, 8'hff, 8'h00);
        send(7'h42, 7'h42, 1'b1, 8'h00, 8'h5a);
        send(7'h42, 7'h42, 1'b1, 8'h00, 8'ha5);
        send(7'h42, 7'h42, 1'b1, 8'h00, 8'haa);
      end

      if ((seq_name == "error") || (seq_name == "all")) begin
        send(7'h42, 7'h24, 1'b0, 8'h55, 8'h00, I2C_RESULT_ACK_ERROR);
      end

      if ((seq_name == "reset") || (seq_name == "all")) begin
        send(7'h42, 7'h42, 1'b0, 8'hc3, 8'h00,
             I2C_RESULT_RESET_ABORT, I2C_RESET_DATA);
      end

      if ((seq_name == "jitter") || (seq_name == "all")) begin
        send(7'h42, 7'h42, 1'b1, 8'h00, 8'h3c,
             I2C_RESULT_OK, I2C_RESET_NONE, I2C_TICK_IRREGULAR, I2C_JITTER_EARLY_LATE);
      end

      if ((seq_name == "corner") || (seq_name == "all")) begin
        send(7'h42, 7'h42, 1'b0, 8'h00, 8'h00);
        send(7'h42, 7'h42, 1'b0, 8'hff, 8'h00);
        send(7'h42, 7'h42, 1'b1, 8'h00, 8'h00);
        send(7'h42, 7'h42, 1'b1, 8'h00, 8'hff);
        send(7'h42, 7'h42, 1'b1, 8'h00, 8'haa);
        send(7'h42, 7'h24, 1'b0, 8'h7e, 8'h00, I2C_RESULT_ACK_ERROR);
        send(7'h42, 7'h42, 1'b0, 8'h81, 8'h00,
             I2C_RESULT_RESET_ABORT, I2C_RESET_DATA);
      end

      if ((seq_name == "byte_sweep") || (seq_name == "all")) begin
        bit [7:0] data;

        for (int unsigned i = 0; i < 256; i++) begin
          data = i[7:0];
          send(7'h42, 7'h42, 1'b0, data, 8'h00);
        end

        for (int unsigned i = 0; i < 256; i++) begin
          data = i[7:0];
          send(7'h42, 7'h42, 1'b1, 8'h00, data);
        end
      end

      if (seq_name == "full_random") begin
        int unsigned count;

        if (!$value$plusargs("I2C_SLAVE_RANDOM_COUNT=%d", count)) begin
          count = 512;
        end

        for (int unsigned i = 0; i < count; i++) begin
          bit read;
          bit addr_hit;
          bit [7:0] write_data;
          bit [7:0] tx_data;
          i2c_tick_mode_e tick_mode;
          i2c_jitter_mode_e jitter_mode;

          read = $urandom_range(0, 1);
          addr_hit = 1'b1;
          write_data = $urandom_range(0, 255);
          tx_data = $urandom_range(0, 255);
          tick_mode = i2c_tick_mode_e'($urandom_range(0, 1));
          jitter_mode = i2c_jitter_mode_e'($urandom_range(0, 1));

          send(7'h42, addr_hit ? 7'h42 : 7'h24, read, write_data, tx_data,
               I2C_RESULT_OK, I2C_RESET_NONE, tick_mode, jitter_mode);
        end
      end
    endtask
  endclass

  class i2c_master_sequencer extends uvm_sequencer #(i2c_master_seq_item);
    `uvm_component_utils(i2c_master_sequencer)

    function new(string name = "i2c_master_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class i2c_slave_sequencer extends uvm_sequencer #(i2c_slave_seq_item);
    `uvm_component_utils(i2c_slave_sequencer)

    function new(string name = "i2c_slave_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

`ifndef I2C_TB_SLAVE_ONLY
  class i2c_master_driver extends uvm_driver #(i2c_master_seq_item);
    `uvm_component_utils(i2c_master_driver)

    i2c_master_vif_t i2c_vif;
    uvm_analysis_port #(i2c_master_seq_item) expected_ap;
    int unsigned mNextItemId;

    function new(string name = "i2c_master_driver", uvm_component parent);
      super.new(name, parent);
      expected_ap = new("expected_ap", this);
      mNextItemId = 1;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(i2c_master_vif_t)::get(this, "", "i2c_master_vif", i2c_vif)) begin
        `uvm_fatal("I2C_MST_DRV", "Driver failed to get virtual interface")
      end
    endfunction

    function i2c_master_seq_item clone_item(i2c_master_seq_item item);
      i2c_master_seq_item cloned;

      cloned = i2c_master_seq_item::type_id::create("i2c_master_expected_clone");
      cloned.copy(item);
      return cloned;
    endfunction

    function int tick_gap(i2c_master_seq_item item, int index);
      tick_gap = (item.tick_mode == I2C_TICK_REGULAR) ? 1 : ((index % 3) + 1);

      if (item.jitter_mode == I2C_JITTER_EARLY_LATE) begin
        tick_gap += index[0];
      end
    endfunction

    task automatic wait_clks(int cycles);
      repeat (cycles) begin
        @(i2c_vif.drv_cb);
        i2c_vif.drv_cb.iTick <= 1'b0;
      end
    endtask

    task automatic pulse_tick(i2c_master_seq_item item, int index);
      wait_clks(tick_gap(item, index));
      @(i2c_vif.drv_cb);
      i2c_vif.drv_cb.iTick <= 1'b1;
      @(i2c_vif.drv_cb);
      i2c_vif.drv_cb.iTick <= 1'b0;
    endtask

    task automatic drive_idle();
      i2c_vif.iRst <= 1'b0;
      i2c_vif.iTick <= 1'b0;
      i2c_vif.iStart <= 1'b0;
      i2c_vif.iRead <= 1'b0;
      i2c_vif.iSlaveAddr <= '0;
      i2c_vif.iTxData <= '0;
      i2c_vif.slave_sda_oe <= 1'b0;
    endtask

    task automatic drive_initial_reset();
      i2c_vif.iRst <= 1'b1;
      wait_clks(5);
      i2c_vif.drv_cb.iRst <= 1'b0;
      wait_clks(5);
    endtask

    task automatic drive_reset_pulse();
      i2c_vif.drv_cb.iRst <= 1'b1;
      i2c_vif.drv_cb.iStart <= 1'b0;
      i2c_vif.slave_sda_oe <= 1'b0;
      wait_clks(4);
      i2c_vif.drv_cb.iRst <= 1'b0;
      wait_clks(5);
    endtask

    task automatic publish_expected(i2c_master_seq_item item);
      item.item_id = mNextItemId;
      mNextItemId++;
      expected_ap.write(clone_item(item));
    endtask

    task automatic publish_window_done(i2c_master_seq_item item);
      i2c_master_seq_item done_item;

      done_item = clone_item(item);
      done_item.is_window_done = 1'b1;
      expected_ap.write(done_item);
    endtask

    task automatic slave_responder(i2c_master_seq_item item);
      typedef enum int {WAIT_START, ADDR_BITS, ADDR_ACK, WRITE_BITS, WRITE_ACK, READ_BITS, DONE_ST} rsp_state_e;
      rsp_state_e state;
      bit prev_scl;
      bit prev_sda;
      bit cur_scl;
      bit cur_sda;
      int bit_cnt;
      int ack_fall_count;

      state = WAIT_START;
      prev_scl = i2c_vif.scl_line;
      prev_sda = i2c_vif.sda_line;
      bit_cnt = 0;
      ack_fall_count = 0;
      i2c_vif.slave_sda_oe <= 1'b0;

      forever begin
        @(i2c_vif.scl_line or i2c_vif.sda_line or i2c_vif.iRst or i2c_vif.oDone);

        if (i2c_vif.iRst) begin
          i2c_vif.slave_sda_oe <= 1'b0;
          state = WAIT_START;
          bit_cnt = 0;
          ack_fall_count = 0;
          prev_scl = i2c_vif.scl_line;
          prev_sda = i2c_vif.sda_line;
          continue;
        end

        if (i2c_vif.oDone) begin
          i2c_vif.slave_sda_oe <= 1'b0;
          return;
        end

        cur_scl = i2c_vif.scl_line;
        cur_sda = i2c_vif.sda_line;

        if (prev_sda && !cur_sda && cur_scl) begin
          state = ADDR_BITS;
          bit_cnt = 0;
        end

        if (!prev_scl && cur_scl) begin
          case (state)
            ADDR_BITS: begin
              bit_cnt++;

              if (bit_cnt == 8) begin
                state = ADDR_ACK;
                ack_fall_count = 0;
              end
            end

            WRITE_BITS: begin
              bit_cnt++;

              if (bit_cnt == 8) begin
                state = WRITE_ACK;
                ack_fall_count = 0;
              end
            end

            READ_BITS: begin
              bit_cnt++;
            end

            default: begin
            end
          endcase
        end

        if (prev_scl && !cur_scl) begin
          case (state)
            ADDR_ACK: begin
              i2c_vif.slave_sda_oe <= item.addr_ack;
              ack_fall_count++;

              if (ack_fall_count >= 2) begin
                bit_cnt = 0;
                state = item.read ? READ_BITS : WRITE_BITS;
                i2c_vif.slave_sda_oe <= item.read ? !item.read_data[7] : 1'b0;
              end
            end

            WRITE_ACK: begin
              i2c_vif.slave_sda_oe <= item.data_ack;
              ack_fall_count++;

              if (ack_fall_count >= 2) begin
                i2c_vif.slave_sda_oe <= 1'b0;
                state = DONE_ST;
              end
            end

            READ_BITS: begin
              if (bit_cnt >= 8) begin
                i2c_vif.slave_sda_oe <= 1'b0;
                state = DONE_ST;
              end
              else begin
                i2c_vif.slave_sda_oe <= !item.read_data[7 - bit_cnt];
              end
            end

            default: begin
              if (state != READ_BITS) begin
                i2c_vif.slave_sda_oe <= 1'b0;
              end
            end
          endcase
        end

        prev_scl = cur_scl;
        prev_sda = cur_sda;
      end
    endtask

    task automatic tick_until_done(i2c_master_seq_item item);
      for (int i = 0; i < 180; i++) begin
        if ((item.expected_result == I2C_RESULT_RESET_ABORT) && (i == 32)) begin
          drive_reset_pulse();
          publish_window_done(item);
          return;
        end

        pulse_tick(item, i);

        if (i2c_vif.drv_cb.oDone) begin
          wait_clks(6);
          return;
        end
      end

      `uvm_error("I2C_MST_DRV", "Timed out waiting for i2c_master oDone")
    endtask

    task automatic drive_item(i2c_master_seq_item item);
      publish_expected(item);
      wait_clks(4);

      i2c_vif.drv_cb.iSlaveAddr <= item.addr;
      i2c_vif.drv_cb.iRead <= item.read;
      i2c_vif.drv_cb.iTxData <= item.tx_data;
      i2c_vif.drv_cb.iStart <= 1'b1;
      @(i2c_vif.drv_cb);
      i2c_vif.drv_cb.iStart <= 1'b0;

      fork
        slave_responder(item);
        tick_until_done(item);
      join_any
      disable fork;
      i2c_vif.slave_sda_oe <= 1'b0;
    endtask

    task run_phase(uvm_phase phase);
      i2c_master_seq_item item;

      drive_idle();
      drive_initial_reset();

      forever begin
        seq_item_port.get_next_item(item);
        drive_item(item);
        seq_item_port.item_done();
      end
    endtask
  endclass
`endif

`ifndef I2C_TB_MASTER_ONLY
  class i2c_slave_driver extends uvm_driver #(i2c_slave_seq_item);
    `uvm_component_utils(i2c_slave_driver)

    i2c_slave_vif_t i2c_vif;
    uvm_analysis_port #(i2c_slave_seq_item) expected_ap;
    int unsigned mNextItemId;

    function new(string name = "i2c_slave_driver", uvm_component parent);
      super.new(name, parent);
      expected_ap = new("expected_ap", this);
      mNextItemId = 1;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(i2c_slave_vif_t)::get(this, "", "i2c_slave_vif", i2c_vif)) begin
        `uvm_fatal("I2C_SLV_DRV", "Driver failed to get virtual interface")
      end
    endfunction

    function i2c_slave_seq_item clone_item(i2c_slave_seq_item item);
      i2c_slave_seq_item cloned;

      cloned = i2c_slave_seq_item::type_id::create("i2c_slave_expected_clone");
      cloned.copy(item);
      return cloned;
    endfunction

    task automatic wait_clks(int cycles);
      repeat (cycles) begin
        @(i2c_vif.drv_cb);
      end
    endtask

    task automatic set_scl(bit high);
      i2c_vif.drv_cb.master_scl_oe <= !high;
      wait_clks(4);
    endtask

    task automatic set_sda(bit high);
      i2c_vif.drv_cb.master_sda_oe <= !high;
      wait_clks(2);
    endtask

    task automatic drive_idle();
      i2c_vif.iRst <= 1'b0;
      i2c_vif.iOwnAddr <= 7'h42;
      i2c_vif.iTxData <= '0;
      i2c_vif.master_scl_oe <= 1'b0;
      i2c_vif.master_sda_oe <= 1'b0;
    endtask

    task automatic drive_initial_reset();
      i2c_vif.iRst <= 1'b1;
      wait_clks(5);
      i2c_vif.drv_cb.iRst <= 1'b0;
      wait_clks(5);
    endtask

    task automatic drive_reset_pulse();
      i2c_vif.drv_cb.iRst <= 1'b1;
      i2c_vif.drv_cb.master_scl_oe <= 1'b0;
      i2c_vif.drv_cb.master_sda_oe <= 1'b0;
      wait_clks(4);
      i2c_vif.drv_cb.iRst <= 1'b0;
      wait_clks(5);
    endtask

    task automatic publish_expected(i2c_slave_seq_item item);
      item.item_id = mNextItemId;
      mNextItemId++;
      expected_ap.write(clone_item(item));
    endtask

    task automatic publish_window_done(i2c_slave_seq_item item);
      i2c_slave_seq_item done_item;

      done_item = clone_item(item);
      done_item.is_window_done = 1'b1;
      expected_ap.write(done_item);
    endtask

    task automatic drive_start();
      set_sda(1'b1);
      set_scl(1'b1);
      set_sda(1'b0);
      set_scl(1'b0);
    endtask

    task automatic drive_stop();
      set_sda(1'b0);
      set_scl(1'b1);
      set_sda(1'b1);
    endtask

    task automatic drive_bit(bit value);
      set_sda(value);
      set_scl(1'b1);
      set_scl(1'b0);
    endtask

    task automatic drive_byte(bit [7:0] data);
      for (int i = 7; i >= 0; i--) begin
        drive_bit(data[i]);
      end
    endtask

    task automatic clock_ack();
      set_sda(1'b1);
      set_scl(1'b1);
      set_scl(1'b0);
    endtask

    task automatic read_byte(output bit [7:0] data);
      data = '0;

      for (int i = 7; i >= 0; i--) begin
        set_sda(1'b1);
        set_scl(1'b1);
        data[i] = i2c_vif.drv_cb.sda_line;
        set_scl(1'b0);
      end
    endtask

    task automatic drive_item(i2c_slave_seq_item item);
      bit [7:0] addr_frame;
      bit [7:0] readback;

      publish_expected(item);
      i2c_vif.drv_cb.iOwnAddr <= item.own_addr;
      i2c_vif.drv_cb.iTxData <= item.tx_data;
      wait_clks(4);

      addr_frame = {item.bus_addr, item.read};
      drive_start();
      drive_byte(addr_frame);
      clock_ack();

      if ((item.expected_result == I2C_RESULT_RESET_ABORT) &&
          (item.reset_phase == I2C_RESET_ADDR)) begin
        drive_reset_pulse();
        publish_window_done(item);
        return;
      end

      if (item.bus_addr != item.own_addr) begin
        drive_stop();
        wait_clks(8);
        publish_window_done(item);
        return;
      end

      if (item.read) begin
        read_byte(readback);
        drive_bit(1'b1);
      end
      else begin
        if ((item.expected_result == I2C_RESULT_RESET_ABORT) &&
            (item.reset_phase == I2C_RESET_DATA)) begin
          drive_byte({item.write_data[7:4], 4'h0});
          drive_reset_pulse();
          publish_window_done(item);
          return;
        end

        drive_byte(item.write_data);
        clock_ack();
      end

      drive_stop();
      wait_clks(8);
    endtask

    task run_phase(uvm_phase phase);
      i2c_slave_seq_item item;

      drive_idle();
      drive_initial_reset();

      forever begin
        seq_item_port.get_next_item(item);
        drive_item(item);
        seq_item_port.item_done();
      end
    endtask
  endclass
`endif

`ifndef I2C_TB_SLAVE_ONLY
  class i2c_master_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_master_monitor)

    i2c_master_vif_t i2c_vif;
    uvm_analysis_port #(i2c_master_obs_item) observed_ap;
    i2c_mon_state_e mState;
    bit             mPrevScl;
    bit             mPrevSda;
    bit [7:0]       mShift;
    bit [7:0]       mByteFrame;
    int             mBitCnt;
    bit [6:0]       mAddr;
    bit             mRead;
    bit [7:0]       mData;
    bit             mAddrValid;
    bit             mDataValid;
    bit             mAddrAck;
    bit             mDataAck;

    function new(string name = "i2c_master_monitor", uvm_component parent);
      super.new(name, parent);
      observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(i2c_master_vif_t)::get(this, "", "i2c_master_vif", i2c_vif)) begin
        `uvm_fatal("I2C_MST_MON", "Monitor failed to get virtual interface")
      end
    endfunction

    function void reset_decode();
      mState = I2C_MON_IDLE;
      mPrevScl = 1'b1;
      mPrevSda = 1'b1;
      mShift = '0;
      mByteFrame = '0;
      mBitCnt = 0;
      mAddr = '0;
      mRead = 1'b0;
      mData = '0;
      mAddrValid = 1'b0;
      mDataValid = 1'b0;
      mAddrAck = 1'b0;
      mDataAck = 1'b0;
    endfunction

    function void sample_scl_rise(bit sda_value);
      case (mState)
        I2C_MON_ADDR: begin
          mByteFrame = {mShift[6:0], sda_value};
          mShift = mByteFrame;

          if (mBitCnt == 7) begin
            mAddr = mByteFrame[7:1];
            mRead = mByteFrame[0];
            mAddrValid = 1'b1;
            mBitCnt = 0;
            mShift = '0;
            mState = I2C_MON_ADDR_ACK;
          end
          else begin
            mBitCnt++;
          end
        end

        I2C_MON_ADDR_ACK: begin
          mAddrAck = !sda_value;
          mBitCnt = 0;
          mShift = '0;
          mState = mRead ? I2C_MON_READ_DATA : I2C_MON_WRITE_DATA;
        end

        I2C_MON_WRITE_DATA: begin
          mByteFrame = {mShift[6:0], sda_value};
          mShift = mByteFrame;

          if (mBitCnt == 7) begin
            mData = mByteFrame;
            mDataValid = 1'b1;
            mBitCnt = 0;
            mShift = '0;
            mState = I2C_MON_WRITE_ACK;
          end
          else begin
            mBitCnt++;
          end
        end

        I2C_MON_WRITE_ACK: begin
          mDataAck = !sda_value;
          mState = I2C_MON_IDLE;
        end

        I2C_MON_READ_DATA: begin
          mByteFrame = {mShift[6:0], sda_value};
          mShift = mByteFrame;

          if (mBitCnt == 7) begin
            mData = mByteFrame;
            mDataValid = 1'b1;
            mBitCnt = 0;
            mShift = '0;
            mState = I2C_MON_READ_ACK;
          end
          else begin
            mBitCnt++;
          end
        end

        I2C_MON_READ_ACK: begin
          mDataAck = !sda_value;
          mState = I2C_MON_IDLE;
        end

        default: begin
        end
      endcase
    endfunction

    task run_phase(uvm_phase phase);
      reset_decode();

      forever begin
        @(i2c_vif.mon_cb);

        if (i2c_vif.mon_cb.iRst) begin
          reset_decode();
        end
        else begin
          bit start_det;
          bit stop_det;
          bit scl_rise;

          start_det = mPrevSda && !i2c_vif.mon_cb.sda_line && i2c_vif.mon_cb.scl_line;
          stop_det = !mPrevSda && i2c_vif.mon_cb.sda_line && i2c_vif.mon_cb.scl_line;
          scl_rise = !mPrevScl && i2c_vif.mon_cb.scl_line;

          if (start_det) begin
            mState = I2C_MON_ADDR;
            mShift = '0;
            mBitCnt = 0;
            mAddrValid = 1'b0;
            mDataValid = 1'b0;
            mAddrAck = 1'b0;
            mDataAck = 1'b0;
          end
          else if (stop_det) begin
            mState = I2C_MON_IDLE;
          end

          if (scl_rise) begin
            sample_scl_rise(i2c_vif.mon_cb.sda_line);
          end

          if (i2c_vif.mon_cb.oDone) begin
            i2c_master_obs_item item;

            item = i2c_master_obs_item::type_id::create("i2c_master_obs");
            item.addr = mAddr;
            item.read = mRead;
            item.data = mData;
            item.rx_data = i2c_vif.mon_cb.oRxData;
            item.ack_error = i2c_vif.mon_cb.oAckError;
            item.saw_done = 1'b1;
            item.addr_valid = mAddrValid;
            item.data_valid = mDataValid;
            item.addr_ack = mAddrAck;
            item.data_ack = mDataAck;
            observed_ap.write(item);
          end

          mPrevScl = i2c_vif.mon_cb.scl_line;
          mPrevSda = i2c_vif.mon_cb.sda_line;
        end
      end
    endtask
  endclass
`endif

`ifndef I2C_TB_MASTER_ONLY
  class i2c_slave_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_slave_monitor)

    i2c_slave_vif_t i2c_vif;
    uvm_analysis_port #(i2c_slave_obs_item) observed_ap;
    i2c_mon_state_e mState;
    bit             mPrevScl;
    bit             mPrevSda;
    bit [7:0]       mShift;
    bit [7:0]       mByteFrame;
    int             mBitCnt;
    bit [6:0]       mAddr;
    bit             mRead;
    bit [7:0]       mWriteData;
    bit [7:0]       mReadData;
    bit             mAddrValid;
    bit             mDataValid;
    bit             mReadDataValid;

    function new(string name = "i2c_slave_monitor", uvm_component parent);
      super.new(name, parent);
      observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(i2c_slave_vif_t)::get(this, "", "i2c_slave_vif", i2c_vif)) begin
        `uvm_fatal("I2C_SLV_MON", "Monitor failed to get virtual interface")
      end
    endfunction

    function void reset_decode();
      mState = I2C_MON_IDLE;
      mPrevScl = 1'b1;
      mPrevSda = 1'b1;
      mShift = '0;
      mByteFrame = '0;
      mBitCnt = 0;
      mAddr = '0;
      mRead = 1'b0;
      mWriteData = '0;
      mReadData = '0;
      mAddrValid = 1'b0;
      mDataValid = 1'b0;
      mReadDataValid = 1'b0;
    endfunction

    function void sample_scl_rise(bit sda_value);
      case (mState)
        I2C_MON_ADDR: begin
          mByteFrame = {mShift[6:0], sda_value};
          mShift = mByteFrame;

          if (mBitCnt == 7) begin
            mAddr = mByteFrame[7:1];
            mRead = mByteFrame[0];
            mAddrValid = 1'b1;
            mBitCnt = 0;
            mShift = '0;
            mState = I2C_MON_ADDR_ACK;
          end
          else begin
            mBitCnt++;
          end
        end

        I2C_MON_ADDR_ACK: begin
          mBitCnt = 0;
          mShift = '0;
          mState = mRead ? I2C_MON_READ_DATA : I2C_MON_WRITE_DATA;
        end

        I2C_MON_WRITE_DATA: begin
          mByteFrame = {mShift[6:0], sda_value};
          mShift = mByteFrame;

          if (mBitCnt == 7) begin
            mWriteData = mByteFrame;
            mDataValid = 1'b1;
            mBitCnt = 0;
            mShift = '0;
            mState = I2C_MON_WRITE_ACK;
          end
          else begin
            mBitCnt++;
          end
        end

        I2C_MON_WRITE_ACK: begin
          mState = I2C_MON_IDLE;
        end

        I2C_MON_READ_DATA: begin
          mByteFrame = {mShift[6:0], sda_value};
          mShift = mByteFrame;

          if (mBitCnt == 7) begin
            mReadData = mByteFrame;
            mReadDataValid = 1'b1;
            mBitCnt = 0;
            mShift = '0;
            mState = I2C_MON_READ_ACK;
          end
          else begin
            mBitCnt++;
          end
        end

        I2C_MON_READ_ACK: begin
          mState = I2C_MON_IDLE;
        end

        default: begin
        end
      endcase
    endfunction

    task run_phase(uvm_phase phase);
      reset_decode();

      forever begin
        @(i2c_vif.mon_cb);

        if (i2c_vif.mon_cb.iRst) begin
          reset_decode();
        end
        else begin
          bit start_det;
          bit stop_det;
          bit scl_rise;

          start_det = mPrevSda && !i2c_vif.mon_cb.sda_line && i2c_vif.mon_cb.scl_line;
          stop_det = !mPrevSda && i2c_vif.mon_cb.sda_line && i2c_vif.mon_cb.scl_line;
          scl_rise = !mPrevScl && i2c_vif.mon_cb.scl_line;

          if (start_det) begin
            mState = I2C_MON_ADDR;
            mShift = '0;
            mBitCnt = 0;
            mAddrValid = 1'b0;
            mDataValid = 1'b0;
            mReadDataValid = 1'b0;
          end
          else if (stop_det) begin
            mState = I2C_MON_IDLE;
          end

          if (scl_rise) begin
            sample_scl_rise(i2c_vif.mon_cb.sda_line);
          end

          if (i2c_vif.mon_cb.oTxnDone) begin
            i2c_slave_obs_item item;

            item = i2c_slave_obs_item::type_id::create("i2c_slave_obs");
            item.rx_data = i2c_vif.mon_cb.oRxData;
            item.write_data = mWriteData;
            item.read_data = mReadData;
            item.txn_read = i2c_vif.mon_cb.oTxnRead;
            item.saw_rx_valid = i2c_vif.mon_cb.oRxValid;
            item.saw_txn_done = i2c_vif.mon_cb.oTxnDone;
            item.addr_valid = mAddrValid;
            item.data_valid = mDataValid;
            item.read_data_valid = mReadDataValid;
            item.bus_addr = mAddr;
            observed_ap.write(item);
          end

          mPrevScl = i2c_vif.mon_cb.scl_line;
          mPrevSda = i2c_vif.mon_cb.sda_line;
        end
      end
    endtask
  endclass
`endif

`ifndef I2C_TB_SLAVE_ONLY
  class i2c_master_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_master_scoreboard)

    uvm_analysis_imp_mst_exp #(i2c_master_seq_item, i2c_master_scoreboard) exp_recv;
    uvm_analysis_imp_mst_obs #(i2c_master_obs_item, i2c_master_scoreboard) obs_recv;
    uvm_analysis_port #(i2c_master_seq_item) coverage_ap;
    i2c_master_seq_item mExpectedQ[$];
    bit mNoEventFailed[int unsigned];
    int unsigned mPassCount;
    int unsigned mFailCount;

    function new(string name = "i2c_master_scoreboard", uvm_component parent);
      super.new(name, parent);
      exp_recv = new("exp_recv", this);
      obs_recv = new("obs_recv", this);
      coverage_ap = new("coverage_ap", this);
    endfunction

    function i2c_master_seq_item clone_expected(i2c_master_seq_item item);
      i2c_master_seq_item cloned;

      cloned = i2c_master_seq_item::type_id::create("i2c_master_scb_clone");
      cloned.copy(item);
      return cloned;
    endfunction

    function bit expects_no_event(i2c_result_e result);
      return result == I2C_RESULT_RESET_ABORT;
    endfunction

    function void write_mst_exp(i2c_master_seq_item item);
      if (item.is_window_done) begin
        if (mNoEventFailed.exists(item.item_id)) begin
          mNoEventFailed.delete(item.item_id);
          return;
        end

        if ((mExpectedQ.size() != 0) && (mExpectedQ[0].item_id == item.item_id) &&
            expects_no_event(mExpectedQ[0].expected_result)) begin
          void'(mExpectedQ.pop_front());
          mPassCount++;
          coverage_ap.write(clone_expected(item));
        end
        else begin
          mFailCount++;
          `uvm_error("I2C_MST_SCB", "Unexpected no-event window completion")
        end

        return;
      end

      mExpectedQ.push_back(clone_expected(item));
    endfunction

    function void write_mst_obs(i2c_master_obs_item item);
      i2c_master_seq_item expected;

      if (mExpectedQ.size() == 0) begin
        mFailCount++;
        `uvm_error("I2C_MST_SCB", "Unexpected observed I2C master result")
        return;
      end

      expected = mExpectedQ[0];

      if (expects_no_event(expected.expected_result)) begin
        mFailCount++;
        mNoEventFailed[expected.item_id] = 1'b1;
        void'(mExpectedQ.pop_front());
        `uvm_error("I2C_MST_SCB", "Observed result for reset-aborted transfer")
        return;
      end

      void'(mExpectedQ.pop_front());

      if (!item.addr_valid) begin
        mFailCount++;
        `uvm_error("I2C_MST_SCB", "Bus monitor did not decode address phase")
        return;
      end

      if ((item.addr !== expected.addr) || (item.read !== expected.read)) begin
        mFailCount++;
        `uvm_error("I2C_MST_SCB",
                   $sformatf("Address/RW mismatch exp_addr=0x%0h exp_read=%0b obs_addr=0x%0h obs_read=%0b",
                             expected.addr, expected.read, item.addr, item.read))
        return;
      end

      if (item.ack_error !== (expected.expected_result == I2C_RESULT_ACK_ERROR)) begin
        mFailCount++;
        `uvm_error("I2C_MST_SCB",
                   $sformatf("ACK error mismatch exp=%0b obs=%0b",
                             (expected.expected_result == I2C_RESULT_ACK_ERROR),
                             item.ack_error))
        return;
      end

      if (!expected.read && (expected.expected_result == I2C_RESULT_OK)) begin
        if (!item.data_valid) begin
          mFailCount++;
          `uvm_error("I2C_MST_SCB", "Bus monitor did not decode write data phase")
          return;
        end

        if (item.data !== expected.tx_data) begin
          mFailCount++;
          `uvm_error("I2C_MST_SCB",
                     $sformatf("Write data mismatch exp=0x%0h obs=0x%0h",
                               expected.tx_data, item.data))
          return;
        end
      end

      if (expected.read && (expected.expected_result == I2C_RESULT_OK) &&
          (item.rx_data !== expected.read_data)) begin
        mFailCount++;
        `uvm_error("I2C_MST_SCB",
                   $sformatf("Read data mismatch exp=0x%0h obs=0x%0h",
                             expected.read_data, item.rx_data))
        return;
      end

      if (expected.read && (expected.expected_result == I2C_RESULT_OK)) begin
        if (!item.data_valid) begin
          mFailCount++;
          `uvm_error("I2C_MST_SCB", "Bus monitor did not decode read data phase")
          return;
        end

        if (item.data !== expected.read_data) begin
          mFailCount++;
          `uvm_error("I2C_MST_SCB",
                     $sformatf("Bus read data mismatch exp=0x%0h obs=0x%0h",
                               expected.read_data, item.data))
          return;
        end
      end

      mPassCount++;
      coverage_ap.write(clone_expected(expected));
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      if (mExpectedQ.size() != 0) begin
        mFailCount += mExpectedQ.size();
        `uvm_error("I2C_MST_SCB",
                   $sformatf("Unmatched expected items=%0d", mExpectedQ.size()))
      end

      `uvm_info("I2C_MST_SCB",
                $sformatf("Scoreboard pass=%0d fail=%0d", mPassCount, mFailCount),
                UVM_LOW)
    endfunction
  endclass
`endif

`ifndef I2C_TB_MASTER_ONLY
  class i2c_slave_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_slave_scoreboard)

    uvm_analysis_imp_slv_exp #(i2c_slave_seq_item, i2c_slave_scoreboard) exp_recv;
    uvm_analysis_imp_slv_obs #(i2c_slave_obs_item, i2c_slave_scoreboard) obs_recv;
    uvm_analysis_port #(i2c_slave_seq_item) coverage_ap;
    i2c_slave_seq_item mExpectedQ[$];
    bit mNoEventFailed[int unsigned];
    int unsigned mPassCount;
    int unsigned mFailCount;

    function new(string name = "i2c_slave_scoreboard", uvm_component parent);
      super.new(name, parent);
      exp_recv = new("exp_recv", this);
      obs_recv = new("obs_recv", this);
      coverage_ap = new("coverage_ap", this);
    endfunction

    function i2c_slave_seq_item clone_expected(i2c_slave_seq_item item);
      i2c_slave_seq_item cloned;

      cloned = i2c_slave_seq_item::type_id::create("i2c_slave_scb_clone");
      cloned.copy(item);
      return cloned;
    endfunction

    function bit expects_no_event(i2c_result_e result);
      return (result == I2C_RESULT_RESET_ABORT) ||
             (result == I2C_RESULT_ACK_ERROR) ||
             (result == I2C_RESULT_PARTIAL_STOP);
    endfunction

    function void write_slv_exp(i2c_slave_seq_item item);
      if (item.is_window_done) begin
        if (mNoEventFailed.exists(item.item_id)) begin
          mNoEventFailed.delete(item.item_id);
          return;
        end

        if ((mExpectedQ.size() != 0) && (mExpectedQ[0].item_id == item.item_id) &&
            expects_no_event(mExpectedQ[0].expected_result)) begin
          void'(mExpectedQ.pop_front());
          mPassCount++;
          coverage_ap.write(clone_expected(item));
        end
        else begin
          mFailCount++;
          `uvm_error("I2C_SLV_SCB", "Unexpected no-event window completion")
        end

        return;
      end

      mExpectedQ.push_back(clone_expected(item));
    endfunction

    function void write_slv_obs(i2c_slave_obs_item item);
      i2c_slave_seq_item expected;

      if (mExpectedQ.size() == 0) begin
        mFailCount++;
        `uvm_error("I2C_SLV_SCB", "Unexpected observed I2C slave result")
        return;
      end

      expected = mExpectedQ[0];

      if (expects_no_event(expected.expected_result)) begin
        mFailCount++;
        mNoEventFailed[expected.item_id] = 1'b1;
        void'(mExpectedQ.pop_front());
        `uvm_error("I2C_SLV_SCB", "Observed result for no-event transaction")
        return;
      end

      if (item.saw_txn_done) begin
        void'(mExpectedQ.pop_front());

        if (expected.read && !item.txn_read) begin
          mFailCount++;
          `uvm_error("I2C_SLV_SCB", "Expected read transaction but observed write completion")
          return;
        end

        if (!item.addr_valid || (item.bus_addr !== expected.bus_addr)) begin
          mFailCount++;
          `uvm_error("I2C_SLV_SCB",
                     $sformatf("Address mismatch exp=0x%0h obs=0x%0h valid=%0b",
                               expected.bus_addr, item.bus_addr, item.addr_valid))
          return;
        end

        if (!expected.read && (item.rx_data !== expected.write_data)) begin
          mFailCount++;
          `uvm_error("I2C_SLV_SCB",
                     $sformatf("Write data mismatch exp=0x%0h obs=0x%0h",
                               expected.write_data, item.rx_data))
          return;
        end

        if (!expected.read) begin
          if (!item.data_valid) begin
            mFailCount++;
            `uvm_error("I2C_SLV_SCB", "Bus monitor did not decode write data")
            return;
          end

          if (item.write_data !== expected.write_data) begin
            mFailCount++;
            `uvm_error("I2C_SLV_SCB",
                       $sformatf("Bus write data mismatch exp=0x%0h obs=0x%0h",
                                 expected.write_data, item.write_data))
            return;
          end
        end

        if (expected.read) begin
          if (!item.read_data_valid) begin
            mFailCount++;
            `uvm_error("I2C_SLV_SCB", "Bus monitor did not decode read data")
            return;
          end

          if (item.read_data !== expected.tx_data) begin
            mFailCount++;
            `uvm_error("I2C_SLV_SCB",
                       $sformatf("Read data mismatch exp=0x%0h obs=0x%0h",
                                 expected.tx_data, item.read_data))
            return;
          end
        end

        mPassCount++;
        coverage_ap.write(clone_expected(expected));
      end
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      if (mExpectedQ.size() != 0) begin
        mFailCount += mExpectedQ.size();
        `uvm_error("I2C_SLV_SCB",
                   $sformatf("Unmatched expected items=%0d", mExpectedQ.size()))
      end

      `uvm_info("I2C_SLV_SCB",
                $sformatf("Scoreboard pass=%0d fail=%0d", mPassCount, mFailCount),
                UVM_LOW)
    endfunction
  endclass
`endif

`ifndef I2C_TB_SLAVE_ONLY
  class i2c_master_coverage extends uvm_subscriber #(i2c_master_seq_item);
    `uvm_component_utils(i2c_master_coverage)

    bit mRead;
    bit [6:0] mAddr;
    bit [7:0] mData;
    i2c_result_e mResult;
    i2c_tick_mode_e mTickMode;
    i2c_jitter_mode_e mJitterMode;
    i2c_reset_phase_e mResetPhase;

    covergroup cg_i2c_master;
      option.per_instance = 1;
      cp_direction : coverpoint mRead {
        bins write = {0};
        bins read = {1};
      }
      cp_addr : coverpoint mAddr {
        bins default_addr = {7'h42};
      }
      cp_data : coverpoint mData {
        bins zero = {8'h00};
        bins ones = {8'hff};
        bins alt[] = {8'h55, 8'haa};
        bins other = default;
      }
      cp_result : coverpoint mResult {
        bins ok = {I2C_RESULT_OK};
        bins ack_error = {I2C_RESULT_ACK_ERROR};
        bins reset_abort = {I2C_RESULT_RESET_ABORT};
        ignore_bins unused = {I2C_RESULT_PARTIAL_STOP};
      }
      cp_tick : coverpoint mTickMode {
        bins regular = {I2C_TICK_REGULAR};
        bins irregular = {I2C_TICK_IRREGULAR};
      }
      cp_jitter : coverpoint mJitterMode {
        bins none = {I2C_JITTER_NONE};
        bins early_late = {I2C_JITTER_EARLY_LATE};
      }
      cp_reset : coverpoint mResetPhase {
        bins none = {I2C_RESET_NONE};
        bins data = {I2C_RESET_DATA};
        ignore_bins unused = {I2C_RESET_START, I2C_RESET_ADDR, I2C_RESET_STOP};
      }
    endgroup

    function new(string name = "i2c_master_coverage", uvm_component parent);
      super.new(name, parent);
      cg_i2c_master = new();
    endfunction

    function void write(i2c_master_seq_item t);
      mRead = t.read;
      mAddr = t.addr;
      mData = t.read ? t.read_data : t.tx_data;
      mResult = t.expected_result;
      mTickMode = t.tick_mode;
      mJitterMode = t.jitter_mode;
      mResetPhase = t.reset_phase;
      cg_i2c_master.sample();
    endfunction
  endclass
`endif

`ifndef I2C_TB_MASTER_ONLY
  class i2c_slave_coverage extends uvm_subscriber #(i2c_slave_seq_item);
    `uvm_component_utils(i2c_slave_coverage)

    bit mRead;
    bit mAddrHit;
    bit [7:0] mData;
    i2c_result_e mResult;
    i2c_tick_mode_e mTickMode;
    i2c_jitter_mode_e mJitterMode;
    i2c_reset_phase_e mResetPhase;

    covergroup cg_i2c_slave;
      option.per_instance = 1;
      cp_direction : coverpoint mRead {
        bins write = {0};
        bins read = {1};
      }
      cp_addr_hit : coverpoint mAddrHit {
        bins miss = {0};
        bins hit = {1};
      }
      cp_data : coverpoint mData {
        bins zero = {8'h00};
        bins ones = {8'hff};
        bins alt[] = {8'h55, 8'haa};
        bins other = default;
      }
      cp_result : coverpoint mResult {
        bins ok = {I2C_RESULT_OK};
        bins ack_error = {I2C_RESULT_ACK_ERROR};
        bins reset_abort = {I2C_RESULT_RESET_ABORT};
        ignore_bins unused = {I2C_RESULT_PARTIAL_STOP};
      }
      cp_tick : coverpoint mTickMode {
        bins regular = {I2C_TICK_REGULAR};
        bins irregular = {I2C_TICK_IRREGULAR};
      }
      cp_jitter : coverpoint mJitterMode {
        bins none = {I2C_JITTER_NONE};
        bins early_late = {I2C_JITTER_EARLY_LATE};
      }
      cp_reset : coverpoint mResetPhase {
        bins none = {I2C_RESET_NONE};
        bins data = {I2C_RESET_DATA};
        ignore_bins unused = {I2C_RESET_START, I2C_RESET_ADDR, I2C_RESET_STOP};
      }
    endgroup

    function new(string name = "i2c_slave_coverage", uvm_component parent);
      super.new(name, parent);
      cg_i2c_slave = new();
    endfunction

    function void write(i2c_slave_seq_item t);
      mRead = t.read;
      mAddrHit = (t.own_addr == t.bus_addr);
      mData = t.read ? t.tx_data : t.write_data;
      mResult = t.expected_result;
      mTickMode = t.tick_mode;
      mJitterMode = t.jitter_mode;
      mResetPhase = t.reset_phase;
      cg_i2c_slave.sample();
    endfunction
  endclass
`endif

`ifndef I2C_TB_SLAVE_ONLY
  class i2c_master_agent extends uvm_agent;
    `uvm_component_utils(i2c_master_agent)

    i2c_master_sequencer seqr;
    i2c_master_driver driver;
    i2c_master_monitor monitor;

    function new(string name = "i2c_master_agent", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seqr = i2c_master_sequencer::type_id::create("seqr", this);
      driver = i2c_master_driver::type_id::create("driver", this);
      monitor = i2c_master_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      driver.seq_item_port.connect(seqr.seq_item_export);
    endfunction
  endclass
`endif

`ifndef I2C_TB_MASTER_ONLY
  class i2c_slave_agent extends uvm_agent;
    `uvm_component_utils(i2c_slave_agent)

    i2c_slave_sequencer seqr;
    i2c_slave_driver driver;
    i2c_slave_monitor monitor;

    function new(string name = "i2c_slave_agent", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seqr = i2c_slave_sequencer::type_id::create("seqr", this);
      driver = i2c_slave_driver::type_id::create("driver", this);
      monitor = i2c_slave_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      driver.seq_item_port.connect(seqr.seq_item_export);
    endfunction
  endclass
`endif

`ifndef I2C_TB_SLAVE_ONLY
  class i2c_master_env extends uvm_env;
    `uvm_component_utils(i2c_master_env)

    i2c_master_agent agent;
    i2c_master_scoreboard scoreboard;
    i2c_master_coverage coverage;

    function new(string name = "i2c_master_env", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = i2c_master_agent::type_id::create("agent", this);
      scoreboard = i2c_master_scoreboard::type_id::create("scoreboard", this);
      coverage = i2c_master_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.driver.expected_ap.connect(scoreboard.exp_recv);
      agent.monitor.observed_ap.connect(scoreboard.obs_recv);
      scoreboard.coverage_ap.connect(coverage.analysis_export);
    endfunction
  endclass
`endif

`ifndef I2C_TB_MASTER_ONLY
  class i2c_slave_env extends uvm_env;
    `uvm_component_utils(i2c_slave_env)

    i2c_slave_agent agent;
    i2c_slave_scoreboard scoreboard;
    i2c_slave_coverage coverage;

    function new(string name = "i2c_slave_env", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = i2c_slave_agent::type_id::create("agent", this);
      scoreboard = i2c_slave_scoreboard::type_id::create("scoreboard", this);
      coverage = i2c_slave_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.driver.expected_ap.connect(scoreboard.exp_recv);
      agent.monitor.observed_ap.connect(scoreboard.obs_recv);
      scoreboard.coverage_ap.connect(coverage.analysis_export);
    endfunction
  endclass
`endif

`ifndef I2C_TB_SLAVE_ONLY
  class i2c_master_test extends uvm_test;
    `uvm_component_utils(i2c_master_test)

    i2c_master_env env;
    string seq_name;

    function new(string name = "i2c_master_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = i2c_master_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      i2c_master_sequence seq;

      phase.raise_objection(this);
      seq = i2c_master_sequence::type_id::create("seq");
      if (!$value$plusargs("I2C_MASTER_SEQ=%s", seq_name)) begin
        seq_name = "all";
      end

      seq.seq_name = seq_name;
      seq.start(env.agent.seqr);
      #2000ns;
      phase.drop_objection(this);
    endtask
  endclass
`endif

`ifndef I2C_TB_MASTER_ONLY
  class i2c_slave_test extends uvm_test;
    `uvm_component_utils(i2c_slave_test)

    i2c_slave_env env;
    string seq_name;

    function new(string name = "i2c_slave_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = i2c_slave_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      i2c_slave_sequence seq;

      phase.raise_objection(this);
      seq = i2c_slave_sequence::type_id::create("seq");
      if (!$value$plusargs("I2C_SLAVE_SEQ=%s", seq_name)) begin
        seq_name = "all";
      end

      seq.seq_name = seq_name;
      seq.start(env.agent.seqr);
      #2000ns;
      phase.drop_objection(this);
    endtask
  endclass
`endif
endpackage

`endif
