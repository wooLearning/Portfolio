`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: AxiLiteInterconnect1x3
Role: One-master AXI-Lite address decoder for I-SRAM, D-SRAM, and peripherals
Summary:
  - Routes one AXI-Lite master to three slaves by address window
  - S0: instruction SRAM write/read window, S1: data SRAM, S2: peripheral control window
  - Returns SLVERR for ROM or otherwise unmapped DBus accesses
StateDescription:
  - Error response state is stored for unmapped write/read transactions
[MODULE_INFO_END]
*/
module AxiLiteInterconnect1x3 (
  input  logic        iClk,
  input  logic        iRstn,

  input  logic [31:0] iM_AWADDR,
  input  logic        iM_AWVALID,
  output logic        oM_AWREADY,
  input  logic [31:0] iM_WDATA,
  input  logic [3:0]  iM_WSTRB,
  input  logic        iM_WVALID,
  output logic        oM_WREADY,
  output logic [1:0]  oM_BRESP,
  output logic        oM_BVALID,
  input  logic        iM_BREADY,
  input  logic [31:0] iM_ARADDR,
  input  logic        iM_ARVALID,
  output logic        oM_ARREADY,
  output logic [31:0] oM_RDATA,
  output logic [1:0]  oM_RRESP,
  output logic        oM_RVALID,
  input  logic        iM_RREADY,

  output logic [31:0] oS0_AWADDR,
  output logic        oS0_AWVALID,
  input  logic        iS0_AWREADY,
  output logic [31:0] oS0_WDATA,
  output logic [3:0]  oS0_WSTRB,
  output logic        oS0_WVALID,
  input  logic        iS0_WREADY,
  input  logic [1:0]  iS0_BRESP,
  input  logic        iS0_BVALID,
  output logic        oS0_BREADY,
  output logic [31:0] oS0_ARADDR,
  output logic        oS0_ARVALID,
  input  logic        iS0_ARREADY,
  input  logic [31:0] iS0_RDATA,
  input  logic [1:0]  iS0_RRESP,
  input  logic        iS0_RVALID,
  output logic        oS0_RREADY,

  output logic [31:0] oS1_AWADDR,
  output logic        oS1_AWVALID,
  input  logic        iS1_AWREADY,
  output logic [31:0] oS1_WDATA,
  output logic [3:0]  oS1_WSTRB,
  output logic        oS1_WVALID,
  input  logic        iS1_WREADY,
  input  logic [1:0]  iS1_BRESP,
  input  logic        iS1_BVALID,
  output logic        oS1_BREADY,
  output logic [31:0] oS1_ARADDR,
  output logic        oS1_ARVALID,
  input  logic        iS1_ARREADY,
  input  logic [31:0] iS1_RDATA,
  input  logic [1:0]  iS1_RRESP,
  input  logic        iS1_RVALID,
  output logic        oS1_RREADY,

  output logic [31:0] oS2_AWADDR,
  output logic        oS2_AWVALID,
  input  logic        iS2_AWREADY,
  output logic [31:0] oS2_WDATA,
  output logic [3:0]  oS2_WSTRB,
  output logic        oS2_WVALID,
  input  logic        iS2_WREADY,
  input  logic [1:0]  iS2_BRESP,
  input  logic        iS2_BVALID,
  output logic        oS2_BREADY,
  output logic [31:0] oS2_ARADDR,
  output logic        oS2_ARVALID,
  input  logic        iS2_ARREADY,
  input  logic [31:0] iS2_RDATA,
  input  logic [1:0]  iS2_RRESP,
  input  logic        iS2_RVALID,
  output logic        oS2_RREADY
);

  localparam logic [1:0] LP_SEL_ISRAM  = 2'd0;
  localparam logic [1:0] LP_SEL_DSRAM  = 2'd1;
  localparam logic [1:0] LP_SEL_PERIPH = 2'd2;
  localparam logic [1:0] LP_SEL_ERROR  = 2'd3;

  logic [1:0] wWriteSel;
  logic [1:0] wReadSel;
  logic       rWriteErrorValid;
  logic       rReadErrorValid;

  function automatic logic [1:0] decode_addr(input logic [31:0] iAddr);
    begin
      if (address_map_pkg::in_range(iAddr, axi_lite_pkg::ISRAM_BASE, axi_lite_pkg::ISRAM_SIZE)) begin
        decode_addr = LP_SEL_ISRAM;
      end
      else if (address_map_pkg::in_range(iAddr, axi_lite_pkg::DSRAM_BASE, axi_lite_pkg::DSRAM_SIZE)) begin
        decode_addr = LP_SEL_DSRAM;
      end
      else if (address_map_pkg::in_range(iAddr, axi_lite_pkg::PERIPH_BASE, axi_lite_pkg::PERIPH_SIZE)) begin
        decode_addr = LP_SEL_PERIPH;
      end
      else begin
        decode_addr = LP_SEL_ERROR;
      end
    end
  endfunction

  assign wWriteSel = decode_addr(iM_AWADDR);
  assign wReadSel  = decode_addr(iM_ARADDR);

  assign oS0_AWADDR = iM_AWADDR - axi_lite_pkg::ISRAM_BASE;
  assign oS0_WDATA  = iM_WDATA;
  assign oS0_WSTRB  = iM_WSTRB;
  assign oS0_ARADDR = iM_ARADDR - axi_lite_pkg::ISRAM_BASE;
  assign oS1_AWADDR = iM_AWADDR - axi_lite_pkg::DSRAM_BASE;
  assign oS1_WDATA  = iM_WDATA;
  assign oS1_WSTRB  = iM_WSTRB;
  assign oS1_ARADDR = iM_ARADDR - axi_lite_pkg::DSRAM_BASE;
  assign oS2_AWADDR = iM_AWADDR - axi_lite_pkg::PERIPH_BASE;
  assign oS2_WDATA  = iM_WDATA;
  assign oS2_WSTRB  = iM_WSTRB;
  assign oS2_ARADDR = iM_ARADDR - axi_lite_pkg::PERIPH_BASE;

  assign oS0_AWVALID = iM_AWVALID && (wWriteSel == LP_SEL_ISRAM);
  assign oS0_WVALID  = iM_WVALID  && (wWriteSel == LP_SEL_ISRAM);
  assign oS1_AWVALID = iM_AWVALID && (wWriteSel == LP_SEL_DSRAM);
  assign oS1_WVALID  = iM_WVALID  && (wWriteSel == LP_SEL_DSRAM);
  assign oS2_AWVALID = iM_AWVALID && (wWriteSel == LP_SEL_PERIPH);
  assign oS2_WVALID  = iM_WVALID  && (wWriteSel == LP_SEL_PERIPH);

  always_comb begin
    unique case (wWriteSel)
      LP_SEL_ISRAM: begin
        oM_AWREADY = iS0_AWREADY;
        oM_WREADY  = iS0_WREADY;
      end
      LP_SEL_DSRAM: begin
        oM_AWREADY = iS1_AWREADY;
        oM_WREADY  = iS1_WREADY;
      end
      LP_SEL_PERIPH: begin
        oM_AWREADY = iS2_AWREADY;
        oM_WREADY  = iS2_WREADY;
      end
      default: begin
        oM_AWREADY = !rWriteErrorValid;
        oM_WREADY  = !rWriteErrorValid;
      end
    endcase
  end

  always_comb begin
    oM_BRESP = axi_lite_pkg::RESP_OKAY;
    oM_BVALID = 1'b0;
    oS0_BREADY = 1'b0;
    oS1_BREADY = 1'b0;
    oS2_BREADY = 1'b0;

    if (iS0_BVALID) begin
      oM_BRESP = iS0_BRESP;
      oM_BVALID = iS0_BVALID;
      oS0_BREADY = iM_BREADY;
    end
    else if (iS1_BVALID) begin
      oM_BRESP = iS1_BRESP;
      oM_BVALID = iS1_BVALID;
      oS1_BREADY = iM_BREADY;
    end
    else if (iS2_BVALID) begin
      oM_BRESP = iS2_BRESP;
      oM_BVALID = iS2_BVALID;
      oS2_BREADY = iM_BREADY;
    end
    else if (rWriteErrorValid) begin
      oM_BRESP = axi_lite_pkg::RESP_SLVERR;
      oM_BVALID = 1'b1;
    end
  end

  assign oS0_ARVALID = iM_ARVALID && (wReadSel == LP_SEL_ISRAM);
  assign oS1_ARVALID = iM_ARVALID && (wReadSel == LP_SEL_DSRAM);
  assign oS2_ARVALID = iM_ARVALID && (wReadSel == LP_SEL_PERIPH);

  always_comb begin
    unique case (wReadSel)
      LP_SEL_ISRAM:  oM_ARREADY = iS0_ARREADY;
      LP_SEL_DSRAM:  oM_ARREADY = iS1_ARREADY;
      LP_SEL_PERIPH: oM_ARREADY = iS2_ARREADY;
      default:       oM_ARREADY = !rReadErrorValid;
    endcase
  end

  always_comb begin
    oM_RDATA = 32'd0;
    oM_RRESP = axi_lite_pkg::RESP_OKAY;
    oM_RVALID = 1'b0;
    oS0_RREADY = 1'b0;
    oS1_RREADY = 1'b0;
    oS2_RREADY = 1'b0;

    if (iS0_RVALID) begin
      oM_RDATA = iS0_RDATA;
      oM_RRESP = iS0_RRESP;
      oM_RVALID = iS0_RVALID;
      oS0_RREADY = iM_RREADY;
    end
    else if (iS1_RVALID) begin
      oM_RDATA = iS1_RDATA;
      oM_RRESP = iS1_RRESP;
      oM_RVALID = iS1_RVALID;
      oS1_RREADY = iM_RREADY;
    end
    else if (iS2_RVALID) begin
      oM_RDATA = iS2_RDATA;
      oM_RRESP = iS2_RRESP;
      oM_RVALID = iS2_RVALID;
      oS2_RREADY = iM_RREADY;
    end
    else if (rReadErrorValid) begin
      oM_RDATA = 32'd0;
      oM_RRESP = axi_lite_pkg::RESP_SLVERR;
      oM_RVALID = 1'b1;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rWriteErrorValid <= 1'b0;
      rReadErrorValid  <= 1'b0;
    end
    else begin
      if (rWriteErrorValid && iM_BREADY) begin
        rWriteErrorValid <= 1'b0;
      end

      if (rReadErrorValid && iM_RREADY) begin
        rReadErrorValid <= 1'b0;
      end

      if ((wWriteSel == LP_SEL_ERROR) && iM_AWVALID && iM_WVALID &&
          oM_AWREADY && oM_WREADY) begin
        rWriteErrorValid <= 1'b1;
      end

      if ((wReadSel == LP_SEL_ERROR) && iM_ARVALID && oM_ARREADY) begin
        rReadErrorValid <= 1'b1;
      end
    end
  end

endmodule
