`ifndef UART_RX_AGENT_SV
`define UART_RX_AGENT_SV

class uart_rx_agent extends uvm_agent;
  `uvm_component_utils(uart_rx_agent)

  uart_rx_sequencer sequencer;
  uart_rx_driver    driver;
  uart_rx_monitor   monitor;

  function new(string name = "uart_rx_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    sequencer = uart_rx_sequencer::type_id::create("sequencer", this);
    driver    = uart_rx_driver::type_id::create("driver", this);
    monitor   = uart_rx_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

`endif
