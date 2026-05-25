`ifndef SPI_SLAVE_IF_SV
`define SPI_SLAVE_IF_SV

interface spi_slave_if(input logic iClk);
  logic       iRst;
  logic       iCpol;
  logic       iCpha;
  logic       iSclk;
  logic       iCsN;
  logic       iMosi;
  logic [7:0] iTxData;
  logic [7:0] oRxData;
  logic       oRxValid;
  logic       oMiso;
  logic       oMisoOe;

  clocking drv_cb @(posedge iClk);
    default input #1step output #1;

    output iRst;
    output iCpol;
    output iCpha;
    output iSclk;
    output iCsN;
    output iMosi;
    output iTxData;

    input  oRxData;
    input  oRxValid;
    input  oMiso;
    input  oMisoOe;
  endclocking

  clocking mon_cb @(posedge iClk);
    default input #1step output #1;

    input iRst;
    input iCpol;
    input iCpha;
    input iSclk;
    input iCsN;
    input iMosi;
    input iTxData;
    input oRxData;
    input oRxValid;
    input oMiso;
    input oMisoOe;
  endclocking

  property p_miso_oe_released_when_cs_high;
    @(posedge iClk) disable iff (iRst)
      iCsN |-> !oMisoOe;
  endproperty

  property p_rx_valid_one_cycle;
    @(posedge iClk) disable iff (iRst)
      oRxValid |=> !oRxValid;
  endproperty

  property p_no_rx_valid_during_reset;
    @(posedge iClk)
      iRst |-> !oRxValid;
  endproperty

  a_miso_oe_released_when_cs_high : assert property (p_miso_oe_released_when_cs_high)
    else $error("SPI_SLAVE_IF_SVA: oMisoOe high while iCsN is high");

  a_rx_valid_one_cycle : assert property (p_rx_valid_one_cycle)
    else $error("SPI_SLAVE_IF_SVA: oRxValid is not a one-cycle pulse");

  a_no_rx_valid_during_reset : assert property (p_no_rx_valid_during_reset)
    else $error("SPI_SLAVE_IF_SVA: oRxValid asserted during reset");

endinterface

`endif
