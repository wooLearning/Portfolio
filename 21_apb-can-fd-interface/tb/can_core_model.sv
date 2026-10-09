`timescale 1ns/1ps
`default_nettype none

// Behavioral completion model only. It does not implement CAN bits or timing.
module can_core_model (
  input wire logic iClk, iRstN,
  input  wire logic                iAllow,
  input  wire logic [7:0]          iLatency,
  input  wire logic                iFail,
  input  wire logic                iTxValid,
  output      logic                oTxReady,
  output      logic                oTxDone,
  output      logic                oTxError
);
  logic rBusy, rFail;
  logic [7:0] rRemaining;
  assign oTxReady = iAllow && !rBusy;
  always_ff @(posedge iClk or negedge iRstN) begin
    if (!iRstN) begin
      rBusy <= 0;
      rFail <= 0;
      rRemaining <= 0;
      oTxDone <= 0;
      oTxError <= 0;
    end
    else begin
      oTxDone <= 0;
      oTxError <= 0;
      if (iTxValid && oTxReady) begin
        rBusy <= 1;
        rFail <= iFail;
        rRemaining <= (iLatency == 0) ? 1 : iLatency;
      end
      else if (rBusy) begin
        if (rRemaining == 1) begin
          rBusy <= 0;
          oTxDone <= 1;
          oTxError <= rFail;
        end
        else rRemaining <= rRemaining - 1'b1;
      end
    end
  end
endmodule

`default_nettype wire
