`ifndef UART_TX_MONITOR_SV
`define UART_TX_MONITOR_SV

class uart_tx_monitor extends uvm_monitor;
  `uvm_component_utils(uart_tx_monitor)

  uart_tx_vif_t uart_vif;
  uvm_analysis_port #(uart_tx_obs_item) observed_ap;

  function new(string name = "uart_tx_monitor", uvm_component parent);
    super.new(name, parent);
    observed_ap = new("observed_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uart_tx_vif_t)::get(this, "", "uart_vif", uart_vif)) begin
      `uvm_fatal("UART_TX_MON", "Monitor failed to get virtual interface")
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

  task automatic wait_done_window(int tick_count, output bit reset_seen, output bit saw_done);
    int tick_seen;
    int no_tick_seen;

    reset_seen = 1'b0;
    saw_done   = 1'b0;
    tick_seen  = 0;
    no_tick_seen = 0;

    while (tick_seen < tick_count) begin
      @(uart_vif.mon_cb);

      if (uart_vif.mon_cb.iRst) begin
        reset_seen = 1'b1;
        return;
      end

      if (uart_vif.mon_cb.oTxDone) begin
        saw_done = 1'b1;
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

  task automatic decode_frame();
    uart_tx_obs_item item;
    bit reset_seen;
    bit saw_done;

    item = uart_tx_obs_item::type_id::create("uart_tx_observed_item");

    wait_ticks_or_reset(OVERSAMPLE + (OVERSAMPLE / 2), reset_seen);
    if (reset_seen) begin
      return;
    end

    item.data[0] = uart_vif.mon_cb.oTx;

    for (int i = 1; i < DATA_BITS; i++) begin
      wait_ticks_or_reset(OVERSAMPLE, reset_seen);
      if (reset_seen) begin
        return;
      end

      item.data[i] = uart_vif.mon_cb.oTx;
    end

    wait_ticks_or_reset(OVERSAMPLE, reset_seen);
    if (reset_seen) begin
      return;
    end

    item.stop_bit = uart_vif.mon_cb.oTx;

    wait_done_window((OVERSAMPLE / 2) + 2, reset_seen, saw_done);
    if (reset_seen) begin
      return;
    end

    item.saw_done = saw_done;
    observed_ap.write(item);
  endtask

  task run_phase(uvm_phase phase);
    bit prev_tx;

    prev_tx = 1'b1;

    forever begin
      @(uart_vif.mon_cb);

      if (uart_vif.mon_cb.iRst) begin
        prev_tx = 1'b1;
        continue;
      end

      if (prev_tx && !uart_vif.mon_cb.oTx) begin
        decode_frame();
        prev_tx = uart_vif.mon_cb.oTx;
      end
      else begin
        prev_tx = uart_vif.mon_cb.oTx;
      end
    end
  endtask
endclass

`endif
