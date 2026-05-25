`ifndef UART_RX_TEST_SV
`define UART_RX_TEST_SV

class uart_rx_test extends uvm_test;
  `uvm_component_utils(uart_rx_test)

  uart_rx_env env;

  function new(string name = "uart_rx_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_rx_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    string seq_name;

    phase.raise_objection(this);

    if (!$value$plusargs("UART_RX_SEQ=%s", seq_name)) begin
      seq_name = "all";
    end

    case (seq_name)
      "smoke": begin
        uart_rx_smoke_sequence seq;
        seq = uart_rx_smoke_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      "directed": begin
        uart_rx_directed_pattern_sequence seq;
        seq = uart_rx_directed_pattern_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      "error": begin
        uart_rx_error_sequence seq;
        seq = uart_rx_error_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      "reset": begin
        uart_rx_reset_sequence seq;
        seq = uart_rx_reset_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      "timeout": begin
        uart_rx_timeout_sequence seq;
        seq = uart_rx_timeout_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      "jitter": begin
        uart_rx_jitter_sequence seq;
        seq = uart_rx_jitter_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      "corner": begin
        uart_rx_corner_sequence seq;
        seq = uart_rx_corner_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      "byte_sweep": begin
        uart_rx_byte_sweep_sequence seq;
        seq = uart_rx_byte_sweep_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      "full_random": begin
        uart_rx_full_random_sequence seq;
        seq = uart_rx_full_random_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end

      default: begin
        uart_rx_all_sequence seq;
        seq = uart_rx_all_sequence::type_id::create("seq");
        seq.start(env.agt.sequencer);
      end
    endcase

    repeat (OVERSAMPLE * 20) @(posedge env.agt.monitor.uart_vif.iClk);
    phase.drop_objection(this);
  endtask
endclass

`endif
