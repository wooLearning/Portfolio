module ram #(
  parameter int DATA_WIDTH = 32,
  parameter int DEPTH      = 16,
  parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
  input  logic                  iClk,
  input  logic                  iRstn,
  input  logic                  iCs,
  input  logic                  iWea,
  input  logic [ADDR_WIDTH-1:0] iAddr,
  input  logic [DATA_WIDTH-1:0] iWData,
  output logic [DATA_WIDTH-1:0] oRData
);

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  integer idx;

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      oRData <= '0;
      for (idx = 0; idx < DEPTH; idx = idx + 1) begin
        mem[idx] <= '0;
      end
    end else begin
      if (iCs) begin
        if (iWea) begin
          mem[iAddr] <= iWData;
        end else begin
          oRData <= mem[iAddr];
        end
      end
    end
  end

endmodule
