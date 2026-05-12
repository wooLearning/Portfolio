`timescale 1ns / 1ps

/*
  AXI-Stream-style byte FIFO starter.

  This is intentionally small and independent from the current SoC.
  It uses the core ready/valid rule:

    transfer happens when valid && ready

  Ports:
    S side = input/source side
    M side = output/master side

  Notes:
    - This is not full AXI-Stream because it has no TKEEP/TLAST/TUSER.
    - Add TLAST later when the stream bridge needs packet/frame boundaries.
*/
module StreamFifo #(
  parameter integer P_DATA_WIDTH = 8,
  parameter integer P_DEPTH = 16
) (
  input  logic                     iClk,
  input  logic                     iRstn,

  input  logic [P_DATA_WIDTH-1:0]  iSData,
  input  logic                     iSValid,
  output logic                     oSReady,

  output logic [P_DATA_WIDTH-1:0]  oMData,
  output logic                     oMValid,
  input  logic                     iMReady,

  output logic                     oFull,
  output logic                     oEmpty
);

  localparam integer LP_PTR_WIDTH = (P_DEPTH <= 2) ? 1 : $clog2(P_DEPTH);
  localparam integer LP_CNT_WIDTH = $clog2(P_DEPTH + 1);

  logic [P_DATA_WIDTH-1:0] rMem [0:P_DEPTH-1];
  logic [LP_PTR_WIDTH-1:0] rWrPtr;
  logic [LP_PTR_WIDTH-1:0] rRdPtr;
  logic [LP_CNT_WIDTH-1:0] rCount;
  logic                    wPush;
  logic                    wPop;
  integer                  idx;

  assign oFull   = (rCount == P_DEPTH[LP_CNT_WIDTH-1:0]);
  assign oEmpty  = (rCount == '0);
  assign oSReady = !oFull || wPop;
  assign oMValid = !oEmpty;
  assign oMData  = rMem[rRdPtr];
  assign wPush   = iSValid && oSReady;
  assign wPop    = oMValid && iMReady;

  function automatic logic [LP_PTR_WIDTH-1:0] next_ptr(
    input logic [LP_PTR_WIDTH-1:0] iPtr
  );
    begin
      if (iPtr == P_DEPTH[LP_PTR_WIDTH-1:0] - 1'b1) begin
        next_ptr = '0;
      end
      else begin
        next_ptr = iPtr + 1'b1;
      end
    end
  endfunction

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rWrPtr <= '0;
      rRdPtr <= '0;
      rCount <= '0;

      for (idx = 0; idx < P_DEPTH; idx = idx + 1) begin
        rMem[idx] <= '0;
      end
    end
    else begin
      if (wPush) begin
        rMem[rWrPtr] <= iSData;
        rWrPtr <= next_ptr(rWrPtr);
      end

      if (wPop) begin
        rRdPtr <= next_ptr(rRdPtr);
      end

      unique case ({wPush, wPop})
        2'b10: rCount <= rCount + 1'b1;
        2'b01: rCount <= rCount - 1'b1;
        default: begin end
      endcase
    end
  end

endmodule
