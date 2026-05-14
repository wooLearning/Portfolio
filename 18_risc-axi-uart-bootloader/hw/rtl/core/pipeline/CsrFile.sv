`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: CsrFile
Role: Minimal machine-mode CSR file and trap state for the RV32I pipeline
Summary:
  - Implements mstatus, mie, mtvec, mepc, mcause, mtval, and mip
  - Handles exception/interrupt trap entry and mret interrupt-enable restore
  - Exposes machine interrupt CSRs to the separate interrupt controller
StateDescription:
  - CSR state updates on CSR write, trap entry, mret, and reset
[MODULE_INFO_END]
*/
module CsrFile #(
  parameter bit P_ENABLE_MTVEC_VECTORED = 1'b0
) (
  input  logic                   iClk,
  input  logic                   iRstn,
  input  logic [11:0]            iCsrAddr,
  input  rv32i_pkg::csr_op_e     iCsrOp,
  input  logic [31:0]            iCsrWrData,
  input  logic                   iCsrWriteEn,
  input  logic                   iTrapEn,
  input  logic                   iTrapIsInterrupt,
  input  logic [31:0]            iTrapPc,
  input  logic [3:0]             iTrapCause,
  input  logic [31:0]            iTrapTval,
  input  logic                   iMretEn,
  input  logic [31:0]            iMip,
  output logic [31:0]            oCsrRdData,
  output logic                   oCsrAddrValid,
  output logic [31:0]            oMstatus,
  output logic [31:0]            oMie,
  output logic [31:0]            oMtvec,
  output logic [31:0]            oMepc,
  output logic [31:0]            oMcause,
  output logic [31:0]            oMtval,
  output logic [31:0]            oMipSw
);

  logic [31:0] rMstatus;
  logic [31:0] rMie;
  logic [31:0] rMtvec;
  logic [31:0] rMepc;
  logic [31:0] rMcause;
  logic [31:0] rMtval;
  logic [31:0] rMipSw;
  logic [31:0] wCsrNextData;
  logic        wCsrWriteAllowed;

  assign wCsrWriteAllowed = iCsrWriteEn && oCsrAddrValid;

  assign oMstatus = rMstatus;
  assign oMie     = rMie;
  assign oMtvec  = rMtvec;
  assign oMepc   = rMepc;
  assign oMcause = rMcause;
  assign oMtval  = rMtval;
  assign oMipSw  = rMipSw;

  always_comb begin
    oCsrAddrValid = 1'b1;
    oCsrRdData    = 32'd0;

    unique case (iCsrAddr)
      rv32i_pkg::LP_CSR_MSTATUS: oCsrRdData = rMstatus;
      rv32i_pkg::LP_CSR_MIE:     oCsrRdData = rMie;
      rv32i_pkg::LP_CSR_MTVEC:   oCsrRdData = rMtvec;
      rv32i_pkg::LP_CSR_MEPC:    oCsrRdData = rMepc;
      rv32i_pkg::LP_CSR_MCAUSE:  oCsrRdData = rMcause;
      rv32i_pkg::LP_CSR_MTVAL:   oCsrRdData = rMtval;
      rv32i_pkg::LP_CSR_MIP:     oCsrRdData = iMip;
      default: begin
        oCsrAddrValid = 1'b0;
        oCsrRdData    = 32'd0;
      end
    endcase
  end

  always_comb begin
    unique case (iCsrOp)
      rv32i_pkg::CSR_RW,
      rv32i_pkg::CSR_RWI: wCsrNextData = iCsrWrData;
      rv32i_pkg::CSR_RS,
      rv32i_pkg::CSR_RSI: wCsrNextData = oCsrRdData | iCsrWrData;
      rv32i_pkg::CSR_RC,
      rv32i_pkg::CSR_RCI: wCsrNextData = oCsrRdData & ~iCsrWrData;
      default:            wCsrNextData = oCsrRdData;
    endcase
  end

  function automatic logic [31:0] normalize_mtvec(input logic [31:0] iData);
    begin
      normalize_mtvec = {iData[31:2], 2'b00};

      if (P_ENABLE_MTVEC_VECTORED && (iData[1:0] == 2'b01)) begin
        normalize_mtvec[1:0] = 2'b01;
      end
    end
  endfunction

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rMstatus <= 32'd0;
      rMie     <= 32'd0;
      rMtvec   <= 32'h0000_0080;
      rMepc    <= 32'd0;
      rMcause  <= 32'd0;
      rMtval   <= 32'd0;
      rMipSw   <= 32'd0;
    end
    else begin
      if (iTrapEn) begin
        rMstatus[rv32i_pkg::LP_MSTATUS_MPIE_BIT] <= rMstatus[rv32i_pkg::LP_MSTATUS_MIE_BIT];
        rMstatus[rv32i_pkg::LP_MSTATUS_MIE_BIT]  <= 1'b0;
        rMepc   <= {iTrapPc[31:2], 2'b00};
        rMcause <= {iTrapIsInterrupt, 27'd0, iTrapCause};
        rMtval  <= iTrapTval;
      end
      else if (iMretEn) begin
        rMstatus[rv32i_pkg::LP_MSTATUS_MIE_BIT]  <= rMstatus[rv32i_pkg::LP_MSTATUS_MPIE_BIT];
        rMstatus[rv32i_pkg::LP_MSTATUS_MPIE_BIT] <= 1'b1;
      end
      else if (wCsrWriteAllowed) begin
        unique case (iCsrAddr)
          rv32i_pkg::LP_CSR_MSTATUS: begin
            rMstatus[rv32i_pkg::LP_MSTATUS_MIE_BIT]  <= wCsrNextData[rv32i_pkg::LP_MSTATUS_MIE_BIT];
            rMstatus[rv32i_pkg::LP_MSTATUS_MPIE_BIT] <= wCsrNextData[rv32i_pkg::LP_MSTATUS_MPIE_BIT];
          end
          rv32i_pkg::LP_CSR_MIE: begin
            rMie <= wCsrNextData & 32'h0000_0888;
          end
          rv32i_pkg::LP_CSR_MTVEC: begin
            rMtvec <= normalize_mtvec(wCsrNextData);
          end
          rv32i_pkg::LP_CSR_MEPC: begin
            rMepc <= {wCsrNextData[31:2], 2'b00};
          end
          rv32i_pkg::LP_CSR_MCAUSE: begin
            rMcause <= wCsrNextData;
          end
          rv32i_pkg::LP_CSR_MTVAL: begin
            rMtval <= wCsrNextData;
          end
          rv32i_pkg::LP_CSR_MIP: begin
            rMipSw <= wCsrNextData & 32'h0000_0888;
          end
          default: begin end
        endcase
      end
    end
  end

endmodule
