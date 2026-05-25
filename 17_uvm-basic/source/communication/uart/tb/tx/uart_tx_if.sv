`ifndef UART_TX_IF_SV
`define UART_TX_IF_SV

interface uart_tx_if #(
  parameter int DATA_BITS  = 8,
  parameter int OVERSAMPLE = 16
)(
  input logic iClk
);

  logic                 iRst;
  logic                 iTick16x;
  logic [DATA_BITS-1:0] iTxData;
  logic                 iTxValid;
  logic                 oTxReady;
  logic                 oTx;
  logic                 oTxBusy;
  logic                 oTxDone;

  clocking drv_cb @(posedge iClk);
    default input #1step output #1;

    output iRst;
    output iTick16x;
    output iTxData;
    output iTxValid;

    input  oTxReady;
    input  oTx;
    input  oTxBusy;
    input  oTxDone;
  endclocking

  clocking mon_cb @(posedge iClk);
    default input #1step output #1;

    input iRst;
    input iTick16x;
    input iTxData;
    input iTxValid;
    input oTxReady;
    input oTx;
    input oTxBusy;
    input oTxDone;
  endclocking

  property p_done_one_cycle_pulse;
    @(posedge iClk) disable iff (iRst)
      oTxDone |=> !oTxDone;
  endproperty

  property p_no_done_during_reset;
    @(posedge iClk)
      iRst |-> !oTxDone;
  endproperty

  property p_ready_busy_complement;
    @(posedge iClk) disable iff (iRst)
      oTxReady == !oTxBusy;
  endproperty

  property p_idle_tx_high;
    @(posedge iClk) disable iff (iRst)
      (!oTxBusy && !iTxValid) |-> oTx;
  endproperty

  a_done_one_cycle_pulse : assert property (p_done_one_cycle_pulse)
    else $error("UART_TX_IF_SVA: oTxDone is not a one-cycle pulse");

  a_no_done_during_reset : assert property (p_no_done_during_reset)
    else $error("UART_TX_IF_SVA: oTxDone asserted during reset");

  a_ready_busy_complement : assert property (p_ready_busy_complement)
    else $error("UART_TX_IF_SVA: oTxReady and oTxBusy are inconsistent");

  a_idle_tx_high : assert property (p_idle_tx_high)
    else $error("UART_TX_IF_SVA: oTx is not high while idle");

endinterface

`endif
