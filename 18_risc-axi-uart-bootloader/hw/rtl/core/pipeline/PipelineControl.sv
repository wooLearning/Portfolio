`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: PipelineControl
Role: Central stall, flush, and PC redirect control for the RV32I pipeline
Summary:
  - Combines bus wait and load-use stall decisions
  - Arbitrates EX redirects, ID early redirects, and PC write enables
  - Registers EX/ID redirect requests to preserve the original Rv32Core timing
StateDescription:
  - rExRedirect holds a registered EX-stage redirect
  - rIdJalRedirect/rIdBranchRedirect hold registered ID early redirects
[MODULE_INFO_END]
*/
module PipelineControl (
  input  logic        iClk,
  input  logic        iRstn,
  input  logic        iFetchWaitStall,
  input  logic        iDataWaitStall,
  input  logic        iLoadUseStall,
  input  logic        iTrapRedirectEn,
  input  logic [31:0] iTrapRedirectTarget,
  input  logic        iExPcRedirectEn,
  input  logic [31:0] iExPcRedirectTarget,
  input  logic        iIdJalCandidate,
  input  logic        iIdJalX0Candidate,
  input  logic        iIdBranchCandidate,
  input  logic [31:0] iIdJalTarget,
  input  logic [31:0] iIdBranchTarget,
  output logic        oBusWaitStall,
  output logic        oPipelineStall,
  output logic        oPcWriteEn,
  output logic        oPcTargetEn,
  output logic [31:0] oPcTarget,
  output logic        oIfIdFlush,
  output logic        oIfIdWriteEn,
  output logic        oIdExFlush,
  output logic        oIdExHold,
  output logic        oExMemHold,
  output logic        oMemWbHold,
  output logic        oExRedirectPending,
  output logic        oIdJalRedirectEn,
  output logic        oIdJalX0RedirectEn,
  output logic        oIdBranchRedirectEn
);

  logic        rExRedirectEn;
  logic [31:0] rExRedirectTarget;
  logic        rTrapRedirectEn;
  logic [31:0] rTrapRedirectTarget;
  logic        rIdJalRedirectEn;
  logic [31:0] rIdJalRedirectTarget;
  logic        rIdBranchRedirectEn;
  logic [31:0] rIdBranchRedirectTarget;

  assign oBusWaitStall  = iFetchWaitStall || iDataWaitStall;
  assign oPipelineStall = iLoadUseStall || oBusWaitStall;

  assign oIdJalX0RedirectEn =
    iIdJalX0Candidate &&
    !rTrapRedirectEn &&
    !rExRedirectEn &&
    !rIdJalRedirectEn &&
    !rIdBranchRedirectEn &&
    !oPipelineStall;

  assign oIdJalRedirectEn =
    iIdJalCandidate &&
    !rTrapRedirectEn &&
    !rExRedirectEn &&
    !rIdJalRedirectEn &&
    !rIdBranchRedirectEn &&
    !iTrapRedirectEn &&
    !iExPcRedirectEn &&
    !oPipelineStall;

  assign oIdBranchRedirectEn =
    iIdBranchCandidate &&
    !rTrapRedirectEn &&
    !rExRedirectEn &&
    !rIdJalRedirectEn &&
    !rIdBranchRedirectEn &&
    !iTrapRedirectEn &&
    !iExPcRedirectEn &&
    !oPipelineStall;

  assign oPcTargetEn =
    rTrapRedirectEn ||
    rExRedirectEn ||
    oIdJalX0RedirectEn ||
    rIdJalRedirectEn ||
    rIdBranchRedirectEn;

  assign oPcTarget =
    rTrapRedirectEn ? rTrapRedirectTarget :
    rExRedirectEn ? rExRedirectTarget :
    oIdJalX0RedirectEn ? iIdJalTarget :
    rIdJalRedirectEn ? rIdJalRedirectTarget : rIdBranchRedirectTarget;

  assign oPcWriteEn        = oPcTargetEn || !oPipelineStall;
  assign oIfIdFlush        = oPcTargetEn;
  assign oIfIdWriteEn      = !oPipelineStall;
  assign oIdExFlush        = oPcTargetEn || (!oBusWaitStall && iLoadUseStall);
  assign oIdExHold         = oBusWaitStall;
  assign oExMemHold        = oBusWaitStall;
  assign oMemWbHold        = oBusWaitStall;
  assign oExRedirectPending = rTrapRedirectEn || rExRedirectEn;

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rExRedirectEn         <= 1'b0;
      rExRedirectTarget     <= 32'd0;
      rTrapRedirectEn       <= 1'b0;
      rTrapRedirectTarget   <= 32'd0;
      rIdJalRedirectEn      <= 1'b0;
      rIdJalRedirectTarget  <= 32'd0;
      rIdBranchRedirectEn   <= 1'b0;
      rIdBranchRedirectTarget <= 32'd0;
    end
    else begin
      rTrapRedirectEn     <= iTrapRedirectEn && !rTrapRedirectEn && !oBusWaitStall;
      rTrapRedirectTarget <= iTrapRedirectTarget;

      rExRedirectEn     <= !iTrapRedirectEn && iExPcRedirectEn &&
                            !rTrapRedirectEn && !rExRedirectEn && !oBusWaitStall;
      rExRedirectTarget <= iExPcRedirectTarget;

      rIdJalRedirectEn     <= oIdJalRedirectEn && !rTrapRedirectEn && !rExRedirectEn;
      rIdJalRedirectTarget <= iIdJalTarget;

      rIdBranchRedirectEn     <= oIdBranchRedirectEn && !rTrapRedirectEn && !rExRedirectEn;
      rIdBranchRedirectTarget <= iIdBranchTarget;
    end
  end

endmodule
