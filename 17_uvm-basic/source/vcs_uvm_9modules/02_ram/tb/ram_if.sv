`ifndef RAM_IF_SV
`define RAM_IF_SV

interface ram_if #(
  parameter int DATA_WIDTH = 32,
  parameter int DEPTH      = 16,
  parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
  input logic iClk
);

  logic                  iRstn;
  logic                  iCs;
  logic                  iWea;
  logic [ADDR_WIDTH-1:0] iAddr;
  logic [DATA_WIDTH-1:0] iWData;
  logic [DATA_WIDTH-1:0] oRData;

  clocking drv_cb @(posedge iClk);
    default input #1step output #1;

    output iCs;
    output iWea;
    output iAddr;
    output iWData;

    input  oRData;
  endclocking

  clocking mon_cb @(posedge iClk);
    default input #1step output #1;

    input iRstn;
    input iCs;
    input iWea;
    input iAddr;
    input iWData;
    input oRData;
  endclocking

`include "ram_if_sva.svh"

endinterface

`endif
