`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: AxiLiteToApbBridge
Role: AXI-Lite slave to APB master bridge
Summary:
  - Converts single-beat AXI-Lite read/write transactions into APB setup/access cycles
  - Keeps APB peripherals as the register/control endpoint behind the AXI fabric
  - Serializes reads and writes to one APB transaction at a time
StateDescription:
  - S_IDLE waits for AXI-Lite address/data
  - S_SETUP drives APB setup phase
  - S_ACCESS waits for PREADY and captures response
  - S_WRITE_RESP/S_READ_RESP returns the AXI-Lite response
[MODULE_INFO_END]
*/
module AxiLiteToApbBridge (
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

  output logic        oPSEL,
  output logic        oPENABLE,
  output logic        oPWRITE,
  output logic [31:0] oPADDR,
  output logic [31:0] oPWDATA,
  output logic [3:0]  oPSTRB,
  input  logic [31:0] iPRDATA,
  input  logic        iPREADY,
  input  logic        iPSLVERR
);

  typedef enum logic [2:0] {
    S_IDLE,
    S_SETUP,
    S_ACCESS,
    S_WRITE_RESP,
    S_READ_RESP
  } state_e;

  state_e      rState;
  logic        rWrite;
  logic [31:0] rAddr;
  logic [31:0] rWData;
  logic [3:0]  rWStrb;
  logic [31:0] rRData;
  logic        rError;
  logic        wWriteAccept;
  logic        wReadAccept;

  assign wWriteAccept = (rState == S_IDLE) && iS_AWVALID && iS_WVALID;
  assign wReadAccept  = (rState == S_IDLE) && !iS_AWVALID && iS_ARVALID;

  assign oS_AWREADY = (rState == S_IDLE) && iS_WVALID;
  assign oS_WREADY  = (rState == S_IDLE) && iS_AWVALID;
  assign oS_BRESP   = rError ? axi_lite_pkg::RESP_SLVERR : axi_lite_pkg::RESP_OKAY;
  assign oS_BVALID  = (rState == S_WRITE_RESP);
  assign oS_ARREADY = (rState == S_IDLE) && !iS_AWVALID;
  assign oS_RDATA   = rRData;
  assign oS_RRESP   = rError ? axi_lite_pkg::RESP_SLVERR : axi_lite_pkg::RESP_OKAY;
  assign oS_RVALID  = (rState == S_READ_RESP);

  assign oPSEL    = (rState == S_SETUP) || (rState == S_ACCESS);
  assign oPENABLE = (rState == S_ACCESS);
  assign oPWRITE  = rWrite;
  assign oPADDR   = rAddr;
  assign oPWDATA  = rWData;
  assign oPSTRB   = rWrite ? rWStrb : 4'b0000;

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rState <= S_IDLE;
      rWrite <= 1'b0;
      rAddr  <= 32'd0;
      rWData <= 32'd0;
      rWStrb <= 4'd0;
      rRData <= 32'd0;
      rError <= 1'b0;
    end
    else begin
      unique case (rState)
        S_IDLE: begin
          rError <= 1'b0;

          if (wWriteAccept) begin
            rState <= S_SETUP;
            rWrite <= 1'b1;
            rAddr  <= iS_AWADDR;
            rWData <= iS_WDATA;
            rWStrb <= iS_WSTRB;
          end
          else if (wReadAccept) begin
            rState <= S_SETUP;
            rWrite <= 1'b0;
            rAddr  <= iS_ARADDR;
            rWData <= 32'd0;
            rWStrb <= 4'd0;
          end
        end

        S_SETUP: begin
          rState <= S_ACCESS;
        end

        S_ACCESS: begin
          if (iPREADY) begin
            rRData <= iPRDATA;
            rError <= iPSLVERR;
            rState <= rWrite ? S_WRITE_RESP : S_READ_RESP;
          end
        end

        S_WRITE_RESP: begin
          if (iS_BREADY) begin
            rState <= S_IDLE;
          end
        end

        S_READ_RESP: begin
          if (iS_RREADY) begin
            rState <= S_IDLE;
          end
        end

        default: begin
          rState <= S_IDLE;
        end
      endcase
    end
  end

endmodule
