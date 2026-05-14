`timescale 1ns / 1ps

module AxiLiteRom #(
  parameter integer P_ADDR_WIDTH = 12,
  parameter string  P_MEM_FILE = "src/timing_programs/link_demo.mem"
) (
  input  logic        iClk,
  input  logic        iRstn,
  input  logic [31:0] iS_AWADDR,
  input  logic        iS_AWVALID,
  output logic        oS_AWREADY,
  input  logic [31:0] iS_WDATA,
  input  logic [3:0]  iS_WSTRB,
  input  logic        iS_WVALID,
  output logic        oS_WREADY,
  output logic [1:0]  oS_BRESP,
  output logic        oS_BVALID,
  input  logic        iS_BREADY,
  input  logic [31:0] iS_ARADDR,
  input  logic        iS_ARVALID,
  output logic        oS_ARREADY,
  output logic [31:0] oS_RDATA,
  output logic [1:0]  oS_RRESP,
  output logic        oS_RVALID,
  input  logic        iS_RREADY
);

  localparam integer LP_DEPTH = (1 << P_ADDR_WIDTH);
  localparam logic [31:0] LP_NOP = 32'h0000_0013;

  (* ram_style = "block" *) logic [31:0] rMem [0:LP_DEPTH-1];
  logic [31:0] rRData;
  logic        rRValid;
  logic        rBValid;
  logic [P_ADDR_WIDTH-1:0] wReadWordAddr;
  logic                    wReadInRange;
  integer                  idx;

  assign wReadWordAddr = iS_ARADDR[P_ADDR_WIDTH+1:2];
  assign wReadInRange  = (iS_ARADDR[31:P_ADDR_WIDTH+2] == '0);
  assign oS_AWREADY = !rBValid;
  assign oS_WREADY  = !rBValid;
  assign oS_BRESP   = axi_lite_pkg::RESP_SLVERR;
  assign oS_BVALID  = rBValid;
  assign oS_ARREADY = !rRValid;
  assign oS_RDATA   = rRData;
  assign oS_RRESP   = axi_lite_pkg::RESP_OKAY;
  assign oS_RVALID  = rRValid;

  initial begin
    for (idx = 0; idx < LP_DEPTH; idx = idx + 1) begin
      rMem[idx] = LP_NOP;
    end

    $readmemh(P_MEM_FILE, rMem);
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rRData  <= LP_NOP;
      rRValid <= 1'b0;
      rBValid <= 1'b0;
    end
    else begin
      if (rRValid && iS_RREADY) begin
        rRValid <= 1'b0;
      end

      if (rBValid && iS_BREADY) begin
        rBValid <= 1'b0;
      end

      if (iS_ARVALID && oS_ARREADY) begin
        rRData  <= wReadInRange ? rMem[wReadWordAddr] : LP_NOP;
        rRValid <= 1'b1;
      end

      if (iS_AWVALID && oS_AWREADY && iS_WVALID && oS_WREADY) begin
        rBValid <= 1'b1;
      end
    end
  end

endmodule
