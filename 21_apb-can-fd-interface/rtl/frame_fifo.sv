`timescale 1ns/1ps
`default_nettype none

// Single-clock, first-word-visible FIFO. Memory contents need no reset:
// rCount defines validity, and oData is zero whenever the FIFO is empty.
module frame_fifo #(
  parameter integer DATA_W = 529,
  parameter integer DEPTH = 4,
  parameter integer COUNT_W = $clog2(DEPTH + 1)
) (
  input  wire logic                iClk,
  input  wire logic                iRstN,
  input  wire logic                iPush,
  input  wire logic [DATA_W-1:0]   iData,
  input  wire logic                iPop,
  output      logic [DATA_W-1:0]   oData,
  output      logic                oFull,
  output      logic                oEmpty,
  output      logic                oPushReady,
  output      logic [COUNT_W-1:0]  oCount
);
  localparam integer PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1;
  logic [DATA_W-1:0] rMem [0:DEPTH-1];
  logic [PTR_W-1:0] rWrPtr, rRdPtr;
  logic [COUNT_W-1:0] rCount;
  logic wPopFire;
  logic wPushFire;

  assign wPopFire = iPop && !oEmpty;
  assign wPushFire = iPush && oPushReady;

  // synthesis translate_off
  initial begin
    if (DEPTH < 1 || DATA_W < 1 || COUNT_W < $clog2(DEPTH+1))
      $fatal(1, "Invalid frame_fifo parameters");
  end
  // synthesis translate_on

  assign oFull = (rCount == COUNT_W'(DEPTH));
  assign oEmpty = (rCount == 0);
  // A simultaneous pop makes room even when the FIFO starts this cycle full.
  assign oPushReady = !oFull || wPopFire;
  assign oData = oEmpty ? {DATA_W{1'b0}} : rMem[rRdPtr];
  assign oCount = rCount;

  // Keep RAM writes separate from asynchronously reset pointers/counter.
  // Unwritten storage is never visible while the FIFO is empty.
  always_ff @(posedge iClk) begin
    if (iRstN && wPushFire) begin
      rMem[rWrPtr] <= iData;
    end
  end

  always_ff @(posedge iClk or negedge iRstN) begin
    if (!iRstN) begin
      rWrPtr <= '0;
      rRdPtr <= '0;
      rCount <= '0;
    end
    else begin
      if (wPushFire) begin
        rWrPtr <= (rWrPtr == PTR_W'(DEPTH-1)) ? '0 : rWrPtr + 1'b1;
      end
      if (wPopFire)
        rRdPtr <= (rRdPtr == PTR_W'(DEPTH-1)) ? '0 : rRdPtr + 1'b1;
      case ({wPushFire, wPopFire})
        2'b10: rCount <= rCount + 1'b1;
        2'b01: rCount <= rCount - 1'b1;
        default: rCount <= rCount;
      endcase
    end
  end
endmodule

`default_nettype wire
