interface adder_if #(
  parameter int DATA_WIDTH = 32
);
  logic [DATA_WIDTH-1:0] iA;
  logic [DATA_WIDTH-1:0] iB;
  logic [DATA_WIDTH:0]   oY;

endinterface
