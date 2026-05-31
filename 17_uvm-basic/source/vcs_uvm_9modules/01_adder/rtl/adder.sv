module adder #(
  parameter int DATA_WIDTH = 32
)(
  input  logic [DATA_WIDTH-1:0] iA,
  input  logic [DATA_WIDTH-1:0] iB,
  output logic [DATA_WIDTH  :0] oY
);

  assign oY = iA + iB;

endmodule
