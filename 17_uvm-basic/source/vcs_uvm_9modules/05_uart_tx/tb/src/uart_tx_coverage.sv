`ifndef UART_TX_COVERAGE_SV
`define UART_TX_COVERAGE_SV

class uart_tx_coverage extends uvm_subscriber #(uart_tx_seq_item);
  `uvm_component_utils(uart_tx_coverage)

  uart_tx_seq_item item;

  covergroup uart_tx_cg;
    option.per_instance = 1;

    cp_data_pattern : coverpoint item.data {
      bins zero        = {8'h00};
      bins all_ones    = {8'hFF};
      bins alternating = {8'h55, 8'hAA};
      bins walking_1   = {8'h01, 8'h02, 8'h04, 8'h08,
                          8'h10, 8'h20, 8'h40, 8'h80};
      bins walking_0   = {8'hFE, 8'hFD, 8'hFB, 8'hF7,
                          8'hEF, 8'hDF, 8'hBF, 8'h7F};
      bins randomish   = default;
    }

    cp_handshake : coverpoint item.attempt_while_busy {
      bins accepted_only = {0};
      bins busy_attempt  = {1};
    }

    cp_result : coverpoint item.expected_result {
      bins complete    = {UART_TX_RESULT_COMPLETE};
      bins ignored     = {UART_TX_RESULT_IGNORED};
      bins reset_abort = {UART_TX_RESULT_RESET_ABORT};
      bins timeout     = {UART_TX_RESULT_TIMEOUT_ABORT};
    }

    cp_reset_phase : coverpoint item.reset_phase {
      bins none  = {UART_TX_RESET_NONE};
      bins idle  = {UART_TX_RESET_IDLE};
      bins start = {UART_TX_RESET_START};
      bins data  = {UART_TX_RESET_DATA};
      bins stop  = {UART_TX_RESET_STOP};
    }

    cp_tick_mode : coverpoint item.tick_mode {
      bins direct            = {UART_TX_TICK_DIRECT};
      bins integer_divider   = {UART_TX_TICK_INTEGER_DIVIDER};
      bins phase_accumulator = {UART_TX_TICK_PHASE_ACCUMULATOR};
    }

    cp_jitter_mode : coverpoint item.jitter_mode {
      bins none       = {UART_TX_JITTER_NONE};
      bins early_late = {UART_TX_JITTER_EARLY_LATE};
      bins random     = {UART_TX_JITTER_RANDOM};
    }
  endgroup

  function new(string name = "uart_tx_coverage", uvm_component parent);
    super.new(name, parent);
    uart_tx_cg = new();
  endfunction

  function void write(uart_tx_seq_item t);
    item = t;
    uart_tx_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("UART_TX_COV",
              $sformatf("Functional coverage = %0.2f%%",
                        uart_tx_cg.get_coverage()),
              UVM_LOW)
  endfunction
endclass

`endif
