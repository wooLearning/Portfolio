`timescale 1ns / 1ps

module AxiLiteSram #(
  parameter integer P_ADDR_WIDTH = 12,
  parameter bit     P_ENABLE_DEBUG_WORDS = 1'b0
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
  input  logic        iS_RREADY,
  input  logic        iILocalValid,
  input  logic [31:0] iILocalAddr,
  output logic        oILocalReady,
  output logic [31:0] oILocalRData,
  output logic        oILocalError,
  output logic [31:0] oDbgWord0,
  output logic [31:0] oDbgWord1,
  output logic [31:0] oDbgWord2,
  output logic [31:0] oDbgWord3
);

  localparam integer LP_DEPTH = (1 << P_ADDR_WIDTH);

  (* ram_style = "block" *) logic [31:0] rMem [0:LP_DEPTH-1];
  logic [P_ADDR_WIDTH-1:0] wReadWordAddr;
  logic [P_ADDR_WIDTH-1:0] wWriteWordAddr;
  logic [P_ADDR_WIDTH-1:0] wIReadWordAddr;
  logic                    wReadInRange;
  logic                    wWriteInRange;
  logic                    wIReadInRange;
  logic [31:0]             rRData;
  logic                    rRValid;
  logic                    rBValid;
  logic [31:0]             rIReadAddr;
  logic [31:0]             rIReadData;
  logic                    rIReadValid;
  logic [31:0]             rDbgWord0;
  logic [31:0]             rDbgWord1;
  logic [31:0]             rDbgWord2;
  logic [31:0]             rDbgWord3;

  assign wReadWordAddr  = iS_ARADDR[P_ADDR_WIDTH+1:2];
  assign wWriteWordAddr = iS_AWADDR[P_ADDR_WIDTH+1:2];
  assign wIReadWordAddr = iILocalAddr[P_ADDR_WIDTH+1:2];
  assign wReadInRange   = (iS_ARADDR[31:P_ADDR_WIDTH+2] == '0);
  assign wWriteInRange  = (iS_AWADDR[31:P_ADDR_WIDTH+2] == '0);
  assign wIReadInRange  = (iILocalAddr[31:P_ADDR_WIDTH+2] == '0);
  assign oS_AWREADY = !rBValid;
  assign oS_WREADY  = !rBValid;
  assign oS_BRESP   = axi_lite_pkg::RESP_OKAY;
  assign oS_BVALID  = rBValid;
  assign oS_ARREADY = !rRValid;
  assign oS_RDATA   = rRData;
  assign oS_RRESP   = axi_lite_pkg::RESP_OKAY;
  assign oS_RVALID  = rRValid;
  assign oILocalReady = iILocalValid && rIReadValid && (rIReadAddr == iILocalAddr);
  assign oILocalRData = rIReadData;
  assign oILocalError = 1'b0;

  assign oDbgWord0 = P_ENABLE_DEBUG_WORDS ? rDbgWord0 : 32'd0;
  assign oDbgWord1 = P_ENABLE_DEBUG_WORDS ? rDbgWord1 : 32'd0;
  assign oDbgWord2 = P_ENABLE_DEBUG_WORDS ? rDbgWord2 : 32'd0;
  assign oDbgWord3 = P_ENABLE_DEBUG_WORDS ? rDbgWord3 : 32'd0;

  always_ff @(posedge iClk) begin
    if (iS_ARVALID && oS_ARREADY) begin
      rRData <= wReadInRange ? rMem[wReadWordAddr] : 32'd0;
    end

    if (iS_AWVALID && oS_AWREADY && iS_WVALID && oS_WREADY && wWriteInRange) begin
      if (iS_WSTRB[0]) begin
        rMem[wWriteWordAddr][7:0] <= iS_WDATA[7:0];
      end
      if (iS_WSTRB[1]) begin
        rMem[wWriteWordAddr][15:8] <= iS_WDATA[15:8];
      end
      if (iS_WSTRB[2]) begin
        rMem[wWriteWordAddr][23:16] <= iS_WDATA[23:16];
      end
      if (iS_WSTRB[3]) begin
        rMem[wWriteWordAddr][31:24] <= iS_WDATA[31:24];
      end
    end

    if (iILocalValid && !oILocalReady) begin
      rIReadData <= wIReadInRange ? rMem[wIReadWordAddr] : 32'h0000_0013;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rRValid <= 1'b0;
      rBValid <= 1'b0;
      rIReadAddr <= 32'd0;
      rIReadValid <= 1'b0;
      rDbgWord0 <= 32'd0;
      rDbgWord1 <= 32'd0;
      rDbgWord2 <= 32'd0;
      rDbgWord3 <= 32'd0;
    end
    else begin
      if (iS_ARVALID && oS_ARREADY) begin
        rRValid <= 1'b1;
      end
      else if (rRValid && iS_RREADY) begin
        rRValid <= 1'b0;
      end

      if (iILocalValid && !oILocalReady) begin
        rIReadAddr <= iILocalAddr;
        rIReadValid <= 1'b1;
      end
      else if (!iILocalValid) begin
        rIReadValid <= 1'b0;
      end

      if (iS_AWVALID && oS_AWREADY && iS_WVALID && oS_WREADY) begin
        rBValid <= 1'b1;

        if (P_ENABLE_DEBUG_WORDS && wWriteInRange && (wWriteWordAddr < 4)) begin
          unique case (wWriteWordAddr[1:0])
            2'd0: rDbgWord0 <= (rDbgWord0 & ~{{8{iS_WSTRB[3]}}, {8{iS_WSTRB[2]}},
                                                {8{iS_WSTRB[1]}}, {8{iS_WSTRB[0]}}}) |
                                (iS_WDATA & {{8{iS_WSTRB[3]}}, {8{iS_WSTRB[2]}},
                                             {8{iS_WSTRB[1]}}, {8{iS_WSTRB[0]}}});
            2'd1: rDbgWord1 <= (rDbgWord1 & ~{{8{iS_WSTRB[3]}}, {8{iS_WSTRB[2]}},
                                                {8{iS_WSTRB[1]}}, {8{iS_WSTRB[0]}}}) |
                                (iS_WDATA & {{8{iS_WSTRB[3]}}, {8{iS_WSTRB[2]}},
                                             {8{iS_WSTRB[1]}}, {8{iS_WSTRB[0]}}});
            2'd2: rDbgWord2 <= (rDbgWord2 & ~{{8{iS_WSTRB[3]}}, {8{iS_WSTRB[2]}},
                                                {8{iS_WSTRB[1]}}, {8{iS_WSTRB[0]}}}) |
                                (iS_WDATA & {{8{iS_WSTRB[3]}}, {8{iS_WSTRB[2]}},
                                             {8{iS_WSTRB[1]}}, {8{iS_WSTRB[0]}}});
            default: rDbgWord3 <= (rDbgWord3 & ~{{8{iS_WSTRB[3]}}, {8{iS_WSTRB[2]}},
                                                   {8{iS_WSTRB[1]}}, {8{iS_WSTRB[0]}}}) |
                                   (iS_WDATA & {{8{iS_WSTRB[3]}}, {8{iS_WSTRB[2]}},
                                                {8{iS_WSTRB[1]}}, {8{iS_WSTRB[0]}}});
          endcase
        end
      end
      else if (rBValid && iS_BREADY) begin
        rBValid <= 1'b0;
      end
    end
  end

endmodule
