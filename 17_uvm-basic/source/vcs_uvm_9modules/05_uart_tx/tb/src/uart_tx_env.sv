`ifndef UART_TX_ENV_SV
`define UART_TX_ENV_SV

class uart_tx_env extends uvm_env;
  `uvm_component_utils(uart_tx_env)

  uart_tx_agent      agt;
  uart_tx_scoreboard scb;
  uart_tx_coverage   cov;

  function new(string name = "uart_tx_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agt = uart_tx_agent::type_id::create("agt", this);
    scb = uart_tx_scoreboard::type_id::create("scb", this);
    cov = uart_tx_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.driver.expected_ap.connect(scb.exp_recv);
    agt.monitor.observed_ap.connect(scb.obs_recv);
    scb.coverage_ap.connect(cov.analysis_export);
  endfunction
endclass

`endif
