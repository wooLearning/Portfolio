`ifndef UART_RX_DRIVER_SV
`define UART_RX_DRIVER_SV

class uart_rx_driver extends uvm_driver #(uart_rx_seq_item);
  `uvm_component_utils(uart_rx_driver)

  uart_rx_vif_t uart_vif;
  uvm_analysis_port #(uart_rx_seq_item) expected_ap;
  int unsigned mNextItemId;

  function new(string name = "uart_rx_driver", uvm_component parent);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
    mNextItemId = 1;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uart_rx_vif_t)::get(this, "", "uart_vif", uart_vif)) begin
      `uvm_fatal("UART_RX_DRV", "Driver failed to get virtual interface")
    end
  endfunction

  function uart_rx_seq_item clone_item(uart_rx_seq_item item);
    uart_rx_seq_item cloned;

    cloned = uart_rx_seq_item::type_id::create("cloned_expected_item");
    cloned.copy(item);
    return cloned;
  endfunction

  function int tick_gap(uart_rx_seq_item item, int tick_index);
    case (item.tick_mode)
      UART_RX_TICK_DIRECT: begin
        tick_gap = 1;
      end

      UART_RX_TICK_INTEGER_DIVIDER: begin
        tick_gap = 2;
      end

      default: begin
        tick_gap = (tick_index % 3 == 0) ? 1 : 2;
      end
    endcase

    case (item.jitter_mode)
      UART_RX_JITTER_EARLY_LATE: begin
        tick_gap = (tick_index[0]) ? tick_gap + 1 : tick_gap;
      end

      UART_RX_JITTER_RANDOM: begin
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

  task automatic pulse_tick(uart_rx_seq_item item, int tick_index);
    wait_clks(tick_gap(item, tick_index));

    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTick16x <= 1'b1;

    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTick16x <= 1'b0;
  endtask

  task automatic drive_ticks(uart_rx_seq_item item, int tick_count);
    for (int i = 0; i < tick_count; i++) begin
      pulse_tick(item, i);
    end
  endtask

  task automatic drive_bit(bit bit_value, uart_rx_seq_item item);
    uart_vif.drv_cb.iRx <= bit_value;
    drive_ticks(item, OVERSAMPLE);
  endtask

  task automatic drive_frame_error_stop_bit(uart_rx_seq_item item);
    uart_vif.drv_cb.iRx <= 1'b0;
    drive_ticks(item, OVERSAMPLE - 1);

    wait_clks(tick_gap(item, OVERSAMPLE - 1));
    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTick16x <= 1'b1;
    uart_vif.drv_cb.iRx      <= 1'b1;

    @(uart_vif.drv_cb);
    uart_vif.drv_cb.iTick16x <= 1'b0;
  endtask

  task automatic drive_idle();
    uart_vif.iRst      <= 1'b0;
    uart_vif.iTick16x  <= 1'b0;
    uart_vif.iRx       <= 1'b1;
  endtask

  task automatic drive_initial_reset();
    uart_vif.iRst      <= 1'b1;
    uart_vif.iTick16x  <= 1'b0;
    uart_vif.iRx       <= 1'b1;

    wait_clks(5);
    uart_vif.drv_cb.iRst <= 1'b0;
    wait_clks(5);
  endtask

  task automatic drive_reset_pulse();
    uart_vif.drv_cb.iRst     <= 1'b1;
    uart_vif.drv_cb.iRx      <= 1'b1;
    uart_vif.drv_cb.iTick16x <= 1'b0;

    wait_clks(4);
    uart_vif.drv_cb.iRst <= 1'b0;
    wait_clks(5);
  endtask

  task automatic drive_expected_done(uart_rx_seq_item item);
    uart_rx_seq_item done_item;

    done_item = clone_item(item);
    done_item.is_window_done = 1'b1;
    expected_ap.write(done_item);
  endtask

  task automatic publish_expected(uart_rx_seq_item item);
    item.item_id = mNextItemId;
    mNextItemId++;
    expected_ap.write(clone_item(item));
  endtask

  task automatic drive_valid_or_error_frame(uart_rx_seq_item item);
    drive_ticks(item, item.idle_ticks);

    uart_vif.drv_cb.iRx <= 1'b0;
    wait_clks(3);
    drive_bit(1'b0, item);

    for (int i = 0; i < DATA_BITS; i++) begin
      drive_bit(item.data[i], item);
    end

    if (item.expected_result == UART_RX_RESULT_FRAME_ERROR) begin
      drive_frame_error_stop_bit(item);
      drive_reset_pulse();
    end
    else begin
      drive_bit(1'b1, item);
    end

    uart_vif.drv_cb.iRx <= 1'b1;
    drive_ticks(item, item.idle_ticks);
  endtask

  task automatic drive_false_start(uart_rx_seq_item item);
    drive_ticks(item, item.idle_ticks);

    uart_vif.drv_cb.iRx <= 1'b0;
    wait_clks(1);

    uart_vif.drv_cb.iRx <= 1'b1;
    drive_ticks(item, OVERSAMPLE * 10);
    drive_expected_done(item);
  endtask

  task automatic drive_reset_abort(uart_rx_seq_item item);
    drive_ticks(item, item.idle_ticks);

    if (item.reset_phase == UART_RX_RESET_IDLE) begin
      drive_reset_pulse();
      drive_expected_done(item);
      return;
    end

    uart_vif.drv_cb.iRx <= 1'b0;
    wait_clks(3);

    if (item.reset_phase == UART_RX_RESET_START) begin
      drive_ticks(item, 4);
      drive_reset_pulse();
      drive_expected_done(item);
      return;
    end

    drive_bit(1'b0, item);

    if (item.reset_phase == UART_RX_RESET_DATA) begin
      for (int i = 0; i < 3; i++) begin
        drive_bit(item.data[i], item);
      end

      drive_reset_pulse();
      drive_expected_done(item);
      return;
    end

    for (int i = 0; i < DATA_BITS; i++) begin
      drive_bit(item.data[i], item);
    end

    uart_vif.drv_cb.iRx <= 1'b1;
    drive_ticks(item, 4);
    drive_reset_pulse();
    drive_expected_done(item);
  endtask

  task automatic drive_timeout_frame(uart_rx_seq_item item);
    drive_ticks(item, item.idle_ticks);

    uart_vif.drv_cb.iRx <= 1'b0;
    wait_clks(3);
    drive_ticks(item, 3);
    wait_clks(TICK_TIMEOUT_CYCLES + 4);
    uart_vif.drv_cb.iRx <= 1'b1;
    drive_ticks(item, item.idle_ticks);
  endtask

  task automatic drive_item(uart_rx_seq_item item);
    publish_expected(item);

    case (item.expected_result)
      UART_RX_RESULT_VALID,
      UART_RX_RESULT_FRAME_ERROR: begin
        drive_valid_or_error_frame(item);
      end

      UART_RX_RESULT_FALSE_START: begin
        drive_false_start(item);
      end

      UART_RX_RESULT_TIMEOUT: begin
        drive_timeout_frame(item);
      end

      default: begin
        drive_reset_abort(item);
      end
    endcase
  endtask

  task run_phase(uvm_phase phase);
    uart_rx_seq_item item;

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
