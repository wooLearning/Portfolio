`ifndef SPI_MASTER_IF_SV
`define SPI_MASTER_IF_SV

interface spi_master_if(input logic iClk);
  logic       iRst;
  logic       iTick;
  logic       iStart;
  logic       iCpol;
  logic       iCpha;
  logic [7:0] iTxData;
  logic       iMiso;
  logic [7:0] oRxData;
  logic       oBusy;
  logic       oDone;
  logic       oSclk;
  logic       oCsN;
  logic       oMosi;

  clocking drv_cb @(posedge iClk);
    default input #1step output #1;

    output iRst;
    output iTick;
    output iStart;
    output iCpol;
    output iCpha;
    output iTxData;
    output iMiso;

    input  oRxData;
    input  oBusy;
    input  oDone;
    input  oSclk;
    input  oCsN;
    input  oMosi;
  endclocking

  clocking mon_cb @(posedge iClk);
    default input #1step output #1;

    input iRst;
    input iTick;
    input iStart;
    input iCpol;
    input iCpha;
    input iTxData;
    input iMiso;
    input oRxData;
    input oBusy;
    input oDone;
    input oSclk;
    input oCsN;
    input oMosi;
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

  property p_cs_high_when_idle_done;
    @(posedge iClk) disable iff (iRst)
      (!oBusy || oDone) |-> oCsN;
  endproperty

  property p_sclk_idle_when_cs_high;
    @(posedge iClk) disable iff (iRst)
      (oCsN && !oBusy && !iStart &&
       !$past(iRst) && !$past(iRst, 2) && !$past(iRst, 3) &&
       $stable(iCpol) &&
       (iCpol == $past(iCpol, 2))) |-> (oSclk == iCpol);
  endproperty

  a_done_one_cycle : assert property (p_done_one_cycle)
    else $error("SPI_MASTER_IF_SVA: oDone is not a one-cycle pulse");

  a_no_done_during_reset : assert property (p_no_done_during_reset)
    else $error("SPI_MASTER_IF_SVA: oDone asserted during reset");

  a_done_not_busy : assert property (p_done_not_busy)
    else $error("SPI_MASTER_IF_SVA: oDone asserted while oBusy is high");

  a_cs_high_when_idle_done : assert property (p_cs_high_when_idle_done)
    else $error("SPI_MASTER_IF_SVA: oCsN is not high while idle/done");

  a_sclk_idle_when_cs_high : assert property (p_sclk_idle_when_cs_high)
    else $error("SPI_MASTER_IF_SVA: oSclk is not at CPOL while oCsN is high");
endinterface

`endif
