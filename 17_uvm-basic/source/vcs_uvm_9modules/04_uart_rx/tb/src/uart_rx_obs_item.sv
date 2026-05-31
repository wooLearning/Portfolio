`ifndef UART_RX_OBS_ITEM_SV
`define UART_RX_OBS_ITEM_SV

class uart_rx_obs_item extends uvm_sequence_item;
  logic [DATA_BITS-1:0] data;
  uart_rx_result_e      result;

  `uvm_object_utils_begin(uart_rx_obs_item)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_enum(uart_rx_result_e, result, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_rx_obs_item");
    super.new(name);
    data   = '0;
    result = UART_RX_RESULT_VALID;
  endfunction
endclass

`endif
