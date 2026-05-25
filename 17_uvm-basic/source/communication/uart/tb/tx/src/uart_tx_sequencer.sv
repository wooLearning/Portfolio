`ifndef UART_TX_SEQUENCER_SV
`define UART_TX_SEQUENCER_SV

class uart_tx_sequencer extends uvm_sequencer #(uart_tx_seq_item);
  `uvm_component_utils(uart_tx_sequencer)

  function new(string name = "uart_tx_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif
