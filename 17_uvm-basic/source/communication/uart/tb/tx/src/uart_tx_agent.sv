`ifndef UART_TX_AGENT_SV
`define UART_TX_AGENT_SV

class uart_tx_agent extends uvm_agent;
  `uvm_component_utils(uart_tx_agent)

  uart_tx_sequencer sequencer;
  uart_tx_driver    driver;
  uart_tx_monitor   monitor;

  function new(string name = "uart_tx_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    sequencer = uart_tx_sequencer::type_id::create("sequencer", this);
    driver    = uart_tx_driver::type_id::create("driver", this);
    monitor   = uart_tx_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

`endif
