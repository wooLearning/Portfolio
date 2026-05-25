`ifndef UART_TX_OBS_ITEM_SV
`define UART_TX_OBS_ITEM_SV

class uart_tx_obs_item extends uvm_sequence_item;
  logic [DATA_BITS-1:0] data;
  bit                   stop_bit;
  bit                   saw_done;

  `uvm_object_utils_begin(uart_tx_obs_item)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(stop_bit, UVM_ALL_ON)
    `uvm_field_int(saw_done, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_tx_obs_item");
    super.new(name);
    data     = '0;
    stop_bit = 1'b0;
    saw_done = 1'b0;
  endfunction
endclass

`endif
