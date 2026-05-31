`ifndef UART_RX_ENV_SV
`define UART_RX_ENV_SV

class uart_rx_env extends uvm_env;
  `uvm_component_utils(uart_rx_env)

  uart_rx_agent      agt;
  uart_rx_scoreboard scb;
  uart_rx_coverage   cov;

  function new(string name = "uart_rx_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agt = uart_rx_agent::type_id::create("agt", this);
    scb = uart_rx_scoreboard::type_id::create("scb", this);
    cov = uart_rx_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.driver.expected_ap.connect(scb.exp_recv);
    agt.monitor.observed_ap.connect(scb.obs_recv);
    agt.monitor.serial_ap.connect(scb.ser_recv);
    scb.coverage_ap.connect(cov.analysis_export);
  endfunction
endclass

`endif
