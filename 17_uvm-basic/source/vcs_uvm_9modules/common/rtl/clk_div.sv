`timescale 1ns/1ps

module clk_div #(
  parameter int DIV_RATIO = 25
) (
  input  logic iClk,
  input  logic iRst,
  output logic oTick
);

  localparam int CNT_W = (DIV_RATIO > 1) ? $clog2(DIV_RATIO) : 1;

  logic [CNT_W-1:0] rCnt;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rCnt  <= '0;
      oTick <= 1'b0;
    end
    else if (DIV_RATIO <= 1) begin
      rCnt  <= '0;
      oTick <= 1'b1;
    end
    else if (rCnt == DIV_RATIO - 1) begin
      rCnt  <= '0;
      oTick <= 1'b1;
    end
    else begin
      rCnt  <= rCnt + 1'b1;
      oTick <= 1'b0;
    end
  end

endmodule
