`ifndef UART_RX_SEQ_ITEM_SV
`define UART_RX_SEQ_ITEM_SV

class uart_rx_seq_item extends uvm_sequence_item;
  rand logic [DATA_BITS-1:0]     data;
  rand uart_rx_result_e          expected_result;
  rand uart_rx_reset_phase_e     reset_phase;
  rand uart_rx_tick_mode_e       tick_mode;
  rand uart_rx_jitter_mode_e     jitter_mode;
  rand int unsigned              idle_ticks;

  int unsigned item_id;
  bit          is_window_done;

  constraint idle_ticks_c {
    idle_ticks inside {[4:64]};
  }

  `uvm_object_utils_begin(uart_rx_seq_item)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_enum(uart_rx_result_e, expected_result, UVM_ALL_ON)
    `uvm_field_enum(uart_rx_reset_phase_e, reset_phase, UVM_ALL_ON)
    `uvm_field_enum(uart_rx_tick_mode_e, tick_mode, UVM_ALL_ON)
    `uvm_field_enum(uart_rx_jitter_mode_e, jitter_mode, UVM_ALL_ON)
    `uvm_field_int(idle_ticks, UVM_ALL_ON)
    `uvm_field_int(item_id, UVM_ALL_ON)
    `uvm_field_int(is_window_done, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_rx_seq_item");
    super.new(name);
    data            = '0;
    expected_result = UART_RX_RESULT_VALID;
    reset_phase     = UART_RX_RESET_NONE;
    tick_mode       = UART_RX_TICK_DIRECT;
    jitter_mode     = UART_RX_JITTER_NONE;
    idle_ticks      = 16;
    item_id         = 0;
    is_window_done  = 1'b0;
  endfunction

  function void do_copy(uvm_object rhs);
    uart_rx_seq_item rhs_item;

    if (!$cast(rhs_item, rhs)) begin
      `uvm_fatal("UART_RX_ITEM", "do_copy cast failed")
    end

    super.do_copy(rhs);
    data            = rhs_item.data;
    expected_result = rhs_item.expected_result;
    reset_phase     = rhs_item.reset_phase;
    tick_mode       = rhs_item.tick_mode;
    jitter_mode     = rhs_item.jitter_mode;
    idle_ticks      = rhs_item.idle_ticks;
    item_id         = rhs_item.item_id;
    is_window_done  = rhs_item.is_window_done;
  endfunction
endclass

`endif
