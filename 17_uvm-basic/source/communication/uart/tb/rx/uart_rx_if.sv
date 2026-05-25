`ifndef UART_RX_IF_SV
`define UART_RX_IF_SV

interface uart_rx_if #(
  parameter int DATA_BITS  = 8,
  parameter int OVERSAMPLE = 16
)(
  input logic iClk
);

  localparam int MID_TICK = (OVERSAMPLE / 2) - 1;

  logic                 iRst;
  logic                 iTick16x;
  logic                 iRx;
  logic [DATA_BITS-1:0] oRxData;
  logic                 oRxValid;
  logic                 oRxBusy;
  logic                 oFrameError;

  logic                 rWasIdleHigh;
  logic                 rCheckingStart;
  logic                 rFalseStartWindow;
  int                   rFalseStartTickCnt;
  int                   rFalseStartWindowCnt;

  clocking drv_cb @(posedge iClk);
    default input #1step output #1;

    output iRst;
    output iTick16x;
    output iRx;

    input  oRxData;
    input  oRxValid;
    input  oRxBusy;
    input  oFrameError;
  endclocking

  clocking mon_cb @(posedge iClk);
    default input #1step output #1;

    input iRst;
    input iTick16x;
    input iRx;
    input oRxData;
    input oRxValid;
    input oRxBusy;
    input oFrameError;
  endclocking

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rWasIdleHigh         <= 1'b1;
      rCheckingStart       <= 1'b0;
      rFalseStartWindow    <= 1'b0;
      rFalseStartTickCnt   <= 0;
      rFalseStartWindowCnt <= 0;
    end
    else begin
      rWasIdleHigh <= iRx && !oRxBusy;

      if (rFalseStartWindow) begin
        if (iTick16x) begin
          if (rFalseStartWindowCnt == ((OVERSAMPLE * 10) - 1)) begin
            rFalseStartWindow <= 1'b0;
          end
          else begin
            rFalseStartWindowCnt <= rFalseStartWindowCnt + 1;
          end
        end
      end

      if (!rCheckingStart && rWasIdleHigh && !iRx) begin
        rCheckingStart     <= 1'b1;
        rFalseStartTickCnt <= 0;
      end
      else if (rCheckingStart && iTick16x) begin
        if (rFalseStartTickCnt == MID_TICK) begin
          rCheckingStart <= 1'b0;

          if (iRx) begin
            rFalseStartWindow    <= 1'b1;
            rFalseStartWindowCnt <= 0;
          end
        end
        else begin
          rFalseStartTickCnt <= rFalseStartTickCnt + 1;
        end
      end
    end
  end

  property p_no_valid_and_frame_error;
    @(posedge iClk) disable iff (iRst)
      !(oRxValid && oFrameError);
  endproperty

  property p_no_pulse_during_reset;
    @(posedge iClk)
      iRst |-> (!oRxValid && !oFrameError);
  endproperty

  property p_valid_one_cycle_pulse;
    @(posedge iClk) disable iff (iRst)
      oRxValid |=> !oRxValid;
  endproperty

  property p_frame_error_one_cycle_pulse;
    @(posedge iClk) disable iff (iRst)
      oFrameError |=> !oFrameError;
  endproperty

  property p_no_result_after_false_start;
    @(posedge iClk) disable iff (iRst)
      rFalseStartWindow |-> (!oRxValid && !oFrameError);
  endproperty

  a_no_valid_and_frame_error : assert property (p_no_valid_and_frame_error)
    else $error("UART_RX_IF_SVA: oRxValid and oFrameError are both high");

  a_no_pulse_during_reset : assert property (p_no_pulse_during_reset)
    else $error("UART_RX_IF_SVA: valid/error pulse during reset");

  a_valid_one_cycle_pulse : assert property (p_valid_one_cycle_pulse)
    else $error("UART_RX_IF_SVA: oRxValid is not a one-cycle pulse");

  a_frame_error_one_cycle_pulse : assert property (p_frame_error_one_cycle_pulse)
    else $error("UART_RX_IF_SVA: oFrameError is not a one-cycle pulse");

  a_no_result_after_false_start : assert property (p_no_result_after_false_start)
    else $error("UART_RX_IF_SVA: result pulse after false start");

endinterface

`endif
