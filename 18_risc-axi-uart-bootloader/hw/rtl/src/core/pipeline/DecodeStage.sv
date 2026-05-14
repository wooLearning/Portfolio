`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: DecodeStage
Role: RV32I pipeline decode stage
Summary:
  - Splits instruction fields, decodes control, generates immediates, and reads the register file
  - Computes ID-stage early JAL/branch redirect candidates
  - Packages decoded operands and controls for the ID/EX pipeline register
StateDescription:
  - Register file state is stored in Regfile
[MODULE_INFO_END]
*/
module DecodeStage #(
  parameter bit P_ID_EARLY_BRANCH = 1'b1,
  parameter bit P_FAST_JAL_X0 = 1'b1
) (
  input  logic                     iClk,
  input  logic                     iRstn,
  input  rv32i_pkg::if_id_packet_t iIfIdPacket,
  input  rv32i_pkg::id_ex_packet_t iIdExPacket,
  input  rv32i_pkg::ex_mem_packet_t iExMemPacket,
  input  rv32i_pkg::mem_wb_packet_t iMemWbPacket,
  input  logic                     iWbRegWriteEn,
  input  logic                     iIdJalRedirectEn,
  input  logic                     iIdBranchRedirectEn,
  output rv32i_pkg::id_ex_packet_t oDecodePacket,
  output logic                     oIdJalCandidate,
  output logic                     oIdJalX0Candidate,
  output logic                     oIdBranchCandidate,
  output logic [31:0]              oIdJalTarget,
  output logic [31:0]              oIdBranchTarget,
  output logic                     oIdBtbUpdateValid,
  output logic                     oIdBtbUpdateTaken,
  output logic [31:0]              oIdBtbUpdatePc,
  output logic [31:0]              oIdBtbUpdateTarget,
  output logic [4:0]               oIdRs1Addr,
  output logic [4:0]               oIdRs2Addr,
  output logic                     oIdUsesRs1,
  output logic                     oIdUsesRs2
);

  logic [6:0]  wOpcode;
  logic [2:0]  wFunct3;
  logic [6:0]  wFunct7;
  logic [4:0]  wRs1Addr;
  logic [4:0]  wRs2Addr;
  logic [4:0]  wRdAddr;
  logic [31:0] wImm;
  logic [31:0] wRs1DataRaw;
  logic [31:0] wRs2DataRaw;
  logic [31:0] wRs1Data;
  logic [31:0] wRs2Data;
  logic [31:0] wBranchRs1Data;
  logic [31:0] wBranchRs2Data;
  logic        wRegWrite;
  logic        wMemWrite;
  logic        wAluSrc;
  logic        wIllegal;
  logic        wUsesRs1;
  logic        wUsesRs2;
  logic        wCsrAddrValid;
  logic        wBranchTaken;
  logic        wBranchSrcBlocked;
  logic        wOlderMayRedirect;
  logic        wLegalJal;
  logic        wJalPredictedCorrect;
  logic        wIdBranchResolved;
  logic        wIdBranchMispredict;
  logic [31:0] wBranchTarget;
  logic [31:0] wBranchCorrectTarget;
  rv32i_pkg::wb_sel_e     wWbSel;
  rv32i_pkg::alu_op_e     wAluOp;
  rv32i_pkg::load_type_e  wLoadType;
  rv32i_pkg::store_type_e wStoreType;
  rv32i_pkg::imm_sel_e    wImmSel;
  rv32i_pkg::branch_e     wBranchType;
  rv32i_pkg::jump_e       wJumpType;
  rv32i_pkg::csr_op_e     wCsrOp;
  rv32i_pkg::sys_op_e     wSysOp;

  InstrFields uInstrFields (
    .iInstr  (iIfIdPacket.instr),
    .oOpcode (wOpcode),
    .oFunct3 (wFunct3),
    .oFunct7 (wFunct7),
    .oRs1    (wRs1Addr),
    .oRs2    (wRs2Addr),
    .oRd     (wRdAddr)
  );

  ControlUnit uControlUnit (
    .iInstr      (iIfIdPacket.instr),
    .iInstrValid (iIfIdPacket.valid),
    .iOpcode     (wOpcode),
    .iFunct3     (wFunct3),
    .iFunct7     (wFunct7),
    .oRegWrite   (wRegWrite),
    .oMemWrite   (wMemWrite),
    .oAluSrc     (wAluSrc),
    .oWbSel      (wWbSel),
    .oAluOp      (wAluOp),
    .oLoadType   (wLoadType),
    .oStoreType  (wStoreType),
    .oImmSel     (wImmSel),
    .oBranchType (wBranchType),
    .oJumpType   (wJumpType),
    .oCsrOp      (wCsrOp),
    .oSysOp      (wSysOp),
    .oIllegal    (wIllegal)
  );

  ImmGen uImmGen (
    .iInstr  (iIfIdPacket.instr),
    .iImmSel (wImmSel),
    .oImm    (wImm)
  );

  Regfile uRegfile (
    .iClk       (iClk),
    .iRstn      (iRstn),
    .iRs1Addr   (wRs1Addr),
    .iRs2Addr   (wRs2Addr),
    .iRdAddr    (iMemWbPacket.rd_addr),
    .iRdWrData  (iMemWbPacket.wr_data),
    .iRdWrEn    (iWbRegWriteEn),
    .oRs1RdData (wRs1DataRaw),
    .oRs2RdData (wRs2DataRaw)
  );

  assign oIdRs1Addr = wRs1Addr;
  assign oIdRs2Addr = wRs2Addr;
  assign oIdUsesRs1 = wUsesRs1;
  assign oIdUsesRs2 = wUsesRs2;

  assign wRs1Data =
    (wRs1Addr != 5'd0) && iWbRegWriteEn && (iMemWbPacket.rd_addr == wRs1Addr) ?
    iMemWbPacket.wr_data : wRs1DataRaw;

  assign wRs2Data =
    (wRs2Addr != 5'd0) && iWbRegWriteEn && (iMemWbPacket.rd_addr == wRs2Addr) ?
    iMemWbPacket.wr_data : wRs2DataRaw;

  assign wBranchTarget = iIfIdPacket.pc + wImm;
  assign wBranchCorrectTarget = wBranchTaken ? wBranchTarget : iIfIdPacket.pc_plus4;
  assign oIdBranchTarget = wBranchCorrectTarget;
  assign oIdJalTarget    = iIfIdPacket.pc + wImm;

  always_comb begin
    wUsesRs1 = 1'b0;
    wUsesRs2 = 1'b0;

    if (iIfIdPacket.valid) begin
      unique case (wOpcode)
        rv32i_pkg::LP_OPCODE_RTYPE: begin
          wUsesRs1 = 1'b1;
          wUsesRs2 = 1'b1;
        end
        rv32i_pkg::LP_OPCODE_OPIMM,
        rv32i_pkg::LP_OPCODE_LOAD,
        rv32i_pkg::LP_OPCODE_JALR: begin
          wUsesRs1 = 1'b1;
        end
        rv32i_pkg::LP_OPCODE_STORE,
        rv32i_pkg::LP_OPCODE_BRANCH: begin
          wUsesRs1 = 1'b1;
          wUsesRs2 = 1'b1;
        end
        rv32i_pkg::LP_OPCODE_SYSTEM: begin
          if ((wFunct3 == 3'b001) || (wFunct3 == 3'b010) ||
              (wFunct3 == 3'b011)) begin
            wUsesRs1 = 1'b1;
          end
        end
        default: begin end
      endcase
    end
  end

  always_comb begin
    wCsrAddrValid = 1'b1;

    if (wCsrOp != rv32i_pkg::CSR_NONE) begin
      unique case (iIfIdPacket.instr[31:20])
        rv32i_pkg::LP_CSR_MSTATUS,
        rv32i_pkg::LP_CSR_MIE,
        rv32i_pkg::LP_CSR_MTVEC,
        rv32i_pkg::LP_CSR_MEPC,
        rv32i_pkg::LP_CSR_MCAUSE,
        rv32i_pkg::LP_CSR_MTVAL,
        rv32i_pkg::LP_CSR_MIP: begin
          wCsrAddrValid = 1'b1;
        end
        default: begin
          wCsrAddrValid = 1'b0;
        end
      endcase
    end
  end

  always_comb begin
    wBranchRs1Data = wRs1Data;
    wBranchRs2Data = wRs2Data;

    if ((wRs1Addr != 5'd0) && iExMemPacket.forward_en &&
        (iExMemPacket.rd_addr == wRs1Addr) && (iExMemPacket.wb_sel != rv32i_pkg::WB_MEM)) begin
      wBranchRs1Data = iExMemPacket.wb_data_non_mem;
    end

    if ((wRs2Addr != 5'd0) && iExMemPacket.forward_en &&
        (iExMemPacket.rd_addr == wRs2Addr) && (iExMemPacket.wb_sel != rv32i_pkg::WB_MEM)) begin
      wBranchRs2Data = iExMemPacket.wb_data_non_mem;
    end
  end

  assign wBranchSrcBlocked =
    (iIdExPacket.valid && iIdExPacket.reg_write && (iIdExPacket.rd_addr != 5'd0) &&
     ((wUsesRs1 && (iIdExPacket.rd_addr == wRs1Addr)) ||
      (wUsesRs2 && (iIdExPacket.rd_addr == wRs2Addr)))) ||
    (iExMemPacket.reg_write && (iExMemPacket.wb_sel == rv32i_pkg::WB_MEM) &&
     (iExMemPacket.rd_addr != 5'd0) &&
     ((wUsesRs1 && (iExMemPacket.rd_addr == wRs1Addr)) ||
      (wUsesRs2 && (iExMemPacket.rd_addr == wRs2Addr))));

  always_comb begin
    wBranchTaken = 1'b0;

    unique case (wBranchType)
      rv32i_pkg::BR_BEQ:  wBranchTaken = (wBranchRs1Data == wBranchRs2Data);
      rv32i_pkg::BR_BNE:  wBranchTaken = (wBranchRs1Data != wBranchRs2Data);
      rv32i_pkg::BR_BLT:  wBranchTaken = ($signed(wBranchRs1Data) < $signed(wBranchRs2Data));
      rv32i_pkg::BR_BGE:  wBranchTaken = !($signed(wBranchRs1Data) < $signed(wBranchRs2Data));
      rv32i_pkg::BR_BLTU: wBranchTaken = (wBranchRs1Data < wBranchRs2Data);
      rv32i_pkg::BR_BGEU: wBranchTaken = !(wBranchRs1Data < wBranchRs2Data);
      default:            wBranchTaken = 1'b0;
    endcase
  end

  assign wOlderMayRedirect =
    iIdExPacket.valid &&
    ((iIdExPacket.branch_type != rv32i_pkg::BR_NONE) ||
     (iIdExPacket.jump_type != rv32i_pkg::JUMP_NONE) ||
     (iIdExPacket.load_type != rv32i_pkg::LOAD_NONE) ||
     (iIdExPacket.store_type != rv32i_pkg::STORE_NONE) ||
     (iIdExPacket.csr_op != rv32i_pkg::CSR_NONE) ||
     (iIdExPacket.sys_op != rv32i_pkg::SYS_NONE) ||
     iIdExPacket.illegal ||
     !iIdExPacket.csr_addr_valid);

  assign wLegalJal =
    iIfIdPacket.valid &&
    (wJumpType == rv32i_pkg::JUMP_JAL) &&
    !wIllegal &&
    (oIdJalTarget[1:0] == 2'b00);

  assign wJalPredictedCorrect =
    wLegalJal &&
    iIfIdPacket.predicted_taken &&
    (iIfIdPacket.predicted_target == oIdJalTarget);

  assign wIdBranchResolved =
    P_ID_EARLY_BRANCH &&
    iIfIdPacket.valid &&
    (wBranchType != rv32i_pkg::BR_NONE) &&
    !wIllegal &&
    !wBranchSrcBlocked &&
    (!wBranchTaken || (wBranchTarget[1:0] == 2'b00));

  assign wIdBranchMispredict =
    wIdBranchResolved &&
    ((iIfIdPacket.predicted_taken != wBranchTaken) ||
     (wBranchTaken && (iIfIdPacket.predicted_target != wBranchTarget)));

  assign oIdBranchCandidate = wIdBranchMispredict;

  assign oIdJalX0Candidate =
    P_FAST_JAL_X0 &&
    wLegalJal &&
    (wRdAddr == 5'd0) &&
    !wOlderMayRedirect &&
    !wJalPredictedCorrect;

  assign oIdJalCandidate =
    wLegalJal &&
    !oIdJalX0Candidate &&
    !wJalPredictedCorrect;

  always_comb begin
    oIdBtbUpdateValid  = 1'b0;
    oIdBtbUpdateTaken  = 1'b0;
    oIdBtbUpdatePc     = iIfIdPacket.pc;
    oIdBtbUpdateTarget = 32'd0;

    if (wLegalJal) begin
      oIdBtbUpdateValid  = 1'b1;
      oIdBtbUpdateTaken  = 1'b1;
      oIdBtbUpdateTarget = oIdJalTarget;
    end
    else if (wIdBranchResolved) begin
      oIdBtbUpdateValid  = 1'b1;
      oIdBtbUpdateTaken  = wBranchTaken;
      oIdBtbUpdateTarget = wBranchTarget;
    end
  end

  always_comb begin
    oDecodePacket.valid          = iIfIdPacket.valid;
    oDecodePacket.instr_error    = iIfIdPacket.instr_error;
    oDecodePacket.illegal        = wIllegal;
    oDecodePacket.csr_addr_valid = wCsrAddrValid;
    oDecodePacket.predicted_taken = iIfIdPacket.predicted_taken;
    oDecodePacket.instr          = iIfIdPacket.instr;
    oDecodePacket.pc             = iIfIdPacket.pc;
    oDecodePacket.pc_plus4       = iIfIdPacket.pc_plus4;
    oDecodePacket.predicted_target = iIfIdPacket.predicted_target;
    oDecodePacket.imm            = wImm;
    oDecodePacket.rs1_data       = wRs1Data;
    oDecodePacket.rs2_data       = wRs2Data;
    oDecodePacket.rs1_addr       = wRs1Addr;
    oDecodePacket.rs2_addr       = wRs2Addr;
    oDecodePacket.rd_addr        = wRdAddr;
    oDecodePacket.reg_write      = wRegWrite;
    oDecodePacket.mem_write      = wMemWrite;
    oDecodePacket.alu_src        = wAluSrc;
    oDecodePacket.uses_rs1       = wUsesRs1;
    oDecodePacket.uses_rs2       = wUsesRs2;
    oDecodePacket.early_jal      = iIdJalRedirectEn || wJalPredictedCorrect;
    oDecodePacket.early_branch   = wIdBranchResolved;
    oDecodePacket.wb_sel         = wWbSel;
    oDecodePacket.alu_op         = wAluOp;
    oDecodePacket.load_type      = wLoadType;
    oDecodePacket.store_type     = wStoreType;
    oDecodePacket.branch_type    = wBranchType;
    oDecodePacket.jump_type      = wJumpType;
    oDecodePacket.csr_op         = wCsrOp;
    oDecodePacket.sys_op         = wSysOp;
  end

endmodule
