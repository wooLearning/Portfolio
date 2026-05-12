`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: TrapController
Role: Central trap and interrupt selection logic for the RV32I pipeline
Summary:
  - Qualifies machine interrupt entry from CSR pending state and pipeline state
  - Selects one trap source with MEM trap > EX trap > IRQ priority
  - Produces CSR trap record fields, mtvec trap target, and PC redirect controls
StateDescription:
  - Combinational only: trap architectural state is stored in CsrFile
[MODULE_INFO_END]
*/
module TrapController #(
  parameter bit P_ENABLE_MTVEC_VECTORED = 1'b0
) (
  input  logic        iInterruptPending,
  input  logic [3:0]  iInterruptCause,
  input  logic [31:0] iMtvec,
  input  logic        iBusWaitStall,
  input  logic        iExRedirectPending,
  input  logic        iMemTrapEn,
  input  logic [3:0]  iMemTrapCause,
  input  logic [31:0] iMemTrapTval,
  input  logic [31:0] iMemTrapPc,
  input  logic        iExTrapEn,
  input  logic [3:0]  iExTrapCause,
  input  logic [31:0] iExTrapTval,
  input  logic [31:0] iExTrapPc,
  input  logic        iExPcRedirectEn,
  input  logic [31:0] iExPcRedirectTarget,
  input  logic [31:0] iFetchPc,
  output logic        oIrqTrapEn,
  output logic        oTrapEn,
  output logic        oTrapIsInterrupt,
  output logic [3:0]  oTrapCause,
  output logic [31:0] oTrapPc,
  output logic [31:0] oTrapTval,
  output logic        oTrapRedirectEn,
  output logic [31:0] oTrapRedirectTarget,
  output logic        oExOnlyPcRedirectEn,
  output logic [31:0] oExOnlyPcRedirectTarget
);

  logic [31:0] wMtvecBase;
  logic        wMtvecVectored;

  assign oIrqTrapEn =
    iInterruptPending &&
    !iBusWaitStall &&
    !iExRedirectPending &&
    !iMemTrapEn &&
    !iExTrapEn &&
    !iExPcRedirectEn;

  assign oTrapEn               = iMemTrapEn || iExTrapEn || oIrqTrapEn;
  assign oTrapIsInterrupt      = oIrqTrapEn;
  assign oTrapRedirectEn       = oTrapEn;
  assign oExOnlyPcRedirectEn   = iExPcRedirectEn && !iExTrapEn;
  assign oExOnlyPcRedirectTarget = iExPcRedirectTarget;
  assign wMtvecBase            = {iMtvec[31:2], 2'b00};
  assign wMtvecVectored        = P_ENABLE_MTVEC_VECTORED && (iMtvec[1:0] == 2'b01);
  assign oTrapRedirectTarget =
    (oTrapIsInterrupt && wMtvecVectored) ?
    (wMtvecBase + {26'd0, oTrapCause, 2'b00}) : wMtvecBase;

  always_comb begin
    oTrapCause = iInterruptCause;
    oTrapPc    = iFetchPc;
    oTrapTval  = 32'd0;

    if (iMemTrapEn) begin
      oTrapCause = iMemTrapCause;
      oTrapPc    = iMemTrapPc;
      oTrapTval  = iMemTrapTval;
    end
    else if (iExTrapEn) begin
      oTrapCause = iExTrapCause;
      oTrapPc    = iExTrapPc;
      oTrapTval  = iExTrapTval;
    end
  end

endmodule
