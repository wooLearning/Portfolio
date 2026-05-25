`ifndef UART_RX_COVERAGE_SV
`define UART_RX_COVERAGE_SV

class uart_rx_coverage extends uvm_subscriber #(uart_rx_seq_item);
  `uvm_component_utils(uart_rx_coverage)

  uart_rx_seq_item item;

  covergroup uart_rx_cg;
    option.per_instance = 1;

    cp_data_pattern : coverpoint item.data {
      bins zero       = {8'h00};
      bins all_ones   = {8'hFF};
      bins alternating = {8'h55, 8'hAA};
      bins walking_1  = {8'h01, 8'h02, 8'h04, 8'h08,
                         8'h10, 8'h20, 8'h40, 8'h80};
      bins walking_0  = {8'hFE, 8'hFD, 8'hFB, 8'hF7,
                         8'hEF, 8'hDF, 8'hBF, 8'h7F};
      bins randomish  = default;
    }

    cp_frame_result : coverpoint item.expected_result {
      bins valid       = {UART_RX_RESULT_VALID};
      bins frame_error = {UART_RX_RESULT_FRAME_ERROR};
      bins false_start = {UART_RX_RESULT_FALSE_START};
      bins reset_abort = {UART_RX_RESULT_RESET_ABORT};
      bins timeout     = {UART_RX_RESULT_TIMEOUT};
    }

    cp_reset_phase : coverpoint item.reset_phase {
      bins none  = {UART_RX_RESET_NONE};
      bins idle  = {UART_RX_RESET_IDLE};
      bins start = {UART_RX_RESET_START};
      bins data  = {UART_RX_RESET_DATA};
      bins stop  = {UART_RX_RESET_STOP};
    }

    cp_tick_mode : coverpoint item.tick_mode {
      bins direct            = {UART_RX_TICK_DIRECT};
      bins integer_divider   = {UART_RX_TICK_INTEGER_DIVIDER};
      bins phase_accumulator = {UART_RX_TICK_PHASE_ACCUMULATOR};
    }

    cp_jitter_mode : coverpoint item.jitter_mode {
      bins none       = {UART_RX_JITTER_NONE};
      bins early_late = {UART_RX_JITTER_EARLY_LATE};
      bins random     = {UART_RX_JITTER_RANDOM};
    }
  endgroup

  function new(string name = "uart_rx_coverage", uvm_component parent);
    super.new(name, parent);
    uart_rx_cg = new();
  endfunction

  function void write(uart_rx_seq_item t);
    item = t;
    uart_rx_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("UART_RX_COV",
              $sformatf("Functional coverage = %0.2f%%",
                        uart_rx_cg.get_coverage()),
              UVM_LOW)
  endfunction
endclass

`endif
