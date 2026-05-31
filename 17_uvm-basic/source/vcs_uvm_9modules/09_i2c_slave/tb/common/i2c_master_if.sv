`ifndef I2C_MASTER_IF_SV
`define I2C_MASTER_IF_SV

interface i2c_master_if(input logic iClk);
  logic       iRst;
  logic       iTick;
  logic       iStart;
  logic       iRead;
  logic [6:0] iSlaveAddr;
  logic [7:0] iTxData;
  logic       slave_sda_oe;
  logic       scl_line;
  logic       sda_line;
  logic [7:0] oRxData;
  logic       oBusy;
  logic       oDone;
  logic       oAckError;
  logic       oSclOe;
  logic       oSdaOe;

  assign scl_line = oSclOe ? 1'b0 : 1'b1;
  assign sda_line = (oSdaOe || slave_sda_oe) ? 1'b0 : 1'b1;

  clocking drv_cb @(posedge iClk);
    default input #1step output #1;

    output iRst;
    output iTick;
    output iStart;
    output iRead;
    output iSlaveAddr;
    output iTxData;
    output slave_sda_oe;

    input  scl_line;
    input  sda_line;
    input  oRxData;
    input  oBusy;
    input  oDone;
    input  oAckError;
    input  oSclOe;
    input  oSdaOe;
  endclocking

  clocking mon_cb @(posedge iClk);
    default input #1step output #1;

    input iRst;
    input iTick;
    input iStart;
    input iRead;
    input iSlaveAddr;
    input iTxData;
    input slave_sda_oe;
    input scl_line;
    input sda_line;
    input oRxData;
    input oBusy;
    input oDone;
    input oAckError;
    input oSclOe;
    input oSdaOe;
  endclocking

  property p_done_one_cycle;
    @(posedge iClk) disable iff (iRst)
      oDone |=> !oDone;
  endproperty

  property p_no_done_during_reset;
    @(posedge iClk)
      iRst |-> !oDone;
  endproperty

  property p_done_not_busy;
    @(posedge iClk) disable iff (iRst)
      oDone |-> !oBusy;
  endproperty

  property p_idle_bus_released;
    @(posedge iClk) disable iff (iRst)
      (!oBusy && !iStart) |-> (!oSclOe && !oSdaOe);
  endproperty

  a_done_one_cycle : assert property (p_done_one_cycle)
    else $error("I2C_MASTER_IF_SVA: oDone is not a one-cycle pulse");

  a_no_done_during_reset : assert property (p_no_done_during_reset)
    else $error("I2C_MASTER_IF_SVA: oDone asserted during reset");

  a_done_not_busy : assert property (p_done_not_busy)
    else $error("I2C_MASTER_IF_SVA: oDone asserted while oBusy is high");

  a_idle_bus_released : assert property (p_idle_bus_released)
    else $error("I2C_MASTER_IF_SVA: bus output enables are active while idle");
endinterface

`endif
