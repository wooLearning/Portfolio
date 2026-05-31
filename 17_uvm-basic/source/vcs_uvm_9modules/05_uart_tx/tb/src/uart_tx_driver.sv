`ifndef UART_TX_DRIVER_SV
`define UART_TX_DRIVER_SV

class uart_tx_driver extends uvm_driver #(uart_tx_seq_item);
  `uvm_component_utils(uart_tx_driver)

  uart_tx_vif_t uart_vif;
  uvm_analysis_port #(uart_tx_seq_item) expected_ap;
  int unsigned mNextItemId;

  function new(string name = "uart_tx_driver", uvm_component parent);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
    mNextItemId = 1;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uart_tx_vif_t)::get(this, "", "uart_vif", uart_vif)) begin
      `uvm_fatal("UART_TX_DRV", "Driver failed to get virtual interface")
    end
  endfunction

  function uart_tx_seq_item clone_item(uart_tx_seq_item item);
    uart_tx_seq_item cloned;

    cloned = uart_tx_seq_item::type_id::create("cloned_expected_item");
    cloned.copy(item);
    return cloned;
  endfunction

  function int tick_gap(uart_tx_seq_item item, int tick_index);
    case (item.tick_mode)
      UART_TX_TICK_DIRECT: begin
        tick_gap = 1;
      end

      UART_TX_TICK_INTEGER_DIVIDER: begin
        tick_gap = 2;
      end

      default: begin
        tick_gap = (tick_index % 3 == 0) ? 1 : 2;
      end
    endcase

    case (item.jitter_mode)
      UART_TX_JITTER_EARLY_LATE: begin
        tick_gap = (tick_index[0]) ? tick_gap + 1 : tick_gap;
      end

      UART_TX_JITTER_RANDOM: begin
        tick_gap = tick_gap + $urandom_range(0, 1);
      end

      default: begin
      end
    endcase
  endfunction

  task automatic wait_clks(int cycles);
    repeat (cycles) begin
      @(uart_vif.drv_cb);
      uart_vif.drv_cb.iTick16x <= 1'b0;
    end
  endtask

  task automatic pulse_tick(uart_tx_seq_item item, int tick_index);
    wait_clks(tick_gap(item, tick_index));

    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTick16x <= 1'b1;

    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTick16x <= 1'b0;
  endtask

  task automatic drive_ticks(uart_tx_seq_item item, int tick_count);
    for (int i = 0; i < tick_count; i++) begin
      pulse_tick(item, i);
    end
  endtask

  task automatic drive_idle();
    uart_vif.iRst     <= 1'b0;
    uart_vif.iTick16x <= 1'b0;
    uart_vif.iTxData  <= '0;
    uart_vif.iTxValid <= 1'b0;
  endtask

  task automatic drive_initial_reset();
    uart_vif.iRst     <= 1'b1;
    uart_vif.iTick16x <= 1'b0;
    uart_vif.iTxData  <= '0;
    uart_vif.iTxValid <= 1'b0;

    wait_clks(5);
    uart_vif.drv_cb.iRst <= 1'b0;
    wait_clks(5);
  endtask

  task automatic drive_reset_pulse();
    uart_vif.drv_cb.iRst     <= 1'b1;
    uart_vif.drv_cb.iTick16x <= 1'b0;
    uart_vif.drv_cb.iTxValid <= 1'b0;

    wait_clks(4);
    uart_vif.drv_cb.iRst <= 1'b0;
    wait_clks(5);
  endtask

  task automatic publish_expected(uart_tx_seq_item item);
    item.item_id = mNextItemId;
    mNextItemId++;
    expected_ap.write(clone_item(item));
  endtask

  task automatic publish_expected_done(uart_tx_seq_item item);
    uart_tx_seq_item done_item;

    done_item = clone_item(item);
    done_item.is_window_done = 1'b1;
    expected_ap.write(done_item);
  endtask

  task automatic publish_ignored_window(uart_tx_seq_item item);
    uart_tx_seq_item ignored_item;

    ignored_item = uart_tx_seq_item::type_id::create("ignored_expected_item");
    ignored_item.copy(item);
    ignored_item.data            = item.busy_data;
    ignored_item.expected_result = UART_TX_RESULT_IGNORED;
    ignored_item.item_id         = mNextItemId;
    mNextItemId++;
    expected_ap.write(clone_item(ignored_item));

    drive_ticks(item, OVERSAMPLE * (DATA_BITS + 2));
    publish_expected_done(ignored_item);
  endtask

  task automatic drive_legal_request(uart_tx_seq_item item, bit publish_accept = 1'b1);
    wait (uart_vif.oTxReady === 1'b1);
    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTxData  <= item.data;
    uart_vif.drv_cb.iTxValid <= 1'b1;

    @(uart_vif.drv_cb);

    if (publish_accept && uart_vif.drv_cb.oTxReady) begin
      publish_expected(item);
    end

    uart_vif.drv_cb.iTxValid <= 1'b0;
  endtask

  task automatic drive_busy_attempt(uart_tx_seq_item item);
    wait (uart_vif.oTxBusy === 1'b1);
    drive_ticks(item, 2);

    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTxData  <= item.busy_data;
    uart_vif.drv_cb.iTxValid <= 1'b1;

    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTxValid <= 1'b0;
  endtask

  task automatic drive_to_completion(uart_tx_seq_item item);
    drive_ticks(item, OVERSAMPLE * (DATA_BITS + 2));
    drive_ticks(item, item.idle_ticks);
  endtask

  task automatic drive_reset_abort(uart_tx_seq_item item);
    drive_ticks(item, item.idle_ticks);

    if (item.reset_phase == UART_TX_RESET_IDLE) begin
      publish_expected(item);
      drive_reset_pulse();
      publish_expected_done(item);
      return;
    end

    drive_legal_request(item);

    if (item.reset_phase == UART_TX_RESET_START) begin
      drive_ticks(item, 4);
      drive_reset_pulse();
      publish_expected_done(item);
      return;
    end

    if (item.reset_phase == UART_TX_RESET_DATA) begin
      drive_ticks(item, OVERSAMPLE + (OVERSAMPLE * 3));
      drive_reset_pulse();
      publish_expected_done(item);
      return;
    end

    drive_ticks(item, OVERSAMPLE * (DATA_BITS + 1));
    drive_reset_pulse();
    publish_expected_done(item);
  endtask

  task automatic drive_timeout_abort(uart_tx_seq_item item);
    drive_ticks(item, item.idle_ticks);
    drive_legal_request(item);
    drive_ticks(item, 3);
    wait_clks(TICK_TIMEOUT_CYCLES + 4);
    wait_clks(4);
    publish_expected_done(item);
  endtask

  task automatic drive_item(uart_tx_seq_item item);
    if (item.expected_result == UART_TX_RESULT_RESET_ABORT) begin
      drive_reset_abort(item);
      return;
    end

    if (item.expected_result == UART_TX_RESULT_TIMEOUT_ABORT) begin
      drive_timeout_abort(item);
      return;
    end

    drive_ticks(item, item.idle_ticks);
    drive_legal_request(item);

    if (item.attempt_while_busy) begin
      drive_busy_attempt(item);
    end

    drive_to_completion(item);

    if (item.attempt_while_busy) begin
      publish_ignored_window(item);
    end
  endtask

  task run_phase(uvm_phase phase);
    uart_tx_seq_item item;

    drive_idle();
    drive_initial_reset();

    forever begin
      seq_item_port.get_next_item(item);

      if (uart_vif.iRst) begin
        drive_idle();
        wait (uart_vif.iRst === 1'b0);
      end

      drive_item(item);
      seq_item_port.item_done();
    end
  endtask
endclass

`endif
