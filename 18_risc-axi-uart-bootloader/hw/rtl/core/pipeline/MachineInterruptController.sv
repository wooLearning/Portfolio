`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: MachineInterruptController
Role: Machine-mode interrupt pending and cause selector for the RV32I pipeline
Summary:
  - Builds the architectural mip value from software-visible mip state and raw IRQ inputs
  - Applies mstatus.MIE and mie masks
  - Selects one machine interrupt cause with external > timer > software priority
StateDescription:
  - Combinational only: interrupt CSR state is stored in CsrFile
[MODULE_INFO_END]
*/
module MachineInterruptController (
  input  logic        iSoftwareIrq,
  input  logic        iTimerIrq,
  input  logic        iExternalIrq,
  input  logic [31:0] iMstatus,
  input  logic [31:0] iMie,
  input  logic [31:0] iMipSw,
  output logic [31:0] oMip,
  output logic        oInterruptPending,
  output logic [3:0]  oInterruptCause
);

  logic [31:0] wIrqMask;

  assign oMip = (iMipSw & 32'h0000_0888) |
                (iSoftwareIrq ? (32'd1 << rv32i_pkg::LP_IRQ_MSIP_BIT) : 32'd0) |
                (iTimerIrq    ? (32'd1 << rv32i_pkg::LP_IRQ_MTIP_BIT) : 32'd0) |
                (iExternalIrq ? (32'd1 << rv32i_pkg::LP_IRQ_MEIP_BIT) : 32'd0);

  assign wIrqMask = iMie & oMip;

  always_comb begin
    oInterruptPending = 1'b0;
    oInterruptCause   = rv32i_pkg::IRQ_SOFTWARE;

    if (iMstatus[rv32i_pkg::LP_MSTATUS_MIE_BIT]) begin
      if (wIrqMask[rv32i_pkg::LP_IRQ_MEIP_BIT]) begin
        oInterruptPending = 1'b1;
        oInterruptCause   = rv32i_pkg::IRQ_EXTERNAL;
      end
      else if (wIrqMask[rv32i_pkg::LP_IRQ_MTIP_BIT]) begin
        oInterruptPending = 1'b1;
        oInterruptCause   = rv32i_pkg::IRQ_TIMER;
      end
      else if (wIrqMask[rv32i_pkg::LP_IRQ_MSIP_BIT]) begin
        oInterruptPending = 1'b1;
        oInterruptCause   = rv32i_pkg::IRQ_SOFTWARE;
      end
    end
  end

endmodule
