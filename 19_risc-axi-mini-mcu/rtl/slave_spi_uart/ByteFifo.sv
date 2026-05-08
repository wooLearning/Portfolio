`timescale 1ns / 1ps

module ByteFifo #(
  parameter integer P_DEPTH = 8192
) (
  input  logic       iClk,
  input  logic       iRstn,
  input  logic [7:0] iWrData,
  input  logic       iWrValid,
  output logic       oWrReady,
  output logic [7:0] oRdData,
  output logic       oRdValid,
  input  logic       iRdReady,
  output logic       oFull,
  output logic       oEmpty,
  output logic [$clog2(P_DEPTH + 1)-1:0] oLevel
);

  localparam integer LP_PTR_WIDTH = (P_DEPTH <= 2) ? 1 : $clog2(P_DEPTH);
  localparam integer LP_CNT_WIDTH = $clog2(P_DEPTH + 1);

  (* ram_style = "block" *) logic [7:0] rMem [0:P_DEPTH-1];
  logic [LP_PTR_WIDTH-1:0] rWrPtr;
  logic [LP_PTR_WIDTH-1:0] rRdPtr;
  logic [LP_CNT_WIDTH-1:0] rCount;
  logic                    wPush;
  logic                    wPop;

  assign oFull    = (rCount == P_DEPTH[LP_CNT_WIDTH-1:0]);
  assign oEmpty   = (rCount == '0);
  assign oWrReady = !oFull || wPop;
  assign oRdValid = !oEmpty;
  assign oRdData  = rMem[rRdPtr];
  assign oLevel   = rCount;
  assign wPush    = iWrValid && oWrReady;
  assign wPop     = oRdValid && iRdReady;

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

  always_ff @(posedge iClk) begin
    if (!iRstn) begin
      rWrPtr <= '0;
      rRdPtr <= '0;
      rCount <= '0;
    end
    else begin
      if (wPush) begin
        rMem[rWrPtr] <= iWrData;
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
