`ifndef UART_RX_MONITOR_SV
`define UART_RX_MONITOR_SV

class uart_rx_monitor extends uvm_monitor;
  `uvm_component_utils(uart_rx_monitor)

  uart_rx_vif_t uart_vif;
  uvm_analysis_port #(uart_rx_obs_item) observed_ap;
  uvm_analysis_port #(uart_rx_serial_item) serial_ap;

  function new(string name = "uart_rx_monitor", uvm_component parent);
    super.new(name, parent);
    observed_ap = new("observed_ap", this);
    serial_ap   = new("serial_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uart_rx_vif_t)::get(this, "", "uart_vif", uart_vif)) begin
      `uvm_fatal("UART_RX_MON", "Monitor failed to get virtual interface")
    end
  endfunction

  task automatic wait_ticks_or_reset(int tick_count, output bit reset_seen);
    int tick_seen;
    int no_tick_seen;

    reset_seen = 1'b0;
    tick_seen  = 0;
    no_tick_seen = 0;

    while (tick_seen < tick_count) begin
      @(uart_vif.mon_cb);

      if (uart_vif.mon_cb.iRst) begin
        reset_seen = 1'b1;
        return;
      end

      if (uart_vif.mon_cb.iTick16x) begin
        tick_seen++;
        no_tick_seen = 0;
      end
      else if (TICK_TIMEOUT_CYCLES > 0) begin
        no_tick_seen++;

        if (no_tick_seen > (TICK_TIMEOUT_CYCLES + 4)) begin
          reset_seen = 1'b1;
          return;
        end
      end
    end
  endtask

  task automatic monitor_dut_outputs();
    uart_rx_obs_item item;

    forever begin
      @(uart_vif.mon_cb);

      if (uart_vif.mon_cb.iRst) begin
        continue;
      end

      if (uart_vif.mon_cb.oRxValid || uart_vif.mon_cb.oFrameError) begin
        item = uart_rx_obs_item::type_id::create("uart_rx_observed_item");
        item.data = uart_vif.mon_cb.oRxData;

        if (uart_vif.mon_cb.oFrameError) begin
          item.result = UART_RX_RESULT_FRAME_ERROR;
        end
        else begin
          item.result = UART_RX_RESULT_VALID;
        end

        observed_ap.write(item);
      end
    end
  endtask

  task automatic decode_serial_frame();
    uart_rx_serial_item item;
    bit reset_seen;

    item = uart_rx_serial_item::type_id::create("uart_rx_serial_item");

    wait_ticks_or_reset(OVERSAMPLE / 2, reset_seen);
    if (reset_seen) begin
      return;
    end

    if (uart_vif.mon_cb.iRx) begin
      item.result = UART_RX_RESULT_FALSE_START;
      serial_ap.write(item);
      return;
    end

    for (int i = 0; i < DATA_BITS; i++) begin
      wait_ticks_or_reset(OVERSAMPLE, reset_seen);
      if (reset_seen) begin
        return;
      end

      item.data[i] = uart_vif.mon_cb.iRx;
    end

    wait_ticks_or_reset(OVERSAMPLE, reset_seen);
    if (reset_seen) begin
      return;
    end

    item.stop_bit = uart_vif.mon_cb.iRx;

    if (item.stop_bit) begin
      item.result = UART_RX_RESULT_VALID;
    end
    else begin
      item.result = UART_RX_RESULT_FRAME_ERROR;
    end

    serial_ap.write(item);
  endtask

  task automatic monitor_serial_line();
    bit prev_rx;

    prev_rx = 1'b1;

    forever begin
      @(uart_vif.mon_cb);

      if (uart_vif.mon_cb.iRst) begin
        prev_rx = 1'b1;
        continue;
      end

      if (prev_rx && !uart_vif.mon_cb.iRx) begin
        decode_serial_frame();
        prev_rx = uart_vif.mon_cb.iRx;
      end
      else begin
        prev_rx = uart_vif.mon_cb.iRx;
      end
    end
  endtask

  task run_phase(uvm_phase phase);
    fork
      monitor_dut_outputs();
      monitor_serial_line();
    join
  endtask
endclass

`endif
