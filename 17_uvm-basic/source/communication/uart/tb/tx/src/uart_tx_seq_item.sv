`ifndef UART_TX_SEQ_ITEM_SV
`define UART_TX_SEQ_ITEM_SV

class uart_tx_seq_item extends uvm_sequence_item;
  rand logic [DATA_BITS-1:0]     data;
  rand logic [DATA_BITS-1:0]     busy_data;
  rand bit                       attempt_while_busy;
  rand uart_tx_result_e          expected_result;
  rand uart_tx_reset_phase_e     reset_phase;
  rand uart_tx_tick_mode_e       tick_mode;
  rand uart_tx_jitter_mode_e     jitter_mode;
  rand int unsigned              idle_ticks;

  int unsigned item_id;
  bit          is_window_done;

  constraint idle_ticks_c {
    idle_ticks inside {[4:64]};
  }

  `uvm_object_utils_begin(uart_tx_seq_item)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(busy_data, UVM_ALL_ON)
    `uvm_field_int(attempt_while_busy, UVM_ALL_ON)
    `uvm_field_enum(uart_tx_result_e, expected_result, UVM_ALL_ON)
    `uvm_field_enum(uart_tx_reset_phase_e, reset_phase, UVM_ALL_ON)
    `uvm_field_enum(uart_tx_tick_mode_e, tick_mode, UVM_ALL_ON)
    `uvm_field_enum(uart_tx_jitter_mode_e, jitter_mode, UVM_ALL_ON)
    `uvm_field_int(idle_ticks, UVM_ALL_ON)
    `uvm_field_int(item_id, UVM_ALL_ON)
    `uvm_field_int(is_window_done, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_tx_seq_item");
    super.new(name);
    data               = '0;
    busy_data          = '0;
    attempt_while_busy = 1'b0;
    expected_result    = UART_TX_RESULT_COMPLETE;
    reset_phase        = UART_TX_RESET_NONE;
    tick_mode          = UART_TX_TICK_DIRECT;
    jitter_mode        = UART_TX_JITTER_NONE;
    idle_ticks         = 16;
    item_id            = 0;
    is_window_done     = 1'b0;
  endfunction

  function void do_copy(uvm_object rhs);
    uart_tx_seq_item rhs_item;

    if (!$cast(rhs_item, rhs)) begin
      `uvm_fatal("UART_TX_ITEM", "do_copy cast failed")
    end

    super.do_copy(rhs);
    data               = rhs_item.data;
    busy_data          = rhs_item.busy_data;
    attempt_while_busy = rhs_item.attempt_while_busy;
    expected_result    = rhs_item.expected_result;
    reset_phase        = rhs_item.reset_phase;
    tick_mode          = rhs_item.tick_mode;
    jitter_mode        = rhs_item.jitter_mode;
    idle_ticks         = rhs_item.idle_ticks;
    item_id            = rhs_item.item_id;
    is_window_done     = rhs_item.is_window_done;
  endfunction
endclass

`endif
