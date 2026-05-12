module sync_fifo #(
  parameter int DATA_WIDTH = 64,
  parameter int DEPTH      = 4,
  parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
  input  logic                  iClk,
  input  logic                  iRstn,
  input  logic                  iWrEn,
  input  logic                  iRdEn,
  input  logic [DATA_WIDTH-1:0] iWrData,
  output logic [DATA_WIDTH-1:0] oRdData,
  output logic                  oFull,
  output logic                  oEmpty,
  output logic [ADDR_WIDTH:0]   oCount
);

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_WIDTH-1:0] wr_ptr;
  logic [ADDR_WIDTH-1:0] rd_ptr;
  integer idx;

  assign oRdData = mem[rd_ptr];
  assign oFull   = (oCount == DEPTH);
  assign oEmpty  = (oCount == 0);

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      oCount <= '0;
      for (idx = 0; idx < DEPTH; idx = idx + 1) begin
        mem[idx] <= '0;
      end
    end else begin
      unique case ({iWrEn && !oFull, iRdEn && !oEmpty})
        2'b10: begin
          mem[wr_ptr] <= iWrData;
          wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
          oCount      <= oCount + 1'b1;
        end
        2'b01: begin
          rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
          oCount <= oCount - 1'b1;
        end
        2'b11: begin
          mem[wr_ptr] <= iWrData;
          wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
          rd_ptr      <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
        end
        default: begin
        end
      endcase
    end
  end

endmodule
