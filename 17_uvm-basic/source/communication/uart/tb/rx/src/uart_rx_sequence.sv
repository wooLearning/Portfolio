`ifndef UART_RX_SEQUENCE_SV
`define UART_RX_SEQUENCE_SV

class uart_rx_base_sequence extends uvm_sequence #(uart_rx_seq_item);
  `uvm_object_utils(uart_rx_base_sequence)

  function new(string name = "uart_rx_base_sequence");
    super.new(name);
  endfunction

  task automatic send_frame(
    logic [DATA_BITS-1:0] data,
    uart_rx_result_e      expected_result = UART_RX_RESULT_VALID,
    uart_rx_reset_phase_e reset_phase     = UART_RX_RESET_NONE,
    uart_rx_tick_mode_e   tick_mode       = UART_RX_TICK_DIRECT,
    uart_rx_jitter_mode_e jitter_mode     = UART_RX_JITTER_NONE,
    int unsigned          idle_ticks      = 16
  );
    uart_rx_seq_item item;

    item = uart_rx_seq_item::type_id::create("uart_rx_item");
    start_item(item);

    item.data            = data;
    item.expected_result = expected_result;
    item.reset_phase     = reset_phase;
    item.tick_mode       = tick_mode;
    item.jitter_mode     = jitter_mode;
    item.idle_ticks      = idle_ticks;
    item.is_window_done  = 1'b0;

    finish_item(item);
  endtask

  virtual task body();
  endtask
endclass

class uart_rx_smoke_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_smoke_sequence)

  function new(string name = "uart_rx_smoke_sequence");
    super.new(name);
  endfunction

  task body();
    send_frame(8'hA5);
  endtask
endclass

class uart_rx_directed_pattern_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_directed_pattern_sequence)

  function new(string name = "uart_rx_directed_pattern_sequence");
    super.new(name);
  endfunction

  task body();
    logic [DATA_BITS-1:0] walk_one;

    send_frame(8'h00);
    send_frame(8'hFF);
    send_frame(8'h55);
    send_frame(8'hAA);

    for (int i = 0; i < DATA_BITS; i++) begin
      walk_one = '0;
      walk_one[i] = 1'b1;
      send_frame(walk_one);
      send_frame(~walk_one);
    end
  endtask
endclass

class uart_rx_error_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_error_sequence)

  function new(string name = "uart_rx_error_sequence");
    super.new(name);
  endfunction

  task body();
    send_frame(8'h3C, UART_RX_RESULT_FRAME_ERROR);
    send_frame(8'h00, UART_RX_RESULT_FALSE_START);
  endtask
endclass

class uart_rx_reset_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_reset_sequence)

  function new(string name = "uart_rx_reset_sequence");
    super.new(name);
  endfunction

  task body();
    send_frame(8'h00, UART_RX_RESULT_RESET_ABORT, UART_RX_RESET_IDLE);
    send_frame(8'h11, UART_RX_RESULT_RESET_ABORT, UART_RX_RESET_START);
    send_frame(8'h22, UART_RX_RESULT_RESET_ABORT, UART_RX_RESET_DATA);
    send_frame(8'h33, UART_RX_RESULT_RESET_ABORT, UART_RX_RESET_STOP);
  endtask
endclass

class uart_rx_timeout_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_timeout_sequence)

  function new(string name = "uart_rx_timeout_sequence");
    super.new(name);
  endfunction

  task body();
    send_frame(8'h00, UART_RX_RESULT_TIMEOUT);
  endtask
endclass

class uart_rx_jitter_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_jitter_sequence)

  function new(string name = "uart_rx_jitter_sequence");
    super.new(name);
  endfunction

  task body();
    send_frame(8'h5A, UART_RX_RESULT_VALID, UART_RX_RESET_NONE,
               UART_RX_TICK_DIRECT, UART_RX_JITTER_EARLY_LATE);
    send_frame(8'hC3, UART_RX_RESULT_VALID, UART_RX_RESET_NONE,
               UART_RX_TICK_PHASE_ACCUMULATOR, UART_RX_JITTER_RANDOM);
    send_frame(8'h96, UART_RX_RESULT_VALID, UART_RX_RESET_NONE,
               UART_RX_TICK_INTEGER_DIVIDER, UART_RX_JITTER_NONE);
  endtask
endclass

class uart_rx_corner_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_corner_sequence)

  function new(string name = "uart_rx_corner_sequence");
    super.new(name);
  endfunction

  task body();
    send_frame(8'h00, UART_RX_RESULT_VALID, UART_RX_RESET_NONE,
               UART_RX_TICK_DIRECT, UART_RX_JITTER_NONE, 1);
    send_frame(8'hFF, UART_RX_RESULT_VALID, UART_RX_RESET_NONE,
               UART_RX_TICK_DIRECT, UART_RX_JITTER_NONE, 2);
    send_frame(8'h7E, UART_RX_RESULT_VALID, UART_RX_RESET_NONE,
               UART_RX_TICK_INTEGER_DIVIDER, UART_RX_JITTER_NONE, 3);
    send_frame(8'h81, UART_RX_RESULT_VALID, UART_RX_RESET_NONE,
               UART_RX_TICK_PHASE_ACCUMULATOR, UART_RX_JITTER_EARLY_LATE, 4);
    send_frame(8'hFF, UART_RX_RESULT_FRAME_ERROR, UART_RX_RESET_NONE,
               UART_RX_TICK_DIRECT, UART_RX_JITTER_NONE, 1);
  endtask
endclass

class uart_rx_byte_sweep_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_byte_sweep_sequence)

  function new(string name = "uart_rx_byte_sweep_sequence");
    super.new(name);
  endfunction

  task body();
    logic [DATA_BITS-1:0] data;

    for (int unsigned i = 0; i < 256; i++) begin
      data = i[DATA_BITS-1:0];
      send_frame(data);
    end
  endtask
endclass

class uart_rx_full_random_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_full_random_sequence)

  function new(string name = "uart_rx_full_random_sequence");
    super.new(name);
  endfunction

  task body();
    int unsigned count;
    logic [DATA_BITS-1:0] data;
    uart_rx_tick_mode_e tick_mode;
    uart_rx_jitter_mode_e jitter_mode;
    uart_rx_reset_phase_e reset_phase;

    if (!$value$plusargs("UART_RX_RANDOM_COUNT=%d", count)) begin
      count = 512;
    end

    for (int unsigned i = 0; i < count; i++) begin
      data = $urandom_range(0, 255);
      tick_mode = uart_rx_tick_mode_e'($urandom_range(0, 2));
      jitter_mode = uart_rx_jitter_mode_e'($urandom_range(0, 2));
      reset_phase = UART_RX_RESET_NONE;
      send_frame(data, UART_RX_RESULT_VALID, reset_phase,
                 tick_mode, jitter_mode, $urandom_range(1, 24));
    end
  endtask
endclass

class uart_rx_all_sequence extends uart_rx_base_sequence;
  `uvm_object_utils(uart_rx_all_sequence)

  function new(string name = "uart_rx_all_sequence");
    super.new(name);
  endfunction

  task body();
    uart_rx_smoke_sequence            smoke_seq;
    uart_rx_directed_pattern_sequence directed_seq;
    uart_rx_error_sequence            error_seq;
    uart_rx_reset_sequence            reset_seq;
    uart_rx_timeout_sequence          timeout_seq;
    uart_rx_jitter_sequence           jitter_seq;
    uart_rx_corner_sequence           corner_seq;
    uart_rx_byte_sweep_sequence       byte_sweep_seq;

    smoke_seq = uart_rx_smoke_sequence::type_id::create("smoke_seq");
    smoke_seq.start(m_sequencer);

    directed_seq = uart_rx_directed_pattern_sequence::type_id::create("directed_seq");
    directed_seq.start(m_sequencer);

    error_seq = uart_rx_error_sequence::type_id::create("error_seq");
    error_seq.start(m_sequencer);

    reset_seq = uart_rx_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(m_sequencer);

    timeout_seq = uart_rx_timeout_sequence::type_id::create("timeout_seq");
    timeout_seq.start(m_sequencer);

    jitter_seq = uart_rx_jitter_sequence::type_id::create("jitter_seq");
    jitter_seq.start(m_sequencer);

    corner_seq = uart_rx_corner_sequence::type_id::create("corner_seq");
    corner_seq.start(m_sequencer);

    byte_sweep_seq = uart_rx_byte_sweep_sequence::type_id::create("byte_sweep_seq");
    byte_sweep_seq.start(m_sequencer);
  endtask
endclass

`endif
