`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: AxiLiteMasterAdapter
Role: Converts the core-local valid/ready memory port into an AXI-Lite master
Summary:
  - Supports one outstanding read or write transaction
  - Converts byte/half/word local stores into AXI-Lite WSTRB
  - Keeps the core isolated from AXI-Lite channel timing
StateDescription:
  - S_IDLE waits for a local request
  - S_WRITE waits for AW/W acceptance and B response
  - S_READ waits for AR acceptance and R response
  - S_DONE presents the completed local response
[MODULE_INFO_END]
*/
module AxiLiteMasterAdapter #(
  parameter bit P_READ_ONLY = 1'b0,
  parameter bit P_PRE_READY = 1'b0
) (
  input  logic        iClk,
  input  logic        iRstn,
  input  logic        iLocalValid,
  input  logic        iLocalWrite,
  input  logic [31:0] iLocalAddr,
  input  logic [1:0]  iLocalSize,
  input  logic [31:0] iLocalWData,
  output logic        oLocalReady,
  output logic [31:0] oLocalRData,
  output logic        oLocalError,

  output logic [31:0] oM_AWADDR,
  output logic        oM_AWVALID,
  input  logic        iM_AWREADY,
  output logic [31:0] oM_WDATA,
  output logic [3:0]  oM_WSTRB,
  output logic        oM_WVALID,
  input  logic        iM_WREADY,
  input  logic [1:0]  iM_BRESP,
  input  logic        iM_BVALID,
  output logic        oM_BREADY,
  output logic [31:0] oM_ARADDR,
  output logic        oM_ARVALID,
  input  logic        iM_ARREADY,
  input  logic [31:0] iM_RDATA,
  input  logic [1:0]  iM_RRESP,
  input  logic        iM_RVALID,
  output logic        oM_RREADY
);

  typedef enum logic [1:0] {
    S_IDLE,
    S_WRITE,
    S_READ,
    S_DONE
  } state_e;

  state_e      rState;
  logic        rWrite;
  logic [31:0] rAddr;
  logic [1:0]  rSize;
  logic [31:0] rWData;
  logic [31:0] rRData;
  logic        rError;
  logic        rAwDone;
  logic        rWDone;
  logic        wRequestSame;
  logic        wDoWrite;
  logic        wDoRead;
  logic        wReadPreReady;
  logic        wWritePreReady;
  logic        wPreReady;

  assign wDoWrite = iLocalValid && (P_READ_ONLY ? 1'b0 : iLocalWrite);
  assign wDoRead  = iLocalValid && !wDoWrite;
  assign wRequestSame =
    iLocalValid &&
    (iLocalAddr == rAddr) &&
    (iLocalSize == rSize) &&
    ((P_READ_ONLY ? 1'b0 : iLocalWrite) == rWrite) &&
    (P_READ_ONLY || !iLocalWrite || (iLocalWData == rWData));

  assign oM_AWADDR  = rAddr;
  assign oM_AWVALID = (rState == S_WRITE) && !rAwDone;
  assign oM_WDATA   = rWData;
  assign oM_WSTRB   = axi_lite_pkg::size_to_strb(rSize, rAddr[1:0]);
  assign oM_WVALID  = (rState == S_WRITE) && !rWDone;
  assign oM_BREADY  = (rState == S_WRITE) && rAwDone && rWDone;
  assign oM_ARADDR  = rAddr;
  assign oM_ARVALID = (rState == S_READ);
  assign oM_RREADY  = (rState == S_READ);

  assign wReadPreReady =
    P_PRE_READY &&
    (rState == S_READ) &&
    iM_RVALID &&
    wRequestSame;

  assign wWritePreReady =
    P_PRE_READY &&
    (rState == S_WRITE) &&
    oM_BREADY &&
    iM_BVALID &&
    wRequestSame;

  assign wPreReady   = wReadPreReady || wWritePreReady;
  assign oLocalReady = ((rState == S_DONE) && wRequestSame) || wPreReady;
  assign oLocalRData = wReadPreReady ? iM_RDATA : rRData;
  assign oLocalError = oLocalReady && (wPreReady ?
                       (wReadPreReady ? (iM_RRESP != axi_lite_pkg::RESP_OKAY) :
                                        (iM_BRESP != axi_lite_pkg::RESP_OKAY)) :
                       rError);

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rState  <= S_IDLE;
      rWrite  <= 1'b0;
      rAddr   <= 32'd0;
      rSize   <= 2'b10;
      rWData  <= 32'd0;
      rRData  <= 32'd0;
      rError  <= 1'b0;
      rAwDone <= 1'b0;
      rWDone  <= 1'b0;
    end
    else begin
      unique case (rState)
        S_IDLE: begin
          rAwDone <= 1'b0;
          rWDone  <= 1'b0;

          if (wDoWrite) begin
            rState <= S_WRITE;
            rWrite <= 1'b1;
            rAddr  <= iLocalAddr;
            rSize  <= iLocalSize;
            rWData <= iLocalWData;
            rError <= 1'b0;
          end
          else if (wDoRead) begin
            rState <= S_READ;
            rWrite <= 1'b0;
            rAddr  <= iLocalAddr;
            rSize  <= iLocalSize;
            rWData <= 32'd0;
            rError <= 1'b0;
          end
        end

        S_WRITE: begin
          if (oM_AWVALID && iM_AWREADY) begin
            rAwDone <= 1'b1;
          end

          if (oM_WVALID && iM_WREADY) begin
            rWDone <= 1'b1;
          end

          if (oM_BREADY && iM_BVALID) begin
            rError <= (iM_BRESP != axi_lite_pkg::RESP_OKAY);
            rState <= wWritePreReady ? S_IDLE : S_DONE;
          end
        end

        S_READ: begin
          if (iM_ARREADY && oM_ARVALID) begin
            rState <= S_READ;
          end

          if (iM_RVALID) begin
            rRData <= iM_RDATA;
            rError <= (iM_RRESP != axi_lite_pkg::RESP_OKAY);
            rState <= wReadPreReady ? S_IDLE : S_DONE;
          end
        end

        S_DONE: begin
          if (!wRequestSame) begin
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
