`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ByteFifo
Role: Small synchronous FIFO for byte-oriented peripherals
Summary:
  - Provides raw push/pop control for UART/SPI internal TX/RX queues
  - Accepts a push while full only when a pop is also accepted
  - Keeps stream ready/valid buffering separate from StreamFifo
StateDescription:
  - Write/read pointers and count track queued entries
[MODULE_INFO_END]
*/
module ByteFifo #(
  parameter integer P_DATA_WIDTH = 8,
  parameter integer P_DEPTH = 4
) (
  input  logic                     iClk,
  input  logic                     iRstn,

  input  logic                     iPush,
  input  logic [P_DATA_WIDTH-1:0]  iPushData,
  output logic                     oPushReady,

  input  logic                     iPop,
  output logic [P_DATA_WIDTH-1:0]  oPopData,
  output logic                     oPopValid,

  output logic                     oFull,
  output logic                     oEmpty,
  output logic [$clog2(P_DEPTH + 1)-1:0] oCount
);

  localparam integer LP_PTR_WIDTH = (P_DEPTH <= 2) ? 1 : $clog2(P_DEPTH);
  localparam integer LP_CNT_WIDTH = $clog2(P_DEPTH + 1);
  localparam logic [LP_CNT_WIDTH-1:0] LP_DEPTH_COUNT = P_DEPTH[LP_CNT_WIDTH-1:0];

  logic [P_DATA_WIDTH-1:0]  rMem [0:P_DEPTH-1];
  logic [LP_PTR_WIDTH-1:0]  rWrPtr;
  logic [LP_PTR_WIDTH-1:0]  rRdPtr;
  logic [LP_CNT_WIDTH-1:0]  rCount;
  logic                     wPop;
  logic                     wPush;
  integer                   idx;

  assign oFull      = (rCount == LP_DEPTH_COUNT);
  assign oEmpty     = (rCount == '0);
  assign oPopValid  = !oEmpty;
  assign oPushReady = !oFull || wPop;
  assign oPopData   = oPopValid ? rMem[rRdPtr] : '0;
  assign oCount     = rCount;
  assign wPop       = iPop && oPopValid;
  assign wPush      = iPush && oPushReady;

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
        rMem[rWrPtr] <= iPushData;
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
