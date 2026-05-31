`ifndef UART_TX_SEQUENCE_SV
`define UART_TX_SEQUENCE_SV

class uart_tx_base_sequence extends uvm_sequence #(uart_tx_seq_item);
  `uvm_object_utils(uart_tx_base_sequence)

  function new(string name = "uart_tx_base_sequence");
    super.new(name);
  endfunction

  task automatic send_cmd(
    logic [DATA_BITS-1:0] data,
    uart_tx_result_e      expected_result    = UART_TX_RESULT_COMPLETE,
    uart_tx_reset_phase_e reset_phase        = UART_TX_RESET_NONE,
    uart_tx_tick_mode_e   tick_mode          = UART_TX_TICK_DIRECT,
    uart_tx_jitter_mode_e jitter_mode        = UART_TX_JITTER_NONE,
    bit                   attempt_while_busy = 1'b0,
    logic [DATA_BITS-1:0] busy_data          = '0,
    int unsigned          idle_ticks         = 16
  );
    uart_tx_seq_item item;

    item = uart_tx_seq_item::type_id::create("uart_tx_item");
    start_item(item);

    item.data               = data;
    item.busy_data          = busy_data;
    item.attempt_while_busy = attempt_while_busy;
    item.expected_result    = expected_result;
    item.reset_phase        = reset_phase;
    item.tick_mode          = tick_mode;
    item.jitter_mode        = jitter_mode;
    item.idle_ticks         = idle_ticks;
    item.is_window_done     = 1'b0;

    finish_item(item);
  endtask

  virtual task body();
  endtask
endclass

class uart_tx_smoke_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_smoke_sequence)

  function new(string name = "uart_tx_smoke_sequence");
    super.new(name);
  endfunction

  task body();
    send_cmd(8'hA5);
  endtask
endclass

class uart_tx_directed_pattern_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_directed_pattern_sequence)

  function new(string name = "uart_tx_directed_pattern_sequence");
    super.new(name);
  endfunction

  task body();
    logic [DATA_BITS-1:0] walk_one;

    send_cmd(8'h00);
    send_cmd(8'hFF);
    send_cmd(8'h55);
    send_cmd(8'hAA);

    for (int i = 0; i < DATA_BITS; i++) begin
      walk_one = '0;
      walk_one[i] = 1'b1;
      send_cmd(walk_one);
      send_cmd(~walk_one);
    end
  endtask
endclass

class uart_tx_busy_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_busy_sequence)

  function new(string name = "uart_tx_busy_sequence");
    super.new(name);
  endfunction

  task body();
    send_cmd(8'h3C, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_DIRECT, UART_TX_JITTER_NONE, 1'b1, 8'hC3);
  endtask
endclass

class uart_tx_reset_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_reset_sequence)

  function new(string name = "uart_tx_reset_sequence");
    super.new(name);
  endfunction

  task body();
    send_cmd(8'h00, UART_TX_RESULT_RESET_ABORT, UART_TX_RESET_IDLE);
    send_cmd(8'h11, UART_TX_RESULT_RESET_ABORT, UART_TX_RESET_START);
    send_cmd(8'h22, UART_TX_RESULT_RESET_ABORT, UART_TX_RESET_DATA);
    send_cmd(8'h33, UART_TX_RESULT_RESET_ABORT, UART_TX_RESET_STOP);
  endtask
endclass

class uart_tx_timeout_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_timeout_sequence)

  function new(string name = "uart_tx_timeout_sequence");
    super.new(name);
  endfunction

  task body();
    send_cmd(8'h4D, UART_TX_RESULT_TIMEOUT_ABORT);
  endtask
endclass

class uart_tx_jitter_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_jitter_sequence)

  function new(string name = "uart_tx_jitter_sequence");
    super.new(name);
  endfunction

  task body();
    send_cmd(8'h5A, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_DIRECT, UART_TX_JITTER_EARLY_LATE);
    send_cmd(8'hC3, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_PHASE_ACCUMULATOR, UART_TX_JITTER_RANDOM);
    send_cmd(8'h96, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_INTEGER_DIVIDER, UART_TX_JITTER_NONE);
  endtask
endclass

class uart_tx_corner_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_corner_sequence)

  function new(string name = "uart_tx_corner_sequence");
    super.new(name);
  endfunction

  task body();
    send_cmd(8'h00, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_DIRECT, UART_TX_JITTER_NONE, 1'b0, '0, 1);
    send_cmd(8'hFF, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_DIRECT, UART_TX_JITTER_NONE, 1'b0, '0, 2);
    send_cmd(8'h7E, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_INTEGER_DIVIDER, UART_TX_JITTER_NONE, 1'b0, '0, 3);
    send_cmd(8'h81, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_PHASE_ACCUMULATOR, UART_TX_JITTER_EARLY_LATE, 1'b0, '0, 4);
    send_cmd(8'h00, UART_TX_RESULT_COMPLETE, UART_TX_RESET_NONE,
             UART_TX_TICK_DIRECT, UART_TX_JITTER_NONE, 1'b1, 8'hFF, 1);
    send_cmd(8'h5A, UART_TX_RESULT_RESET_ABORT, UART_TX_RESET_START,
             UART_TX_TICK_DIRECT, UART_TX_JITTER_NONE, 1'b0, '0, 1);
    send_cmd(8'hA5, UART_TX_RESULT_RESET_ABORT, UART_TX_RESET_DATA,
             UART_TX_TICK_INTEGER_DIVIDER, UART_TX_JITTER_NONE, 1'b0, '0, 2);
    send_cmd(8'h3C, UART_TX_RESULT_TIMEOUT_ABORT, UART_TX_RESET_NONE,
             UART_TX_TICK_DIRECT, UART_TX_JITTER_NONE, 1'b0, '0, 1);
  endtask
endclass

class uart_tx_byte_sweep_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_byte_sweep_sequence)

  function new(string name = "uart_tx_byte_sweep_sequence");
    super.new(name);
  endfunction

  task body();
    logic [DATA_BITS-1:0] data;

    for (int unsigned i = 0; i < 256; i++) begin
      data = i[DATA_BITS-1:0];
      send_cmd(data);
    end
  endtask
endclass

class uart_tx_full_random_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_full_random_sequence)

  function new(string name = "uart_tx_full_random_sequence");
    super.new(name);
  endfunction

  task body();
    int unsigned count;
    logic [DATA_BITS-1:0] data;
    logic [DATA_BITS-1:0] busy_data;
    uart_tx_tick_mode_e tick_mode;
    uart_tx_jitter_mode_e jitter_mode;
    uart_tx_reset_phase_e reset_phase;

    if (!$value$plusargs("UART_TX_RANDOM_COUNT=%d", count)) begin
      count = 512;
    end

    for (int unsigned i = 0; i < count; i++) begin
      data = $urandom_range(0, 255);
      busy_data = $urandom_range(0, 255);
      tick_mode = uart_tx_tick_mode_e'($urandom_range(0, 2));
      jitter_mode = uart_tx_jitter_mode_e'($urandom_range(0, 2));
      reset_phase = UART_TX_RESET_NONE;
      send_cmd(data, UART_TX_RESULT_COMPLETE, reset_phase,
               tick_mode, jitter_mode, 1'b0, busy_data, $urandom_range(1, 24));
    end
  endtask
endclass

class uart_tx_all_sequence extends uart_tx_base_sequence;
  `uvm_object_utils(uart_tx_all_sequence)

  function new(string name = "uart_tx_all_sequence");
    super.new(name);
  endfunction

  task body();
    uart_tx_smoke_sequence            smoke_seq;
    uart_tx_directed_pattern_sequence directed_seq;
    uart_tx_busy_sequence             busy_seq;
    uart_tx_reset_sequence            reset_seq;
    uart_tx_timeout_sequence          timeout_seq;
    uart_tx_jitter_sequence           jitter_seq;
    uart_tx_corner_sequence           corner_seq;
    uart_tx_byte_sweep_sequence       byte_sweep_seq;

    smoke_seq = uart_tx_smoke_sequence::type_id::create("smoke_seq");
    smoke_seq.start(m_sequencer);

    directed_seq = uart_tx_directed_pattern_sequence::type_id::create("directed_seq");
    directed_seq.start(m_sequencer);

    busy_seq = uart_tx_busy_sequence::type_id::create("busy_seq");
    busy_seq.start(m_sequencer);

    reset_seq = uart_tx_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(m_sequencer);

    timeout_seq = uart_tx_timeout_sequence::type_id::create("timeout_seq");
    timeout_seq.start(m_sequencer);

    jitter_seq = uart_tx_jitter_sequence::type_id::create("jitter_seq");
    jitter_seq.start(m_sequencer);

    corner_seq = uart_tx_corner_sequence::type_id::create("corner_seq");
    corner_seq.start(m_sequencer);

    byte_sweep_seq = uart_tx_byte_sweep_sequence::type_id::create("byte_sweep_seq");
    byte_sweep_seq.start(m_sequencer);
  endtask
endclass

`endif
