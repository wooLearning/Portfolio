`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: AxiLiteArbiter2x1
Role: Two-master, one-slave AXI-Lite arbiter
Summary:
  - Arbitrates CPU and DMA AXI-Lite masters into one SRAM slave
  - Holds write ownership from AW/W acceptance through B response
  - Holds read ownership from AR acceptance through R response
  - Gives master 0 priority while idle
StateDescription:
  - Write and read channels have independent transaction-granular grants
[MODULE_INFO_END]
*/
module AxiLiteArbiter2x1 (
  input  logic        iClk,
  input  logic        iRstn,

  input  logic [31:0] iM0_AWADDR,
  input  logic        iM0_AWVALID,
  output logic        oM0_AWREADY,
  input  logic [31:0] iM0_WDATA,
  input  logic [3:0]  iM0_WSTRB,
  input  logic        iM0_WVALID,
  output logic        oM0_WREADY,
  output logic [1:0]  oM0_BRESP,
  output logic        oM0_BVALID,
  input  logic        iM0_BREADY,
  input  logic [31:0] iM0_ARADDR,
  input  logic        iM0_ARVALID,
  output logic        oM0_ARREADY,
  output logic [31:0] oM0_RDATA,
  output logic [1:0]  oM0_RRESP,
  output logic        oM0_RVALID,
  input  logic        iM0_RREADY,

  input  logic [31:0] iM1_AWADDR,
  input  logic        iM1_AWVALID,
  output logic        oM1_AWREADY,
  input  logic [31:0] iM1_WDATA,
  input  logic [3:0]  iM1_WSTRB,
  input  logic        iM1_WVALID,
  output logic        oM1_WREADY,
  output logic [1:0]  oM1_BRESP,
  output logic        oM1_BVALID,
  input  logic        iM1_BREADY,
  input  logic [31:0] iM1_ARADDR,
  input  logic        iM1_ARVALID,
  output logic        oM1_ARREADY,
  output logic [31:0] oM1_RDATA,
  output logic [1:0]  oM1_RRESP,
  output logic        oM1_RVALID,
  input  logic        iM1_RREADY,

  output logic [31:0] oS_AWADDR,
  output logic        oS_AWVALID,
  input  logic        iS_AWREADY,
  output logic [31:0] oS_WDATA,
  output logic [3:0]  oS_WSTRB,
  output logic        oS_WVALID,
  input  logic        iS_WREADY,
  input  logic [1:0]  iS_BRESP,
  input  logic        iS_BVALID,
  output logic        oS_BREADY,
  output logic [31:0] oS_ARADDR,
  output logic        oS_ARVALID,
  input  logic        iS_ARREADY,
  input  logic [31:0] iS_RDATA,
  input  logic [1:0]  iS_RRESP,
  input  logic        iS_RVALID,
  output logic        oS_RREADY
);

  typedef enum logic [1:0] {
    OWNER_NONE,
    OWNER_M0,
    OWNER_M1
  } owner_e;

  owner_e rWriteOwner;
  owner_e rReadOwner;
  logic   rWriteAwDone;
  logic   rWriteWDone;
  logic   wM0WriteReq;
  logic   wM1WriteReq;
  logic   wM0ReadReq;
  logic   wM1ReadReq;
  owner_e wWriteOwnerSel;
  owner_e wReadOwnerSel;

  assign wM0WriteReq = iM0_AWVALID && iM0_WVALID;
  assign wM1WriteReq = iM1_AWVALID && iM1_WVALID;
  assign wM0ReadReq  = iM0_ARVALID;
  assign wM1ReadReq  = iM1_ARVALID;

  always_comb begin
    wWriteOwnerSel = rWriteOwner;

    if (rWriteOwner == OWNER_NONE) begin
      if (wM0WriteReq) begin
        wWriteOwnerSel = OWNER_M0;
      end
      else if (wM1WriteReq) begin
        wWriteOwnerSel = OWNER_M1;
      end
    end
  end

  always_comb begin
    wReadOwnerSel = rReadOwner;

    if (rReadOwner == OWNER_NONE) begin
      if (wM0ReadReq) begin
        wReadOwnerSel = OWNER_M0;
      end
      else if (wM1ReadReq) begin
        wReadOwnerSel = OWNER_M1;
      end
    end
  end

  always_comb begin
    oS_AWADDR   = 32'd0;
    oS_AWVALID  = 1'b0;
    oS_WDATA    = 32'd0;
    oS_WSTRB    = 4'd0;
    oS_WVALID   = 1'b0;
    oS_BREADY   = 1'b0;
    oM0_AWREADY = 1'b0;
    oM0_WREADY  = 1'b0;
    oM0_BRESP   = axi_lite_pkg::RESP_OKAY;
    oM0_BVALID  = 1'b0;
    oM1_AWREADY = 1'b0;
    oM1_WREADY  = 1'b0;
    oM1_BRESP   = axi_lite_pkg::RESP_OKAY;
    oM1_BVALID  = 1'b0;

    unique case (wWriteOwnerSel)
      OWNER_M0: begin
        oS_AWADDR   = iM0_AWADDR;
        oS_AWVALID  = iM0_AWVALID && !rWriteAwDone;
        oS_WDATA    = iM0_WDATA;
        oS_WSTRB    = iM0_WSTRB;
        oS_WVALID   = iM0_WVALID && !rWriteWDone;
        oS_BREADY   = iM0_BREADY;
        oM0_AWREADY = iS_AWREADY && !rWriteAwDone;
        oM0_WREADY  = iS_WREADY && !rWriteWDone;
        oM0_BRESP   = iS_BRESP;
        oM0_BVALID  = iS_BVALID && rWriteAwDone && rWriteWDone;
      end

      OWNER_M1: begin
        oS_AWADDR   = iM1_AWADDR;
        oS_AWVALID  = iM1_AWVALID && !rWriteAwDone;
        oS_WDATA    = iM1_WDATA;
        oS_WSTRB    = iM1_WSTRB;
        oS_WVALID   = iM1_WVALID && !rWriteWDone;
        oS_BREADY   = iM1_BREADY;
        oM1_AWREADY = iS_AWREADY && !rWriteAwDone;
        oM1_WREADY  = iS_WREADY && !rWriteWDone;
        oM1_BRESP   = iS_BRESP;
        oM1_BVALID  = iS_BVALID && rWriteAwDone && rWriteWDone;
      end

      default: begin
      end
    endcase
  end

  always_comb begin
    oS_ARADDR   = 32'd0;
    oS_ARVALID  = 1'b0;
    oS_RREADY   = 1'b0;
    oM0_ARREADY = 1'b0;
    oM0_RDATA   = 32'd0;
    oM0_RRESP   = axi_lite_pkg::RESP_OKAY;
    oM0_RVALID  = 1'b0;
    oM1_ARREADY = 1'b0;
    oM1_RDATA   = 32'd0;
    oM1_RRESP   = axi_lite_pkg::RESP_OKAY;
    oM1_RVALID  = 1'b0;

    unique case (wReadOwnerSel)
      OWNER_M0: begin
        oS_ARADDR   = iM0_ARADDR;
        oS_ARVALID  = iM0_ARVALID && (rReadOwner == OWNER_NONE);
        oS_RREADY   = iM0_RREADY;
        oM0_ARREADY = iS_ARREADY && (rReadOwner == OWNER_NONE);
        oM0_RDATA   = iS_RDATA;
        oM0_RRESP   = iS_RRESP;
        oM0_RVALID  = iS_RVALID && (rReadOwner == OWNER_M0);
      end

      OWNER_M1: begin
        oS_ARADDR   = iM1_ARADDR;
        oS_ARVALID  = iM1_ARVALID && (rReadOwner == OWNER_NONE);
        oS_RREADY   = iM1_RREADY;
        oM1_ARREADY = iS_ARREADY && (rReadOwner == OWNER_NONE);
        oM1_RDATA   = iS_RDATA;
        oM1_RRESP   = iS_RRESP;
        oM1_RVALID  = iS_RVALID && (rReadOwner == OWNER_M1);
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rWriteOwner  <= OWNER_NONE;
      rReadOwner   <= OWNER_NONE;
      rWriteAwDone <= 1'b0;
      rWriteWDone  <= 1'b0;
    end
    else begin
      if (rWriteOwner == OWNER_NONE) begin
        rWriteOwner  <= wWriteOwnerSel;
        rWriteAwDone <= oS_AWVALID && iS_AWREADY;
        rWriteWDone  <= oS_WVALID && iS_WREADY;
      end
      else begin
        if (oS_AWVALID && iS_AWREADY) begin
          rWriteAwDone <= 1'b1;
        end

        if (oS_WVALID && iS_WREADY) begin
          rWriteWDone <= 1'b1;
        end

        if (iS_BVALID && oS_BREADY && rWriteAwDone && rWriteWDone) begin
          rWriteOwner  <= OWNER_NONE;
          rWriteAwDone <= 1'b0;
          rWriteWDone  <= 1'b0;
        end
      end

      if (rReadOwner == OWNER_NONE) begin
        if ((wReadOwnerSel != OWNER_NONE) && iS_ARREADY) begin
          rReadOwner <= wReadOwnerSel;
        end
      end
      else if (iS_RVALID && oS_RREADY) begin
        rReadOwner <= OWNER_NONE;
      end
    end
  end

endmodule
