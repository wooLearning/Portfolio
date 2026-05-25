`ifndef TB_SPI_PKG_SV
`define TB_SPI_PKG_SV

`include "uvm_macros.svh"

package tb_spi_pkg;
  import uvm_pkg::*;

  typedef virtual spi_master_if spi_master_vif_t;
  typedef virtual spi_slave_if  spi_slave_vif_t;

  `uvm_analysis_imp_decl(_mst_exp)
  `uvm_analysis_imp_decl(_mst_obs)
  `uvm_analysis_imp_decl(_slv_exp)
  `uvm_analysis_imp_decl(_slv_obs)

  typedef enum int {
    SPI_RESULT_OK,
    SPI_RESULT_RESET_ABORT,
    SPI_RESULT_CS_ABORT
  } spi_result_e;

  typedef enum int {
    SPI_TICK_REGULAR,
    SPI_TICK_IRREGULAR
  } spi_tick_mode_e;

  typedef enum int {
    SPI_JITTER_NONE,
    SPI_JITTER_EARLY_LATE
  } spi_jitter_mode_e;

  typedef enum int {
    SPI_RESET_NONE,
    SPI_RESET_IDLE,
    SPI_RESET_SELECTED,
    SPI_RESET_TRANSFER
  } spi_reset_phase_e;

  function bit is_directed_pattern(bit [7:0] data);
    return (data == 8'h00) || (data == 8'hff) ||
           (data == 8'h55) || (data == 8'haa) ||
           (data == 8'h01) || (data == 8'h80);
  endfunction

  class spi_master_seq_item extends uvm_sequence_item;
    `uvm_object_utils(spi_master_seq_item)

    rand bit [7:0]        tx_data;
    rand bit [7:0]        miso_data;
    rand bit              cpol;
    rand bit              cpha;
    spi_result_e          expected_result;
    spi_tick_mode_e       tick_mode;
    spi_jitter_mode_e     jitter_mode;
    spi_reset_phase_e     reset_phase;
    int unsigned          idle_cycles;
    int unsigned          item_id;
    bit                   is_window_done;

    constraint c_idle_cycles {
      idle_cycles inside {[1:8]};
    }

    function new(string name = "spi_master_seq_item");
      super.new(name);
      expected_result = SPI_RESULT_OK;
      tick_mode = SPI_TICK_REGULAR;
      jitter_mode = SPI_JITTER_NONE;
      reset_phase = SPI_RESET_NONE;
      idle_cycles = 2;
      item_id = 0;
      is_window_done = 1'b0;
    endfunction

    function void do_copy(uvm_object rhs);
      spi_master_seq_item rhs_;

      if (!$cast(rhs_, rhs)) begin
        `uvm_fatal("SPI_MST_ITEM", "do_copy cast failed")
      end

      super.do_copy(rhs);
      tx_data = rhs_.tx_data;
      miso_data = rhs_.miso_data;
      cpol = rhs_.cpol;
      cpha = rhs_.cpha;
      expected_result = rhs_.expected_result;
      tick_mode = rhs_.tick_mode;
      jitter_mode = rhs_.jitter_mode;
      reset_phase = rhs_.reset_phase;
      idle_cycles = rhs_.idle_cycles;
      item_id = rhs_.item_id;
      is_window_done = rhs_.is_window_done;
    endfunction
  endclass

  class spi_master_obs_item extends uvm_sequence_item;
    `uvm_object_utils(spi_master_obs_item)

    bit [7:0] mosi_data;
    bit [7:0] rx_data;
    bit       saw_done;
    bit       cpol;
    bit       cpha;

    function new(string name = "spi_master_obs_item");
      super.new(name);
    endfunction
  endclass

  class spi_slave_seq_item extends uvm_sequence_item;
    `uvm_object_utils(spi_slave_seq_item)

    rand bit [7:0]        mosi_data;
    rand bit [7:0]        tx_data;
    rand bit              cpol;
    rand bit              cpha;
    spi_result_e          expected_result;
    spi_tick_mode_e       tick_mode;
    spi_jitter_mode_e     jitter_mode;
    spi_reset_phase_e     reset_phase;
    int unsigned          idle_cycles;
    int unsigned          item_id;
    bit                   is_window_done;

    constraint c_idle_cycles {
      idle_cycles inside {[1:8]};
    }

    function new(string name = "spi_slave_seq_item");
      super.new(name);
      expected_result = SPI_RESULT_OK;
      tick_mode = SPI_TICK_REGULAR;
      jitter_mode = SPI_JITTER_NONE;
      reset_phase = SPI_RESET_NONE;
      idle_cycles = 2;
      item_id = 0;
      is_window_done = 1'b0;
    endfunction

    function void do_copy(uvm_object rhs);
      spi_slave_seq_item rhs_;

      if (!$cast(rhs_, rhs)) begin
        `uvm_fatal("SPI_SLV_ITEM", "do_copy cast failed")
      end

      super.do_copy(rhs);
      mosi_data = rhs_.mosi_data;
      tx_data = rhs_.tx_data;
      cpol = rhs_.cpol;
      cpha = rhs_.cpha;
      expected_result = rhs_.expected_result;
      tick_mode = rhs_.tick_mode;
      jitter_mode = rhs_.jitter_mode;
      reset_phase = rhs_.reset_phase;
      idle_cycles = rhs_.idle_cycles;
      item_id = rhs_.item_id;
      is_window_done = rhs_.is_window_done;
    endfunction
  endclass

  class spi_slave_obs_item extends uvm_sequence_item;
    `uvm_object_utils(spi_slave_obs_item)

    bit [7:0] rx_data;
    bit [7:0] miso_data;
    bit       saw_rx_valid;
    bit       cpol;
    bit       cpha;

    function new(string name = "spi_slave_obs_item");
      super.new(name);
    endfunction
  endclass

  class spi_master_sequence extends uvm_sequence #(spi_master_seq_item);
    `uvm_object_utils(spi_master_sequence)

    string seq_name;

    function new(string name = "spi_master_sequence");
      super.new(name);
      seq_name = "all";
    endfunction

    task automatic send(bit [7:0] tx_data,
                        bit [7:0] miso_data,
                        bit cpol,
                        bit cpha,
                        spi_result_e result = SPI_RESULT_OK,
                        spi_reset_phase_e reset_phase = SPI_RESET_NONE,
                        spi_tick_mode_e tick_mode = SPI_TICK_REGULAR,
                        spi_jitter_mode_e jitter_mode = SPI_JITTER_NONE);
      spi_master_seq_item item;

      item = spi_master_seq_item::type_id::create("item");
      start_item(item);
      item.tx_data = tx_data;
      item.miso_data = miso_data;
      item.cpol = cpol;
      item.cpha = cpha;
      item.expected_result = result;
      item.reset_phase = reset_phase;
      item.tick_mode = tick_mode;
      item.jitter_mode = jitter_mode;
      item.idle_cycles = 2;
      finish_item(item);
    endtask

    task body();
      if ((seq_name == "smoke") || (seq_name == "all")) begin
        send(8'ha5, 8'h3c, 1'b0, 1'b0);
      end

      if ((seq_name == "directed") || (seq_name == "all")) begin
        send(8'h00, 8'hff, 1'b0, 1'b0);
        send(8'hff, 8'h00, 1'b0, 1'b1);
        send(8'h55, 8'haa, 1'b1, 1'b0);
        send(8'haa, 8'h55, 1'b1, 1'b1);
        send(8'h01, 8'h80, 1'b0, 1'b0);
        send(8'h80, 8'h01, 1'b1, 1'b1);
      end

      if ((seq_name == "mode") || (seq_name == "all")) begin
        for (int mode = 0; mode < 4; mode++) begin
          send(8'h10 + mode[7:0], 8'he0 + mode[7:0], mode[1], mode[0]);
        end
      end

      if ((seq_name == "reset") || (seq_name == "all")) begin
        send(8'h5a, 8'ha5, 1'b0, 1'b0, SPI_RESULT_RESET_ABORT, SPI_RESET_TRANSFER);
      end

      if ((seq_name == "jitter") || (seq_name == "all")) begin
        send(8'hc3, 8'h3c, 1'b1, 1'b0, SPI_RESULT_OK, SPI_RESET_NONE,
             SPI_TICK_IRREGULAR, SPI_JITTER_EARLY_LATE);
      end

      if ((seq_name == "corner") || (seq_name == "all")) begin
        send(8'h00, 8'h00, 1'b0, 1'b0);
        send(8'hff, 8'hff, 1'b0, 1'b1);
        send(8'h7e, 8'h81, 1'b1, 1'b0);
        send(8'h81, 8'h7e, 1'b1, 1'b1);
        send(8'ha5, 8'h5a, 1'b0, 1'b0, SPI_RESULT_OK, SPI_RESET_NONE,
             SPI_TICK_IRREGULAR, SPI_JITTER_EARLY_LATE);
        send(8'h5a, 8'ha5, 1'b1, 1'b1, SPI_RESULT_RESET_ABORT, SPI_RESET_TRANSFER);
      end

      if ((seq_name == "byte_sweep") || (seq_name == "all")) begin
        bit [7:0] data;

        for (int unsigned i = 0; i < 256; i++) begin
          data = i[7:0];
          send(data, ~data, i[1], i[0]);
        end
      end

      if (seq_name == "full_random") begin
        int unsigned count;

        if (!$value$plusargs("SPI_MASTER_RANDOM_COUNT=%d", count)) begin
          count = 512;
        end

        for (int unsigned i = 0; i < count; i++) begin
          bit cpol;
          bit cpha;
          spi_tick_mode_e tick_mode;
          spi_jitter_mode_e jitter_mode;

          cpol = $urandom_range(0, 1);
          cpha = $urandom_range(0, 1);
          tick_mode = spi_tick_mode_e'($urandom_range(0, 1));
          jitter_mode = spi_jitter_mode_e'($urandom_range(0, 1));

          send($urandom_range(0, 255), $urandom_range(0, 255), cpol, cpha,
               SPI_RESULT_OK, SPI_RESET_NONE, tick_mode, jitter_mode);
        end
      end
    endtask
  endclass

  class spi_slave_sequence extends uvm_sequence #(spi_slave_seq_item);
    `uvm_object_utils(spi_slave_sequence)

    string seq_name;

    function new(string name = "spi_slave_sequence");
      super.new(name);
      seq_name = "all";
    endfunction

    task automatic send(bit [7:0] mosi_data,
                        bit [7:0] tx_data,
                        bit cpol,
                        bit cpha,
                        spi_result_e result = SPI_RESULT_OK,
                        spi_reset_phase_e reset_phase = SPI_RESET_NONE,
                        spi_tick_mode_e tick_mode = SPI_TICK_REGULAR,
                        spi_jitter_mode_e jitter_mode = SPI_JITTER_NONE);
      spi_slave_seq_item item;

      item = spi_slave_seq_item::type_id::create("item");
      start_item(item);
      item.mosi_data = mosi_data;
      item.tx_data = tx_data;
      item.cpol = cpol;
      item.cpha = cpha;
      item.expected_result = result;
      item.reset_phase = reset_phase;
      item.tick_mode = tick_mode;
      item.jitter_mode = jitter_mode;
      item.idle_cycles = 2;
      finish_item(item);
    endtask

    task body();
      if ((seq_name == "smoke") || (seq_name == "all")) begin
        send(8'ha5, 8'h3c, 1'b0, 1'b0);
      end

      if ((seq_name == "directed") || (seq_name == "all")) begin
        send(8'h00, 8'hff, 1'b0, 1'b0);
        send(8'hff, 8'h00, 1'b0, 1'b1);
        send(8'h55, 8'haa, 1'b1, 1'b0);
        send(8'haa, 8'h55, 1'b1, 1'b1);
      end

      if ((seq_name == "mode") || (seq_name == "all")) begin
        for (int mode = 0; mode < 4; mode++) begin
          send(8'h20 + mode[7:0], 8'h80 + mode[7:0], mode[1], mode[0]);
        end
      end

      if ((seq_name == "abort") || (seq_name == "all")) begin
        send(8'h5a, 8'ha5, 1'b0, 1'b0, SPI_RESULT_CS_ABORT);
      end

      if ((seq_name == "reset") || (seq_name == "all")) begin
        send(8'hc3, 8'h3c, 1'b1, 1'b1, SPI_RESULT_RESET_ABORT, SPI_RESET_TRANSFER);
      end

      if ((seq_name == "jitter") || (seq_name == "all")) begin
        send(8'hf0, 8'h0f, 1'b1, 1'b0, SPI_RESULT_OK, SPI_RESET_NONE,
             SPI_TICK_IRREGULAR, SPI_JITTER_EARLY_LATE);
      end

      if ((seq_name == "corner") || (seq_name == "all")) begin
        send(8'h00, 8'h00, 1'b0, 1'b0);
        send(8'hff, 8'hff, 1'b0, 1'b1);
        send(8'h7e, 8'h81, 1'b1, 1'b0);
        send(8'h81, 8'h7e, 1'b1, 1'b1);
        send(8'ha5, 8'h5a, 1'b0, 1'b0, SPI_RESULT_CS_ABORT);
        send(8'h5a, 8'ha5, 1'b1, 1'b1, SPI_RESULT_RESET_ABORT, SPI_RESET_TRANSFER);
      end

      if ((seq_name == "byte_sweep") || (seq_name == "all")) begin
        bit [7:0] data;

        for (int unsigned i = 0; i < 256; i++) begin
          data = i[7:0];
          send(data, ~data, i[1], i[0]);
        end
      end

      if (seq_name == "full_random") begin
        int unsigned count;

        if (!$value$plusargs("SPI_SLAVE_RANDOM_COUNT=%d", count)) begin
          count = 512;
        end

        for (int unsigned i = 0; i < count; i++) begin
          bit cpol;
          bit cpha;
          spi_tick_mode_e tick_mode;
          spi_jitter_mode_e jitter_mode;

          cpol = $urandom_range(0, 1);
          cpha = $urandom_range(0, 1);
          tick_mode = spi_tick_mode_e'($urandom_range(0, 1));
          jitter_mode = spi_jitter_mode_e'($urandom_range(0, 1));

          send($urandom_range(0, 255), $urandom_range(0, 255), cpol, cpha,
               SPI_RESULT_OK, SPI_RESET_NONE, tick_mode, jitter_mode);
        end
      end
    endtask
  endclass

  class spi_master_sequencer extends uvm_sequencer #(spi_master_seq_item);
    `uvm_component_utils(spi_master_sequencer)

    function new(string name = "spi_master_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class spi_slave_sequencer extends uvm_sequencer #(spi_slave_seq_item);
    `uvm_component_utils(spi_slave_sequencer)

    function new(string name = "spi_slave_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

`ifndef SPI_TB_SLAVE_ONLY
  class spi_master_driver extends uvm_driver #(spi_master_seq_item);
    `uvm_component_utils(spi_master_driver)

    spi_master_vif_t spi_vif;
    uvm_analysis_port #(spi_master_seq_item) expected_ap;
    int unsigned mNextItemId;

    function new(string name = "spi_master_driver", uvm_component parent);
      super.new(name, parent);
      expected_ap = new("expected_ap", this);
      mNextItemId = 1;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(spi_master_vif_t)::get(this, "", "spi_master_vif", spi_vif)) begin
        `uvm_fatal("SPI_MST_DRV", "Driver failed to get virtual interface")
      end
    endfunction

    function spi_master_seq_item clone_item(spi_master_seq_item item);
      spi_master_seq_item cloned;

      cloned = spi_master_seq_item::type_id::create("spi_master_expected_clone");
      cloned.copy(item);
      return cloned;
    endfunction

    function int tick_gap(spi_master_seq_item item, int index);
      tick_gap = (item.tick_mode == SPI_TICK_REGULAR) ? 2 : ((index % 2) ? 3 : 1);

      if (item.jitter_mode == SPI_JITTER_EARLY_LATE) begin
        tick_gap += index[0];
      end
    endfunction

    task automatic wait_clks(int cycles);
      repeat (cycles) begin
        @(spi_vif.drv_cb);
        spi_vif.drv_cb.iTick <= 1'b0;
      end
    endtask

    task automatic pulse_tick(spi_master_seq_item item, int index, output bit saw_done);
      saw_done = 1'b0;

      repeat (tick_gap(item, index)) begin
        @(spi_vif.drv_cb);
        spi_vif.drv_cb.iTick <= 1'b0;
        saw_done |= spi_vif.drv_cb.oDone;
      end

      @(spi_vif.drv_cb);
      spi_vif.drv_cb.iTick <= 1'b1;
      saw_done |= spi_vif.drv_cb.oDone;

      @(spi_vif.drv_cb);
      spi_vif.drv_cb.iTick <= 1'b0;
      saw_done |= spi_vif.drv_cb.oDone;
    endtask

    task automatic drive_idle();
      spi_vif.iRst    <= 1'b0;
      spi_vif.iTick   <= 1'b0;
      spi_vif.iStart  <= 1'b0;
      spi_vif.iCpol   <= 1'b0;
      spi_vif.iCpha   <= 1'b0;
      spi_vif.iTxData <= '0;
      spi_vif.iMiso   <= 1'b0;
    endtask

    task automatic drive_initial_reset();
      spi_vif.iRst   <= 1'b1;
      spi_vif.iTick  <= 1'b0;
      spi_vif.iStart <= 1'b0;
      wait_clks(5);
      spi_vif.drv_cb.iRst <= 1'b0;
      wait_clks(5);
    endtask

    task automatic drive_reset_pulse();
      spi_vif.drv_cb.iRst   <= 1'b1;
      spi_vif.drv_cb.iTick  <= 1'b0;
      spi_vif.drv_cb.iStart <= 1'b0;
      wait_clks(4);
      spi_vif.drv_cb.iRst <= 1'b0;
      wait_clks(5);
    endtask

    task automatic publish_expected(spi_master_seq_item item);
      item.item_id = mNextItemId;
      mNextItemId++;
      expected_ap.write(clone_item(item));
    endtask

    task automatic publish_window_done(spi_master_seq_item item);
      spi_master_seq_item done_item;

      done_item = clone_item(item);
      done_item.is_window_done = 1'b1;
      expected_ap.write(done_item);
    endtask

    task automatic update_miso(spi_master_seq_item item,
                               inout bit prev_sclk,
                               inout int shift_count);
      bit rise_edge;
      bit fall_edge;
      bit lead_edge;
      bit trail_edge;
      bit shift_edge;

      rise_edge = !prev_sclk && spi_vif.drv_cb.oSclk;
      fall_edge =  prev_sclk && !spi_vif.drv_cb.oSclk;
      lead_edge = item.cpol ? fall_edge : rise_edge;
      trail_edge = item.cpol ? rise_edge : fall_edge;
      shift_edge = item.cpha ? lead_edge : trail_edge;

      if (!spi_vif.drv_cb.oCsN && shift_edge && (shift_count < 8)) begin
        spi_vif.drv_cb.iMiso <= item.miso_data[7 - shift_count];
        shift_count++;
      end

      prev_sclk = spi_vif.drv_cb.oSclk;
    endtask

    task automatic drive_transfer(spi_master_seq_item item);
      bit prev_sclk;
      int shift_count;
      bit saw_done;

      wait_clks(item.idle_cycles);
      spi_vif.drv_cb.iCpol   <= item.cpol;
      spi_vif.drv_cb.iCpha   <= item.cpha;
      spi_vif.drv_cb.iTxData <= item.tx_data;
      spi_vif.drv_cb.iMiso   <= item.miso_data[7];
      wait_clks(2);

      spi_vif.drv_cb.iStart <= 1'b1;
      @(spi_vif.drv_cb);
      spi_vif.drv_cb.iStart <= 1'b0;

      prev_sclk = item.cpol;
      shift_count = item.cpha ? 0 : 1;

      for (int i = 0; i < 80; i++) begin
        if (item.expected_result == SPI_RESULT_RESET_ABORT && i == 12) begin
          drive_reset_pulse();
          publish_window_done(item);
          return;
        end

        pulse_tick(item, i, saw_done);
        update_miso(item, prev_sclk, shift_count);

        if (saw_done || spi_vif.drv_cb.oDone) begin
          wait_clks(item.idle_cycles);
          return;
        end
      end

      `uvm_error("SPI_MST_DRV", "Timed out waiting for spi_master oDone")
    endtask

    task automatic drive_item(spi_master_seq_item item);
      publish_expected(item);

      if ((item.expected_result == SPI_RESULT_RESET_ABORT) &&
          (item.reset_phase == SPI_RESET_IDLE)) begin
        drive_reset_pulse();
        publish_window_done(item);
        return;
      end

      drive_transfer(item);
    endtask

    task run_phase(uvm_phase phase);
      spi_master_seq_item item;

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

`ifndef SPI_TB_MASTER_ONLY
  class spi_slave_driver extends uvm_driver #(spi_slave_seq_item);
    `uvm_component_utils(spi_slave_driver)

    spi_slave_vif_t spi_vif;
    uvm_analysis_port #(spi_slave_seq_item) expected_ap;
    int unsigned mNextItemId;

    function new(string name = "spi_slave_driver", uvm_component parent);
      super.new(name, parent);
      expected_ap = new("expected_ap", this);
      mNextItemId = 1;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(spi_slave_vif_t)::get(this, "", "spi_slave_vif", spi_vif)) begin
        `uvm_fatal("SPI_SLV_DRV", "Driver failed to get virtual interface")
      end
    endfunction

    function spi_slave_seq_item clone_item(spi_slave_seq_item item);
      spi_slave_seq_item cloned;

      cloned = spi_slave_seq_item::type_id::create("spi_slave_expected_clone");
      cloned.copy(item);
      return cloned;
    endfunction

    task automatic wait_clks(int cycles);
      repeat (cycles) begin
        @(spi_vif.drv_cb);
      end
    endtask

    task automatic set_sclk(bit value);
      spi_vif.drv_cb.iSclk <= value;
      wait_clks(4);
    endtask

    task automatic drive_idle();
      spi_vif.iRst    <= 1'b0;
      spi_vif.iCpol   <= 1'b0;
      spi_vif.iCpha   <= 1'b0;
      spi_vif.iSclk   <= 1'b0;
      spi_vif.iCsN    <= 1'b1;
      spi_vif.iMosi   <= 1'b0;
      spi_vif.iTxData <= '0;
    endtask

    task automatic drive_initial_reset();
      spi_vif.iRst <= 1'b1;
      wait_clks(5);
      spi_vif.drv_cb.iRst <= 1'b0;
      wait_clks(5);
    endtask

    task automatic drive_reset_pulse();
      spi_vif.drv_cb.iRst  <= 1'b1;
      spi_vif.drv_cb.iCsN  <= 1'b1;
      wait_clks(4);
      spi_vif.drv_cb.iRst <= 1'b0;
      wait_clks(5);
    endtask

    task automatic publish_expected(spi_slave_seq_item item);
      item.item_id = mNextItemId;
      mNextItemId++;
      expected_ap.write(clone_item(item));
    endtask

    task automatic publish_window_done(spi_slave_seq_item item);
      spi_slave_seq_item done_item;

      done_item = clone_item(item);
      done_item.is_window_done = 1'b1;
      expected_ap.write(done_item);
    endtask

    task automatic drive_spi_byte(spi_slave_seq_item item, int valid_bits = 8);
      bit lead_level;
      bit trail_level;
      int bit_index;

      lead_level = !item.cpol;
      trail_level = item.cpol;

      for (bit_index = 0; bit_index < valid_bits; bit_index++) begin
        if (!item.cpha) begin
          spi_vif.drv_cb.iMosi <= item.mosi_data[7 - bit_index];
          set_sclk(lead_level);
          set_sclk(trail_level);
        end
        else begin
          set_sclk(lead_level);
          spi_vif.drv_cb.iMosi <= item.mosi_data[7 - bit_index];
          set_sclk(trail_level);
        end
      end
    endtask

    task automatic drive_item(spi_slave_seq_item item);
      publish_expected(item);
      wait_clks(item.idle_cycles);

      spi_vif.drv_cb.iCpol   <= item.cpol;
      spi_vif.drv_cb.iCpha   <= item.cpha;
      spi_vif.drv_cb.iSclk   <= item.cpol;
      spi_vif.drv_cb.iTxData <= item.tx_data;
      wait_clks(4);

      if ((item.expected_result == SPI_RESULT_RESET_ABORT) &&
          (item.reset_phase == SPI_RESET_IDLE)) begin
        drive_reset_pulse();
        publish_window_done(item);
        return;
      end

      spi_vif.drv_cb.iCsN <= 1'b0;
      wait_clks(4);

      if (item.expected_result == SPI_RESULT_CS_ABORT) begin
        drive_spi_byte(item, 4);
        spi_vif.drv_cb.iCsN <= 1'b1;
        wait_clks(8);
        publish_window_done(item);
        return;
      end

      if (item.expected_result == SPI_RESULT_RESET_ABORT) begin
        drive_spi_byte(item, 4);
        drive_reset_pulse();
        publish_window_done(item);
        return;
      end

      drive_spi_byte(item, 8);
      wait_clks(4);
      spi_vif.drv_cb.iCsN <= 1'b1;
      wait_clks(item.idle_cycles + 4);
    endtask

    task run_phase(uvm_phase phase);
      spi_slave_seq_item item;

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

`ifndef SPI_TB_SLAVE_ONLY
  class spi_master_monitor extends uvm_monitor;
    `uvm_component_utils(spi_master_monitor)

    spi_master_vif_t spi_vif;
    uvm_analysis_port #(spi_master_obs_item) observed_ap;
    bit mPrevSclk;
    bit mPrevCsN;
    bit [7:0] mMosiShift;
    int mSampleCnt;
    bit mCpol;
    bit mCpha;

    function new(string name = "spi_master_monitor", uvm_component parent);
      super.new(name, parent);
      observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(spi_master_vif_t)::get(this, "", "spi_master_vif", spi_vif)) begin
        `uvm_fatal("SPI_MST_MON", "Monitor failed to get virtual interface")
      end
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(spi_vif.mon_cb);

        if (spi_vif.mon_cb.iRst) begin
          mPrevSclk = spi_vif.mon_cb.oSclk;
          mPrevCsN = spi_vif.mon_cb.oCsN;
          mSampleCnt = 0;
          mMosiShift = '0;
        end
        else begin
          bit rise_edge;
          bit fall_edge;
          bit lead_edge;
          bit trail_edge;
          bit sample_edge;

          if (mPrevCsN && !spi_vif.mon_cb.oCsN) begin
            mCpol = spi_vif.mon_cb.iCpol;
            mCpha = spi_vif.mon_cb.iCpha;
            mSampleCnt = 0;
            mMosiShift = '0;
          end

          rise_edge = !mPrevSclk && spi_vif.mon_cb.oSclk;
          fall_edge =  mPrevSclk && !spi_vif.mon_cb.oSclk;
          lead_edge = mCpol ? fall_edge : rise_edge;
          trail_edge = mCpol ? rise_edge : fall_edge;
          sample_edge = mCpha ? trail_edge : lead_edge;

          if (!spi_vif.mon_cb.oCsN && sample_edge && (mSampleCnt < 8)) begin
            mMosiShift = {mMosiShift[6:0], spi_vif.mon_cb.oMosi};
            mSampleCnt++;
          end

          if (spi_vif.mon_cb.oDone) begin
            spi_master_obs_item item;

            item = spi_master_obs_item::type_id::create("spi_master_obs");
            item.mosi_data = mMosiShift;
            item.rx_data = spi_vif.mon_cb.oRxData;
            item.saw_done = 1'b1;
            item.cpol = mCpol;
            item.cpha = mCpha;
            observed_ap.write(item);
          end

          mPrevSclk = spi_vif.mon_cb.oSclk;
          mPrevCsN = spi_vif.mon_cb.oCsN;
        end
      end
    endtask
  endclass
`endif

`ifndef SPI_TB_MASTER_ONLY
  class spi_slave_monitor extends uvm_monitor;
    `uvm_component_utils(spi_slave_monitor)

    spi_slave_vif_t spi_vif;
    uvm_analysis_port #(spi_slave_obs_item) observed_ap;
    bit mPrevSclk;
    bit mPrevCsN;
    bit [7:0] mMisoShift;
    int mSampleCnt;
    bit mSamplePending;
    bit mCpol;
    bit mCpha;

    function new(string name = "spi_slave_monitor", uvm_component parent);
      super.new(name, parent);
      observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(spi_slave_vif_t)::get(this, "", "spi_slave_vif", spi_vif)) begin
        `uvm_fatal("SPI_SLV_MON", "Monitor failed to get virtual interface")
      end
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(spi_vif.mon_cb);

        if (spi_vif.mon_cb.oRxValid) begin
          spi_slave_obs_item item;

          item = spi_slave_obs_item::type_id::create("spi_slave_obs");
          item.rx_data = spi_vif.mon_cb.oRxData;
          item.miso_data = mMisoShift;
          item.saw_rx_valid = 1'b1;
          item.cpol = mCpol;
          item.cpha = mCpha;
          observed_ap.write(item);
        end

        if (spi_vif.mon_cb.iRst) begin
          mPrevSclk = spi_vif.mon_cb.iSclk;
          mPrevCsN = spi_vif.mon_cb.iCsN;
          mSampleCnt = 0;
          mSamplePending = 1'b0;
          mMisoShift = '0;
          mCpol = spi_vif.mon_cb.iCpol;
          mCpha = spi_vif.mon_cb.iCpha;
        end
        else begin
          bit rise_edge;
          bit fall_edge;
          bit lead_edge;
          bit trail_edge;
          bit sample_edge;

          if (mPrevCsN && !spi_vif.mon_cb.iCsN) begin
            mPrevSclk = spi_vif.mon_cb.iSclk;
            mSampleCnt = 0;
            mSamplePending = 1'b0;
            mMisoShift = '0;
            mCpol = spi_vif.mon_cb.iCpol;
            mCpha = spi_vif.mon_cb.iCpha;
          end

          if (mSamplePending && (mSampleCnt < 8)) begin
            mMisoShift = {mMisoShift[6:0], spi_vif.mon_cb.oMiso};
            mSampleCnt++;
            mSamplePending = 1'b0;
          end

          rise_edge = !mPrevSclk && spi_vif.mon_cb.iSclk;
          fall_edge =  mPrevSclk && !spi_vif.mon_cb.iSclk;
          lead_edge = mCpol ? fall_edge : rise_edge;
          trail_edge = mCpol ? rise_edge : fall_edge;
          sample_edge = mCpha ? trail_edge : lead_edge;

          if (sample_edge && spi_vif.mon_cb.oMisoOe && (mSampleCnt < 8)) begin
            mSamplePending = 1'b1;
          end

          mPrevSclk = spi_vif.mon_cb.iSclk;
          mPrevCsN = spi_vif.mon_cb.iCsN;
        end
      end
    endtask
  endclass
`endif

`ifndef SPI_TB_SLAVE_ONLY
  class spi_master_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_master_scoreboard)

    uvm_analysis_imp_mst_exp #(spi_master_seq_item, spi_master_scoreboard) exp_recv;
    uvm_analysis_imp_mst_obs #(spi_master_obs_item, spi_master_scoreboard) obs_recv;
    uvm_analysis_port #(spi_master_seq_item) coverage_ap;
    spi_master_seq_item mExpectedQ[$];
    bit mNoEventFailed[int unsigned];
    int unsigned mPassCount;
    int unsigned mFailCount;

    function new(string name = "spi_master_scoreboard", uvm_component parent);
      super.new(name, parent);
      exp_recv = new("exp_recv", this);
      obs_recv = new("obs_recv", this);
      coverage_ap = new("coverage_ap", this);
    endfunction

    function bit expects_no_event(spi_result_e result);
      return result == SPI_RESULT_RESET_ABORT;
    endfunction

    function spi_master_seq_item clone_expected(spi_master_seq_item item);
      spi_master_seq_item cloned;

      cloned = spi_master_seq_item::type_id::create("spi_master_scb_clone");
      cloned.copy(item);
      return cloned;
    endfunction

    function void write_mst_exp(spi_master_seq_item item);
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
          `uvm_error("SPI_MST_SCB", "Unexpected no-event window completion")
        end

        return;
      end

      mExpectedQ.push_back(clone_expected(item));
    endfunction

    function void write_mst_obs(spi_master_obs_item item);
      spi_master_seq_item expected;

      if (mExpectedQ.size() == 0) begin
        mFailCount++;
        `uvm_error("SPI_MST_SCB", "Unexpected observed SPI master result")
        return;
      end

      expected = mExpectedQ[0];

      if (expects_no_event(expected.expected_result)) begin
        mFailCount++;
        mNoEventFailed[expected.item_id] = 1'b1;
        void'(mExpectedQ.pop_front());
        `uvm_error("SPI_MST_SCB", "Observed result for reset-aborted SPI master transfer")
        return;
      end

      void'(mExpectedQ.pop_front());

      if (item.mosi_data !== expected.tx_data) begin
        mFailCount++;
        `uvm_error("SPI_MST_SCB",
                   $sformatf("MOSI mismatch exp=0x%0h obs=0x%0h",
                             expected.tx_data, item.mosi_data))
        return;
      end

      if (item.rx_data !== expected.miso_data) begin
        mFailCount++;
        `uvm_error("SPI_MST_SCB",
                   $sformatf("RX mismatch exp=0x%0h obs=0x%0h",
                             expected.miso_data, item.rx_data))
        return;
      end

      if (!item.saw_done) begin
        mFailCount++;
        `uvm_error("SPI_MST_SCB", "Missing oDone")
        return;
      end

      mPassCount++;
      coverage_ap.write(clone_expected(expected));
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      if (mExpectedQ.size() != 0) begin
        mFailCount += mExpectedQ.size();
        `uvm_error("SPI_MST_SCB",
                   $sformatf("Unmatched expected items=%0d", mExpectedQ.size()))
      end

      `uvm_info("SPI_MST_SCB",
                $sformatf("Scoreboard pass=%0d fail=%0d", mPassCount, mFailCount),
                UVM_LOW)
    endfunction
  endclass
`endif

`ifndef SPI_TB_MASTER_ONLY
  class spi_slave_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_slave_scoreboard)

    uvm_analysis_imp_slv_exp #(spi_slave_seq_item, spi_slave_scoreboard) exp_recv;
    uvm_analysis_imp_slv_obs #(spi_slave_obs_item, spi_slave_scoreboard) obs_recv;
    uvm_analysis_port #(spi_slave_seq_item) coverage_ap;
    spi_slave_seq_item mExpectedQ[$];
    bit mNoEventFailed[int unsigned];
    int unsigned mPassCount;
    int unsigned mFailCount;

    function new(string name = "spi_slave_scoreboard", uvm_component parent);
      super.new(name, parent);
      exp_recv = new("exp_recv", this);
      obs_recv = new("obs_recv", this);
      coverage_ap = new("coverage_ap", this);
    endfunction

    function bit expects_no_event(spi_result_e result);
      return (result == SPI_RESULT_RESET_ABORT) || (result == SPI_RESULT_CS_ABORT);
    endfunction

    function spi_slave_seq_item clone_expected(spi_slave_seq_item item);
      spi_slave_seq_item cloned;

      cloned = spi_slave_seq_item::type_id::create("spi_slave_scb_clone");
      cloned.copy(item);
      return cloned;
    endfunction

    function void write_slv_exp(spi_slave_seq_item item);
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
          `uvm_error("SPI_SLV_SCB", "Unexpected no-event window completion")
        end

        return;
      end

      mExpectedQ.push_back(clone_expected(item));
    endfunction

    function void write_slv_obs(spi_slave_obs_item item);
      spi_slave_seq_item expected;

      if (mExpectedQ.size() == 0) begin
        mFailCount++;
        `uvm_error("SPI_SLV_SCB", "Unexpected observed SPI slave result")
        return;
      end

      expected = mExpectedQ[0];

      if (expects_no_event(expected.expected_result)) begin
        mFailCount++;
        mNoEventFailed[expected.item_id] = 1'b1;
        void'(mExpectedQ.pop_front());
        `uvm_error("SPI_SLV_SCB", "Observed result for aborted SPI slave transfer")
        return;
      end

      void'(mExpectedQ.pop_front());

      if (item.rx_data !== expected.mosi_data) begin
        mFailCount++;
        `uvm_error("SPI_SLV_SCB",
                   $sformatf("RX mismatch exp=0x%0h obs=0x%0h",
                             expected.mosi_data, item.rx_data))
        return;
      end

      if (item.miso_data !== expected.tx_data) begin
        mFailCount++;
        `uvm_error("SPI_SLV_SCB",
                   $sformatf("MISO mismatch exp=0x%0h obs=0x%0h",
                             expected.tx_data, item.miso_data))
        return;
      end

      mPassCount++;
      coverage_ap.write(clone_expected(expected));
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      if (mExpectedQ.size() != 0) begin
        mFailCount += mExpectedQ.size();
        `uvm_error("SPI_SLV_SCB",
                   $sformatf("Unmatched expected items=%0d", mExpectedQ.size()))
      end

      `uvm_info("SPI_SLV_SCB",
                $sformatf("Scoreboard pass=%0d fail=%0d", mPassCount, mFailCount),
                UVM_LOW)
    endfunction
  endclass
`endif

`ifndef SPI_TB_SLAVE_ONLY
  class spi_master_coverage extends uvm_subscriber #(spi_master_seq_item);
    `uvm_component_utils(spi_master_coverage)

    bit [7:0] mTxData;
    bit [7:0] mMisoData;
    bit mCpol;
    bit mCpha;
    spi_result_e mResult;
    spi_tick_mode_e mTickMode;
    spi_jitter_mode_e mJitterMode;
    spi_reset_phase_e mResetPhase;

    covergroup cg_spi_master;
      option.per_instance = 1;
      cp_tx_data : coverpoint mTxData {
        bins zero = {8'h00};
        bins ones = {8'hff};
        bins alt[] = {8'h55, 8'haa};
        bins walking[] = {8'h01, 8'h80};
      }
      cp_miso_data : coverpoint mMisoData {
        bins zero = {8'h00};
        bins ones = {8'hff};
        bins alt[] = {8'h55, 8'haa};
        bins other = default;
      }
      cp_cpol : coverpoint mCpol {
        bins low = {0};
        bins high = {1};
      }
      cp_cpha : coverpoint mCpha {
        bins low = {0};
        bins high = {1};
      }
      cp_result : coverpoint mResult {
        bins ok = {SPI_RESULT_OK};
        bins reset_abort = {SPI_RESULT_RESET_ABORT};
        ignore_bins slave_only = {SPI_RESULT_CS_ABORT};
      }
      cp_tick : coverpoint mTickMode {
        bins regular = {SPI_TICK_REGULAR};
        bins irregular = {SPI_TICK_IRREGULAR};
      }
      cp_jitter : coverpoint mJitterMode {
        bins none = {SPI_JITTER_NONE};
        bins early_late = {SPI_JITTER_EARLY_LATE};
      }
      cp_reset : coverpoint mResetPhase {
        bins none = {SPI_RESET_NONE};
        bins transfer = {SPI_RESET_TRANSFER};
        ignore_bins unused = {SPI_RESET_IDLE, SPI_RESET_SELECTED};
      }
      cx_mode : cross cp_cpol, cp_cpha;
    endgroup

    function new(string name = "spi_master_coverage", uvm_component parent);
      super.new(name, parent);
      cg_spi_master = new();
    endfunction

    function void write(spi_master_seq_item t);
      mTxData = t.tx_data;
      mMisoData = t.miso_data;
      mCpol = t.cpol;
      mCpha = t.cpha;
      mResult = t.expected_result;
      mTickMode = t.tick_mode;
      mJitterMode = t.jitter_mode;
      mResetPhase = t.reset_phase;
      cg_spi_master.sample();
    endfunction
  endclass
`endif

`ifndef SPI_TB_MASTER_ONLY
  class spi_slave_coverage extends uvm_subscriber #(spi_slave_seq_item);
    `uvm_component_utils(spi_slave_coverage)

    bit [7:0] mMosiData;
    bit [7:0] mTxData;
    bit mCpol;
    bit mCpha;
    spi_result_e mResult;
    spi_tick_mode_e mTickMode;
    spi_jitter_mode_e mJitterMode;
    spi_reset_phase_e mResetPhase;

    covergroup cg_spi_slave;
      option.per_instance = 1;
      cp_mosi_data : coverpoint mMosiData {
        bins zero = {8'h00};
        bins ones = {8'hff};
        bins alt[] = {8'h55, 8'haa};
        bins other = default;
      }
      cp_tx_data : coverpoint mTxData {
        bins zero = {8'h00};
        bins ones = {8'hff};
        bins alt[] = {8'h55, 8'haa};
        bins other = default;
      }
      cp_cpol : coverpoint mCpol {
        bins low = {0};
        bins high = {1};
      }
      cp_cpha : coverpoint mCpha {
        bins low = {0};
        bins high = {1};
      }
      cp_result : coverpoint mResult {
        bins ok = {SPI_RESULT_OK};
        bins reset_abort = {SPI_RESULT_RESET_ABORT};
        bins cs_abort = {SPI_RESULT_CS_ABORT};
      }
      cp_tick : coverpoint mTickMode {
        bins regular = {SPI_TICK_REGULAR};
        bins irregular = {SPI_TICK_IRREGULAR};
      }
      cp_jitter : coverpoint mJitterMode {
        bins none = {SPI_JITTER_NONE};
        bins early_late = {SPI_JITTER_EARLY_LATE};
      }
      cp_reset : coverpoint mResetPhase {
        bins none = {SPI_RESET_NONE};
        bins transfer = {SPI_RESET_TRANSFER};
        ignore_bins unused = {SPI_RESET_IDLE, SPI_RESET_SELECTED};
      }
      cx_mode : cross cp_cpol, cp_cpha;
    endgroup

    function new(string name = "spi_slave_coverage", uvm_component parent);
      super.new(name, parent);
      cg_spi_slave = new();
    endfunction

    function void write(spi_slave_seq_item t);
      mMosiData = t.mosi_data;
      mTxData = t.tx_data;
      mCpol = t.cpol;
      mCpha = t.cpha;
      mResult = t.expected_result;
      mTickMode = t.tick_mode;
      mJitterMode = t.jitter_mode;
      mResetPhase = t.reset_phase;
      cg_spi_slave.sample();
    endfunction
  endclass
`endif

`ifndef SPI_TB_SLAVE_ONLY
  class spi_master_agent extends uvm_agent;
    `uvm_component_utils(spi_master_agent)

    spi_master_sequencer seqr;
    spi_master_driver driver;
    spi_master_monitor monitor;

    function new(string name = "spi_master_agent", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seqr = spi_master_sequencer::type_id::create("seqr", this);
      driver = spi_master_driver::type_id::create("driver", this);
      monitor = spi_master_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      driver.seq_item_port.connect(seqr.seq_item_export);
    endfunction
  endclass
`endif

`ifndef SPI_TB_MASTER_ONLY
  class spi_slave_agent extends uvm_agent;
    `uvm_component_utils(spi_slave_agent)

    spi_slave_sequencer seqr;
    spi_slave_driver driver;
    spi_slave_monitor monitor;

    function new(string name = "spi_slave_agent", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seqr = spi_slave_sequencer::type_id::create("seqr", this);
      driver = spi_slave_driver::type_id::create("driver", this);
      monitor = spi_slave_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      driver.seq_item_port.connect(seqr.seq_item_export);
    endfunction
  endclass
`endif

`ifndef SPI_TB_SLAVE_ONLY
  class spi_master_env extends uvm_env;
    `uvm_component_utils(spi_master_env)

    spi_master_agent agent;
    spi_master_scoreboard scoreboard;
    spi_master_coverage coverage;

    function new(string name = "spi_master_env", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = spi_master_agent::type_id::create("agent", this);
      scoreboard = spi_master_scoreboard::type_id::create("scoreboard", this);
      coverage = spi_master_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.driver.expected_ap.connect(scoreboard.exp_recv);
      agent.monitor.observed_ap.connect(scoreboard.obs_recv);
      scoreboard.coverage_ap.connect(coverage.analysis_export);
    endfunction
  endclass
`endif

`ifndef SPI_TB_MASTER_ONLY
  class spi_slave_env extends uvm_env;
    `uvm_component_utils(spi_slave_env)

    spi_slave_agent agent;
    spi_slave_scoreboard scoreboard;
    spi_slave_coverage coverage;

    function new(string name = "spi_slave_env", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = spi_slave_agent::type_id::create("agent", this);
      scoreboard = spi_slave_scoreboard::type_id::create("scoreboard", this);
      coverage = spi_slave_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.driver.expected_ap.connect(scoreboard.exp_recv);
      agent.monitor.observed_ap.connect(scoreboard.obs_recv);
      scoreboard.coverage_ap.connect(coverage.analysis_export);
    endfunction
  endclass
`endif

`ifndef SPI_TB_SLAVE_ONLY
  class spi_master_test extends uvm_test;
    `uvm_component_utils(spi_master_test)

    spi_master_env env;
    string seq_name;

    function new(string name = "spi_master_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = spi_master_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      spi_master_sequence seq;

      phase.raise_objection(this);
      seq = spi_master_sequence::type_id::create("seq");
      if (!$value$plusargs("SPI_MASTER_SEQ=%s", seq_name)) begin
        seq_name = "all";
      end

      seq.seq_name = seq_name;
      seq.start(env.agent.seqr);
      #1000ns;
      phase.drop_objection(this);
    endtask
  endclass
`endif

`ifndef SPI_TB_MASTER_ONLY
  class spi_slave_test extends uvm_test;
    `uvm_component_utils(spi_slave_test)

    spi_slave_env env;
    string seq_name;

    function new(string name = "spi_slave_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = spi_slave_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      spi_slave_sequence seq;

      phase.raise_objection(this);
      seq = spi_slave_sequence::type_id::create("seq");
      if (!$value$plusargs("SPI_SLAVE_SEQ=%s", seq_name)) begin
        seq_name = "all";
      end

      seq.seq_name = seq_name;
      seq.start(env.agent.seqr);
      #1000ns;
      phase.drop_objection(this);
    endtask
  endclass
`endif
endpackage

`endif
