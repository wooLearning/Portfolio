`ifndef I2C_SLAVE_IF_SV
`define I2C_SLAVE_IF_SV

interface i2c_slave_if(input logic iClk);
  logic       iRst;
  logic [6:0] iOwnAddr;
  logic [7:0] iTxData;
  logic       master_scl_oe;
  logic       master_sda_oe;
  logic       scl_line;
  logic       sda_line;
  logic [7:0] oRxData;
  logic       oRxValid;
  logic       oTxnDone;
  logic       oTxnRead;
  logic       oSdaOe;

  assign scl_line = master_scl_oe ? 1'b0 : 1'b1;
  assign sda_line = (master_sda_oe || oSdaOe) ? 1'b0 : 1'b1;

  clocking drv_cb @(posedge iClk);
    default input #1step output #1;

    output iRst;
    output iOwnAddr;
    output iTxData;
    output master_scl_oe;
    output master_sda_oe;

    input  scl_line;
    input  sda_line;
    input  oRxData;
    input  oRxValid;
    input  oTxnDone;
    input  oTxnRead;
    input  oSdaOe;
  endclocking

  clocking mon_cb @(posedge iClk);
    default input #1step output #1;

    input iRst;
    input iOwnAddr;
    input iTxData;
    input master_scl_oe;
    input master_sda_oe;
    input scl_line;
    input sda_line;
    input oRxData;
    input oRxValid;
    input oTxnDone;
    input oTxnRead;
    input oSdaOe;
  endclocking

  property p_rx_valid_one_cycle;
    @(posedge iClk) disable iff (iRst)
      oRxValid |=> !oRxValid;
  endproperty

  property p_txn_done_one_cycle;
    @(posedge iClk) disable iff (iRst)
      oTxnDone |=> !oTxnDone;
  endproperty

  property p_no_pulse_during_reset;
    @(posedge iClk)
      iRst |-> (!oRxValid && !oTxnDone);
  endproperty

  property p_rx_valid_only_for_write;
    @(posedge iClk) disable iff (iRst)
      oRxValid |-> !oTxnRead;
  endproperty

  a_rx_valid_one_cycle : assert property (p_rx_valid_one_cycle)
    else $error("I2C_SLAVE_IF_SVA: oRxValid is not a one-cycle pulse");

  a_txn_done_one_cycle : assert property (p_txn_done_one_cycle)
    else $error("I2C_SLAVE_IF_SVA: oTxnDone is not a one-cycle pulse");

  a_no_pulse_during_reset : assert property (p_no_pulse_during_reset)
    else $error("I2C_SLAVE_IF_SVA: result pulse during reset");

  a_rx_valid_only_for_write : assert property (p_rx_valid_only_for_write)
    else $error("I2C_SLAVE_IF_SVA: oRxValid asserted for read transaction");
endinterface

`endif
