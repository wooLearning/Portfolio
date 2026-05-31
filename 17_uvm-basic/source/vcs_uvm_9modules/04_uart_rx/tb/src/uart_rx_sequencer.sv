`ifndef UART_RX_SEQUENCER_SV
`define UART_RX_SEQUENCER_SV

class uart_rx_sequencer extends uvm_sequencer #(uart_rx_seq_item);
  `uvm_component_utils(uart_rx_sequencer)

  function new(string name = "uart_rx_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif
