`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ExecuteStage
Role: RTL module implementing the RV32I pipeline execute-stage combinational datapath/control
Summary:
  - Computes ALU, branch, jump, CSR write, exception, and non-memory write-back data
  - Keeps EX-stage redirect/trap behavior isolated from pipeline register control in Top
StateDescription:
  - Combinational only: no internal state
[MODULE_INFO_END]
*/
module ExecuteStage (
  input  logic                    iValid,
  input  logic                    iPcRedirectPending,
  input  logic                    iInstrAccessFault,
  input  logic                    iPredictedTaken,
  input  logic                    iEarlyJal,
  input  logic                    iEarlyBranch,
  input  logic                    iIllegal,
  input  logic                    iCsrAddrValid,
  input  logic [31:0]             iInstr,
  input  logic [31:0]             iPc,
  input  logic [31:0]             iPcPlus4,
  input  logic [31:0]             iPredictedTarget,
  input  logic [31:0]             iImm,
  input  logic [31:0]             iRs1Data,
  input  logic [31:0]             iRs2Data,
  input  logic [4:0]              iRs1Addr,
  input  logic                    iAluSrc,
  input  rv32i_pkg::alu_op_e      iAluOp,
  input  rv32i_pkg::wb_sel_e      iWbSel,
  input  rv32i_pkg::load_type_e   iLoadType,
  input  rv32i_pkg::store_type_e  iStoreType,
  input  rv32i_pkg::branch_e      iBranchType,
  input  rv32i_pkg::jump_e        iJumpType,
  input  rv32i_pkg::csr_op_e      iCsrOp,
  input  rv32i_pkg::sys_op_e      iSysOp,
  input  logic [31:0]             iCsrRdData,
  input  logic [31:0]             iCsrMtvec,
  input  logic [31:0]             iCsrMepc,
  output logic [31:0]             oAluResult,
  output logic [31:0]             oStoreData,
  output logic [31:0]             oWbDataNonMem,
  output logic                    oBranchTaken,
  output logic                    oPcRedirectEn,
  output logic [31:0]             oPcRedirectTarget,
  output logic                    oTrapEn,
  output rv32i_pkg::exc_cause_e   oTrapCause,
  output logic [31:0]             oTrapTval,
  output logic                    oMretEn,
  output logic [11:0]             oCsrAddr,
  output logic [31:0]             oCsrWrOperand,
  output logic                    oCsrWriteEn
);

  logic [31:0] wAluOperandB;
  logic [31:0] wPcPlusImm;
  logic [31:0] wControlRedirectTarget;
  logic        wEq;
  logic        wLtSigned;
  logic        wLtUnsigned;
  logic        wCsrInstr;
  logic [31:0] wCsrZimm;
  logic        wCsrRs1IsZero;
  logic        wLoadMisaligned;
  logic        wStoreMisaligned;
  logic        wInstrTargetMisaligned;
  logic        wBranchInstr;
  logic        wBranchMispredict;

  Alu uAlu (
    .iA      (iRs1Data),
    .iB      (wAluOperandB),
    .iAluOp  (iAluOp),
    .oResult (oAluResult)
  );

  assign wAluOperandB = iAluSrc ? iImm : iRs2Data;
  assign wPcPlusImm   = iPc + iImm;
  assign oStoreData   = iRs2Data;
  assign wEq          = (iRs1Data == iRs2Data);
  assign wLtSigned    = ($signed(iRs1Data) < $signed(iRs2Data));
  assign wLtUnsigned  = (iRs1Data < iRs2Data);

  always_comb begin
    oBranchTaken = 1'b0;

    unique case (iBranchType)
      rv32i_pkg::BR_BEQ:  oBranchTaken = wEq;
      rv32i_pkg::BR_BNE:  oBranchTaken = !wEq;
      rv32i_pkg::BR_BLT:  oBranchTaken = wLtSigned;
      rv32i_pkg::BR_BGE:  oBranchTaken = !wLtSigned;
      rv32i_pkg::BR_BLTU: oBranchTaken = wLtUnsigned;
      rv32i_pkg::BR_BGEU: oBranchTaken = !wLtUnsigned;
      default:            oBranchTaken = 1'b0;
    endcase
  end

  assign wCsrInstr     = (iCsrOp != rv32i_pkg::CSR_NONE);
  assign oCsrAddr      = iInstr[31:20];
  assign wCsrZimm      = {27'd0, iInstr[19:15]};
  assign wCsrRs1IsZero = (iRs1Addr == 5'd0);

  always_comb begin
    unique case (iCsrOp)
      rv32i_pkg::CSR_RWI,
      rv32i_pkg::CSR_RSI,
      rv32i_pkg::CSR_RCI: oCsrWrOperand = wCsrZimm;
      default:            oCsrWrOperand = iRs1Data;
    endcase
  end

  always_comb begin
    oCsrWriteEn = 1'b0;

    if (iValid && !iPcRedirectPending && wCsrInstr && !oTrapEn) begin
      unique case (iCsrOp)
        rv32i_pkg::CSR_RW,
        rv32i_pkg::CSR_RWI: begin
          oCsrWriteEn = 1'b1;
        end
        rv32i_pkg::CSR_RS,
        rv32i_pkg::CSR_RC: begin
          oCsrWriteEn = !wCsrRs1IsZero;
        end
        rv32i_pkg::CSR_RSI,
        rv32i_pkg::CSR_RCI: begin
          oCsrWriteEn = (wCsrZimm != 32'd0);
        end
        default: begin end
      endcase
    end
  end

  always_comb begin
    wLoadMisaligned = 1'b0;

    unique case (iLoadType)
      rv32i_pkg::LOAD_LH,
      rv32i_pkg::LOAD_LHU: wLoadMisaligned = oAluResult[0];
      rv32i_pkg::LOAD_LW:  wLoadMisaligned = |oAluResult[1:0];
      default:             wLoadMisaligned = 1'b0;
    endcase
  end

  always_comb begin
    wStoreMisaligned = 1'b0;

    unique case (iStoreType)
      rv32i_pkg::STORE_SH: wStoreMisaligned = oAluResult[0];
      rv32i_pkg::STORE_SW: wStoreMisaligned = |oAluResult[1:0];
      default:             wStoreMisaligned = 1'b0;
    endcase
  end

  always_comb begin
    wControlRedirectTarget = wPcPlusImm;

    if (iJumpType == rv32i_pkg::JUMP_JALR) begin
      wControlRedirectTarget = {oAluResult[31:1], 1'b0};
    end
  end

  assign wInstrTargetMisaligned =
    iValid && !iPcRedirectPending &&
    ((iJumpType != rv32i_pkg::JUMP_NONE) || oBranchTaken) &&
    (wControlRedirectTarget[1:0] != 2'b00);

  assign wBranchInstr = (iBranchType != rv32i_pkg::BR_NONE);
  assign wBranchMispredict =
    wBranchInstr &&
    ((iPredictedTaken != oBranchTaken) ||
     (oBranchTaken && (iPredictedTarget != wPcPlusImm)));

  always_comb begin
    oTrapEn    = 1'b0;
    oTrapCause = rv32i_pkg::EXC_NONE;
    oTrapTval  = 32'd0;

    if (iValid && !iPcRedirectPending) begin
      if (iInstrAccessFault) begin
        oTrapEn    = 1'b1;
        oTrapCause = rv32i_pkg::EXC_INSTR_ACCESS_FAULT;
        oTrapTval  = iPc;
      end
      else if (iIllegal || (wCsrInstr && !iCsrAddrValid)) begin
        oTrapEn    = 1'b1;
        oTrapCause = rv32i_pkg::EXC_ILLEGAL_INSTR;
        oTrapTval  = iInstr;
      end
      else if (iSysOp == rv32i_pkg::SYS_EBREAK) begin
        oTrapEn    = 1'b1;
        oTrapCause = rv32i_pkg::EXC_BREAKPOINT;
        oTrapTval  = 32'd0;
      end
      else if (iSysOp == rv32i_pkg::SYS_ECALL) begin
        oTrapEn    = 1'b1;
        oTrapCause = rv32i_pkg::EXC_ECALL_MMODE;
        oTrapTval  = 32'd0;
      end
      else if (wInstrTargetMisaligned) begin
        oTrapEn    = 1'b1;
        oTrapCause = rv32i_pkg::EXC_INSTR_ADDR_MISALIGNED;
        oTrapTval  = wControlRedirectTarget;
      end
      else if (wLoadMisaligned) begin
        oTrapEn    = 1'b1;
        oTrapCause = rv32i_pkg::EXC_LOAD_ADDR_MISALIGNED;
        oTrapTval  = oAluResult;
      end
      else if (wStoreMisaligned) begin
        oTrapEn    = 1'b1;
        oTrapCause = rv32i_pkg::EXC_STORE_ADDR_MISALIGNED;
        oTrapTval  = oAluResult;
      end
    end
  end

  assign oMretEn = iValid && !iPcRedirectPending &&
                   (iSysOp == rv32i_pkg::SYS_MRET) && !oTrapEn;

  always_comb begin
    oPcRedirectEn     = 1'b0;
    oPcRedirectTarget = 32'd0;

    if (oTrapEn) begin
      oPcRedirectEn     = 1'b1;
      oPcRedirectTarget = iCsrMtvec;
    end
    else if (oMretEn) begin
      oPcRedirectEn     = 1'b1;
      oPcRedirectTarget = iCsrMepc;
    end
    else if (iValid && !iPcRedirectPending) begin
      unique case (iJumpType)
        rv32i_pkg::JUMP_JAL: begin
          oPcRedirectEn     = !iEarlyJal;
          oPcRedirectTarget = !iEarlyJal ? wPcPlusImm : 32'd0;
        end
        rv32i_pkg::JUMP_JALR: begin
          oPcRedirectEn     = 1'b1;
          oPcRedirectTarget = wControlRedirectTarget;
        end
        default: begin
          oPcRedirectEn = !iEarlyBranch && wBranchMispredict;
          oPcRedirectTarget =
            (!iEarlyBranch && wBranchMispredict && oBranchTaken) ? wPcPlusImm :
            (!iEarlyBranch && wBranchMispredict) ? iPcPlus4 : 32'd0;
        end
      endcase
    end
  end

  always_comb begin
    unique case (iWbSel)
      rv32i_pkg::WB_ALU:   oWbDataNonMem = oAluResult;
      rv32i_pkg::WB_PC4:   oWbDataNonMem = iPcPlus4;
      rv32i_pkg::WB_IMM:   oWbDataNonMem = iImm;
      rv32i_pkg::WB_PCIMM: oWbDataNonMem = wPcPlusImm;
      rv32i_pkg::WB_CSR:   oWbDataNonMem = iCsrRdData;
      default:             oWbDataNonMem = oAluResult;
    endcase
  end

endmodule
