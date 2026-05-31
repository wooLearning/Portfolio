`ifndef FIFO_IF_SV
`define FIFO_IF_SV

interface fifo_if #(
  parameter int DATA_WIDTH = 64,
  parameter int DEPTH      = 4,
  parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
  input logic iClk
);

  logic                  iRstn;
  logic                  iWrEn;
  logic                  iRdEn;
  logic [DATA_WIDTH-1:0] iWrData;
  logic [DATA_WIDTH-1:0] oRdData;
  logic                  oFull;
  logic                  oEmpty;
  logic [ADDR_WIDTH:0]   oCount;

  clocking drv_cb @(posedge iClk);
    default input #1step output #1;

    output iWrEn;
    output iRdEn;
    output iWrData;

    input  oFull;
    input  oEmpty;
    input  oCount;
  endclocking

  clocking mon_cb @(posedge iClk);
    default input #1step output #1;

    input iRstn;
    input iWrEn;
    input iRdEn;
    input iWrData;
    input oRdData;
    input oFull;
    input oEmpty;
    input oCount;
  endclocking

  property p_count_empty_match;
    @(posedge iClk) disable iff (!iRstn)
      (oCount == '0) |-> oEmpty;
  endproperty

  property p_count_full_match;
    @(posedge iClk) disable iff (!iRstn)
      (oCount == DEPTH) |-> oFull;
  endproperty

  property p_no_unknown_cmd;
    @(posedge iClk) disable iff (!iRstn)
      !$isunknown({iWrEn, iRdEn});
  endproperty

  a_count_empty_match : assert property (p_count_empty_match)
    else $error("FIFO_IF_SVA: oCount is zero but oEmpty is low");

  a_count_full_match : assert property (p_count_full_match)
    else $error("FIFO_IF_SVA: oCount is DEPTH but oFull is low");

  a_no_unknown_cmd : assert property (p_no_unknown_cmd)
    else $error("FIFO_IF_SVA: iWrEn or iRdEn has X/Z");

endinterface

`endif
