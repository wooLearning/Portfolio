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
  logic        wNoRedirPending;
  logic        wIdJalX0Ok;
  logic        wIdRedirOk;

  // 버스 대기는 hold, load-use는 bubble로 처리한다.
  assign oBusWaitStall  = iFetchWaitStall || iDataWaitStall;
  assign oPipelineStall = iLoadUseStall || oBusWaitStall;

  // 대기 중인 redirect가 없는 상태.
  assign wNoRedirPending =
    !rTrapRedirectEn &&
    !rExRedirectEn &&
    !rIdJalRedirectEn &&
    !rIdBranchRedirectEn;

  // ID 단계 redirect 허용 조건.
  assign wIdJalX0Ok =
    wNoRedirPending &&
    !oPipelineStall;

  // 일반 ID redirect는 같은 cycle의 trap/ex redirect도 없어야 한다.
  assign wIdRedirOk =
    wNoRedirPending &&
    !iTrapRedirectEn &&
    !iExPcRedirectEn &&
    !oPipelineStall;

  // 최종 허용된 ID 단계 redirect.
  assign oIdJalX0RedirectEn =
    iIdJalX0Candidate &&
    wIdJalX0Ok;

  assign oIdJalRedirectEn =
    iIdJalCandidate &&
    wIdRedirOk;

  assign oIdBranchRedirectEn =
    iIdBranchCandidate &&
    wIdRedirOk;

  // FetchStage로 보낼 최종 PC redirect. 우선순위: trap > EX > ID.
  assign oPcTargetEn =
    rTrapRedirectEn ||
    rExRedirectEn ||
    oIdJalX0RedirectEn ||
    rIdJalRedirectEn ||
    rIdBranchRedirectEn;

  // 위 우선순위에 맞춘 redirect target mux.
  assign oPcTarget =
    rTrapRedirectEn ? rTrapRedirectTarget :
    rExRedirectEn ? rExRedirectTarget :
    oIdJalX0RedirectEn ? iIdJalTarget :
    rIdJalRedirectEn ? rIdJalRedirectTarget : rIdBranchRedirectTarget;

  // redirect가 있거나 stall이 아니면 PC를 갱신한다.
  assign oPcWriteEn        = oPcTargetEn || !oPipelineStall;

  // redirect 시 잘못 fetch된 앞단 packet을 버린다.
  assign oIfIdFlush        = oPcTargetEn;

  // stall이 아니면 IF/ID가 새 fetch packet을 받는다.
  assign oIfIdWriteEn      = !oPipelineStall;

  // redirect/load-use 때 ID/EX에 bubble을 넣는다.
  assign oIdExFlush        = oPcTargetEn || (!oBusWaitStall && iLoadUseStall);

  // 버스 대기 중에는 뒤쪽 pipeline register를 hold한다.
  assign oIdExHold         = oBusWaitStall;
  assign oExMemHold        = oBusWaitStall;
  assign oMemWbHold        = oBusWaitStall;

  // trap/EX redirect 대기 중 side effect를 막는 표시.
  assign oExRedirectPending = rTrapRedirectEn || rExRedirectEn;

  // 허용된 redirect를 register에 잡아 PC mux로 보낸다.
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
      // trap redirect가 최우선.
      rTrapRedirectEn     <= iTrapRedirectEn && !rTrapRedirectEn && !oBusWaitStall;
      rTrapRedirectTarget <= iTrapRedirectTarget;

      // EX redirect는 trap/EX pending이 없을 때만 잡는다.
      rExRedirectEn     <= !iTrapRedirectEn && iExPcRedirectEn &&
                            !rTrapRedirectEn && !rExRedirectEn && !oBusWaitStall;
      rExRedirectTarget <= iExPcRedirectTarget;

      // ID redirect는 trap/EX pending 뒤에서는 버린다.
      rIdJalRedirectEn     <= oIdJalRedirectEn && !rTrapRedirectEn && !rExRedirectEn;
      rIdJalRedirectTarget <= iIdJalTarget;

      rIdBranchRedirectEn     <= oIdBranchRedirectEn && !rTrapRedirectEn && !rExRedirectEn;
      rIdBranchRedirectTarget <= iIdBranchTarget;
    end
  end

endmodule
