`ifndef UART_RX_SERIAL_ITEM_SV
`define UART_RX_SERIAL_ITEM_SV

class uart_rx_serial_item extends uvm_sequence_item;
  logic [DATA_BITS-1:0] data;
  bit                   stop_bit;
  uart_rx_result_e      result;

  `uvm_object_utils_begin(uart_rx_serial_item)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(stop_bit, UVM_ALL_ON)
    `uvm_field_enum(uart_rx_result_e, result, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_rx_serial_item");
    super.new(name);
    data     = '0;
    stop_bit = 1'b1;
    result   = UART_RX_RESULT_VALID;
  endfunction
endclass

`endif
