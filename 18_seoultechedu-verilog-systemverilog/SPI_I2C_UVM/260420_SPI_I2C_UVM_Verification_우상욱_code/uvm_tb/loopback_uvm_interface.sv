`timescale 1ns / 1ps

interface loopback_uvm_if (
    input logic clk
);
  localparam int LOOPBACK_DONE_TIMEOUT = 6000;

  logic        rst;
  logic        start;
  logic        mode_i2c;
  logic        read_en;
  logic [1:0]  spi_mode;
  logic [1:0]  reg_sel;
  logic [7:0]  tx_data;
  logic [7:0]  rx_data;
  logic        busy;
  logic        done;
  logic        ack_error;
  logic [15:0] digits;

  clocking drv_cb @(posedge clk);
    default input #1step output #0;
    output rst;
    output start;
    output mode_i2c;
    output read_en;
    output spi_mode;
    output reg_sel;
    output tx_data;
    input rx_data;
    input busy;
    input done;
    input ack_error;
    input digits;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst;
    input start;
    input mode_i2c;
    input read_en;
    input spi_mode;
    input reg_sel;
    input tx_data;
    input rx_data;
    input busy;
    input done;
    input ack_error;
    input digits;
  endclocking

  property p_reset_clears_outputs;
    @(posedge clk) rst |=> (!busy && !done && !ack_error && (digits == 16'h0000));
  endproperty

  property p_start_one_pulse;
    @(posedge clk) disable iff (rst) start |=> !start;
  endproperty

  property p_start_eventually_done;
    @(posedge clk) disable iff (rst) $rose(start) |-> ##[1:LOOPBACK_DONE_TIMEOUT] done;
  endproperty

  property p_busy_eventually_done;
    @(posedge clk) disable iff (rst) $rose(busy) |-> ##[1:LOOPBACK_DONE_TIMEOUT] done;
  endproperty

  property p_ack_requires_done;
    @(posedge clk) disable iff (rst) ack_error |-> done;
  endproperty

  a_loop_reset_clears_outputs: assert property (p_reset_clears_outputs)
    else $error("LOOPBACK_ASSERT reset 이후 busy/done/ack/digits가 초기화되지 않았습니다.");

  a_loop_start_one_pulse: assert property (p_start_one_pulse)
    else $error("LOOPBACK_ASSERT start는 1-cycle pulse여야 합니다.");

  a_loop_start_eventually_done: assert property (p_start_eventually_done)
    else $error("LOOPBACK_ASSERT start 이후 done이 timeout 안에 올라오지 않았습니다.");

  a_loop_busy_eventually_done: assert property (p_busy_eventually_done)
    else $error("LOOPBACK_ASSERT busy 이후 done이 timeout 안에 올라오지 않았습니다.");

  a_loop_ack_requires_done: assert property (p_ack_requires_done)
    else $error("LOOPBACK_ASSERT ack_error는 done과 함께 관측되어야 합니다.");

endinterface
