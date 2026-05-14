`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: Top
Role: RTL module implementing the first-pass 5-stage RV32I pipeline top
Summary:
  - Reuses the legacy RV32I decode, ALU, register file, ROM, and RAM helpers
  - Implements IF/ID/EX/MEM/WB stages with registered EX redirects and ID-early JAL/branch redirects
  - Preserves legacy unsupported-instruction behavior as no-side-effect sequential execution
StateDescription:
  - IF/ID: fetch packet with valid, PC, PC+4, instruction
  - ID/EX: decoded control, operands, immediates, and illegal metadata
  - EX/MEM: execution result, store data, memory controls, and redirect result
  - MEM/WB: final write-back packet for register commit
[MODULE_INFO_END]
*/
module Top #(
  parameter bit P_USE_BUBBLE_ROM = 1'b0,
  parameter bit P_USE_HAZARD_ROM = 1'b0,
  parameter bit P_USE_EXCEPTION_ROM = 1'b0,
  parameter bit P_USE_TIMING_FULL_ROM = 1'b0,
  parameter bit P_USE_TIMING_BUBBLE_ROM = 1'b0,
  parameter bit P_ID_EARLY_BRANCH = 1'b1,
  parameter bit P_FAST_JAL_X0 = 1'b1
) (
  input logic iClk,
  input logic iRstn,
  output logic [31:0] oDbgPc,
  output logic        oDbgLoadUseStall,
  output logic [1:0]  oDbgForwardA,
  output logic [1:0]  oDbgForwardB,
  output logic        oDbgExPcRedirectEn,
  output logic        oDbgTrapEn,
  output rv32i_pkg::exc_cause_e oDbgTrapCause,
  output logic [31:0] oDbgMtvec,
  output logic [31:0] oDbgMepc,
  output logic [31:0] oDbgMcause,
  output logic [31:0] oDbgMtval
);

  localparam logic [31:0] LP_NOP = 32'h00000013;

  // IF stage
  logic [31:0] wPc2Top_Pc;
  logic [31:0] wPc2Top_PcPlus4;
  logic [31:0] wInstrRom2Top_Instr;
  logic        wTop2Pc_PcWriteEn;

  // IF/ID pipeline registers
  logic        rIfIdValid;
  logic [31:0] rIfIdPc;
  logic [31:0] rIfIdPcPlus4;
  logic [31:0] rIfIdInstr;

  // ID stage decode and operand collection
  logic [6:0]  wIdOpcode;
  logic [2:0]  wIdFunct3;
  logic [6:0]  wIdFunct7;
  logic [4:0]  wIdRs1Addr;
  logic [4:0]  wIdRs2Addr;
  logic [4:0]  wIdRdAddr;
  logic [31:0] wIdImm;
  logic [31:0] wRegfile2Top_Rs1DataRaw;
  logic [31:0] wRegfile2Top_Rs2DataRaw;
  logic [31:0] wIdRs1Data;
  logic [31:0] wIdRs2Data;
  logic        wIdRegWrite;
  logic        wIdMemWrite;
  logic        wIdAluSrc;
  logic        wIdIllegal;
  logic        wIdUsesRs1;
  logic        wIdUsesRs2;
  logic        wIdCsrAddrValid;
  logic        wIdJalRedirectEn;
  logic        wIdJalX0RedirectEn;
  logic [31:0] wIdJalRedirectTarget;
  logic        wIdBranchRedirectEn;
  logic [31:0] wIdBranchRedirectTarget;
  logic        wIdBranchTaken;
  logic        wIdBranchSrcBlocked;
  logic        wIdOlderMayRedirect;
  logic [31:0] wIdBranchRs1Data;
  logic [31:0] wIdBranchRs2Data;
  logic        rIdJalRedirectEn;
  logic [31:0] rIdJalRedirectTarget;
  logic        rIdBranchRedirectEn;
  logic [31:0] rIdBranchRedirectTarget;
  logic        wPcTargetEn;
  logic [31:0] wPcTarget;
  rv32i_pkg::wb_sel_e     wIdWbSel;
  rv32i_pkg::alu_op_e     wIdAluOp;
  rv32i_pkg::load_type_e  wIdLoadType;
  rv32i_pkg::store_type_e wIdStoreType;
  rv32i_pkg::imm_sel_e    wIdImmSel;
  rv32i_pkg::branch_e     wIdBranchType;
  rv32i_pkg::jump_e       wIdJumpType;
  rv32i_pkg::csr_op_e     wIdCsrOp;
  rv32i_pkg::sys_op_e     wIdSysOp;

  // Hazard control
  logic wHazard2Top_LoadUseStall;

  // ID/EX pipeline registers
  logic        rIdExValid;
  logic        rIdExIllegal;
  logic        rIdExCsrAddrValid;
  logic [31:0] rIdExInstr;
  logic [31:0] rIdExPc;
  logic [31:0] rIdExPcPlus4;
  logic [31:0] rIdExImm;
  logic [31:0] rIdExRs1Data;
  logic [31:0] rIdExRs2Data;
  logic [4:0]  rIdExRs1Addr;
  logic [4:0]  rIdExRs2Addr;
  logic [4:0]  rIdExRdAddr;
  logic        rIdExRegWrite;
  logic        rIdExMemWrite;
  logic        rIdExAluSrc;
  logic        rIdExUsesRs1;
  logic        rIdExUsesRs2;
  logic        rIdExEarlyJal;
  logic        rIdExEarlyBranch;
  rv32i_pkg::wb_sel_e     rIdExWbSel;
  rv32i_pkg::alu_op_e     rIdExAluOp;
  rv32i_pkg::load_type_e  rIdExLoadType;
  rv32i_pkg::store_type_e rIdExStoreType;
  rv32i_pkg::branch_e     rIdExBranchType;
  rv32i_pkg::jump_e       rIdExJumpType;
  rv32i_pkg::csr_op_e     rIdExCsrOp;
  rv32i_pkg::sys_op_e     rIdExSysOp;

  // EX stage
  logic [1:0]  wForwardA;
  logic [1:0]  wForwardB;
  logic [31:0] wExRs1Data;
  logic [31:0] wExRs2Data;
  logic [31:0] wExAluResult;
  logic [31:0] wExStoreData;
  logic [31:0] wExWbDataNonMem;
  logic        wExBranchTaken;
  logic        wExPcRedirectEn;
  logic [31:0] wExPcRedirectTarget;
  logic        rPcRedirectEn;
  logic [31:0] rPcRedirectTarget;
  logic        wExTrapEn;
  rv32i_pkg::exc_cause_e wExTrapCause;
  logic [31:0] wExTrapTval;
  logic        wExMretEn;
  logic [11:0] wExCsrAddr;
  logic [31:0] wExCsrWrOperand;
  logic        wExCsrWriteEn;
  logic [31:0] wCsrRdData;
  logic        wCsrAddrValid;
  logic [31:0] wCsrMstatus;
  logic [31:0] wCsrMie;
  logic [31:0] wCsrMtvec;
  logic [31:0] wCsrMepc;
  logic [31:0] wCsrMcause;
  logic [31:0] wCsrMtval;
  logic [31:0] wCsrMipSw;
  logic [31:0] wMip;

  // EX/MEM pipeline registers
  logic        rExMemValid;
  logic        rExMemIllegal;
  logic        rExMemRegWrite;
  logic        rExMemMemWrite;
  logic        rExMemForwardEn;
  logic [4:0]  rExMemRdAddr;
  logic [31:0] rExMemAluResult;
  logic [31:0] rExMemStoreData;
  logic [31:0] rExMemWbDataNonMem;
  rv32i_pkg::wb_sel_e     rExMemWbSel;
  rv32i_pkg::load_type_e  rExMemLoadType;
  rv32i_pkg::store_type_e rExMemStoreType;

  // MEM stage
  logic [31:0] wDataRam2Top_RdData;
  logic [31:0] wMemStageWbData;

  // MEM/WB pipeline registers
  logic        rMemWbValid;
  logic        rMemWbIllegal;
  logic        rMemWbRegWrite;
  logic        rMemWbForwardEn;
  logic [4:0]  rMemWbRdAddr;
  logic [31:0] rMemWbWrData;

  // Write-back commit
  logic        wMemWb2Regfile_WrEn;

  assign oDbgPc             = wPc2Top_Pc;
  assign oDbgLoadUseStall   = wHazard2Top_LoadUseStall;
  assign oDbgForwardA       = wForwardA;
  assign oDbgForwardB       = wForwardB;
  assign oDbgExPcRedirectEn = wExPcRedirectEn || wIdJalRedirectEn || wIdBranchRedirectEn;
  assign oDbgTrapEn         = wExTrapEn;
  assign oDbgTrapCause      = wExTrapCause;
  assign oDbgMtvec          = wCsrMtvec;
  assign oDbgMepc           = wCsrMepc;
  assign oDbgMcause         = wCsrMcause;
  assign oDbgMtval          = wCsrMtval;

  assign wPcTargetEn = rPcRedirectEn || wIdJalX0RedirectEn || rIdJalRedirectEn || rIdBranchRedirectEn;
  assign wPcTarget   = rPcRedirectEn ? rPcRedirectTarget :
                       wIdJalX0RedirectEn ? wIdJalRedirectTarget :
                       rIdJalRedirectEn ? rIdJalRedirectTarget : rIdBranchRedirectTarget;
  assign wTop2Pc_PcWriteEn = wPcTargetEn || !wHazard2Top_LoadUseStall;
  assign wMemWb2Regfile_WrEn = rMemWbValid && rMemWbRegWrite;

  Pc uPc (
    .iClk        (iClk),
    .iRstn       (iRstn),
    .iPcWe       (wTop2Pc_PcWriteEn),
    .iPcTargetEn (wPcTargetEn),
    .iPcTarget   (wPcTarget),
    .oPc         (wPc2Top_Pc),
    .oPcPlus4    (wPc2Top_PcPlus4)
  );

  generate
    if (P_USE_TIMING_FULL_ROM) begin : genTimingFullRom
      InstrRom_timing_full uInstrRom (
        .iAddr  (wPc2Top_Pc),
        .oInstr (wInstrRom2Top_Instr)
      );
    end else if (P_USE_TIMING_BUBBLE_ROM) begin : genTimingBubbleRom
      InstrRom_timing_bubble uInstrRom (
        .iAddr  (wPc2Top_Pc),
        .oInstr (wInstrRom2Top_Instr)
      );
    end else if (P_USE_EXCEPTION_ROM) begin : genExceptionRom
      InstrRom_exception uInstrRom (
        .iAddr  (wPc2Top_Pc),
        .oInstr (wInstrRom2Top_Instr)
      );
    end else if (P_USE_HAZARD_ROM) begin : genHazardRom
      InstrRom_hazard uInstrRom (
        .iAddr  (wPc2Top_Pc),
        .oInstr (wInstrRom2Top_Instr)
      );
    end else if (P_USE_BUBBLE_ROM) begin : genBubbleRom
      InstrRom_bubble uInstrRom (
        .iAddr  (wPc2Top_Pc),
        .oInstr (wInstrRom2Top_Instr)
      );
    end else begin : genDefaultRom
      InstrRom uInstrRom (
        .iAddr  (wPc2Top_Pc),
        .oInstr (wInstrRom2Top_Instr)
      );
    end
  endgenerate

  InstrFields uInstrFields (
    .iInstr  (rIfIdInstr),
    .oOpcode (wIdOpcode),
    .oFunct3 (wIdFunct3),
    .oFunct7 (wIdFunct7),
    .oRs1    (wIdRs1Addr),
    .oRs2    (wIdRs2Addr),
    .oRd     (wIdRdAddr)
  );

  ControlUnit uControlUnit (
    .iInstr      (rIfIdInstr),
    .iInstrValid (rIfIdValid),
    .iOpcode     (wIdOpcode),
    .iFunct3     (wIdFunct3),
    .iFunct7     (wIdFunct7),
    .oRegWrite   (wIdRegWrite),
    .oMemWrite   (wIdMemWrite),
    .oAluSrc     (wIdAluSrc),
    .oWbSel      (wIdWbSel),
    .oAluOp      (wIdAluOp),
    .oLoadType   (wIdLoadType),
    .oStoreType  (wIdStoreType),
    .oImmSel     (wIdImmSel),
    .oBranchType (wIdBranchType),
    .oJumpType   (wIdJumpType),
    .oCsrOp      (wIdCsrOp),
    .oSysOp      (wIdSysOp),
    .oIllegal    (wIdIllegal)
  );

  ImmGen uImmGen (
    .iInstr  (rIfIdInstr),
    .iImmSel (wIdImmSel),
    .oImm    (wIdImm)
  );

  Regfile uRegfile (
    .iClk      (iClk),
    .iRstn     (iRstn),
    .iRs1Addr  (wIdRs1Addr),
    .iRs2Addr  (wIdRs2Addr),
    .iRdAddr   (rMemWbRdAddr),
    .iRdWrData (rMemWbWrData),
    .iRdWrEn   (wMemWb2Regfile_WrEn),
    .oRs1RdData(wRegfile2Top_Rs1DataRaw),
    .oRs2RdData(wRegfile2Top_Rs2DataRaw)
  );

  HazardUnit uHazardUnit (
    .iIdValid      (rIfIdValid),
    .iIdRs1Addr    (wIdRs1Addr),
    .iIdRs2Addr    (wIdRs2Addr),
    .iIdUsesRs1    (wIdUsesRs1),
    .iIdUsesRs2    (wIdUsesRs2),
    .iExValid      (rIdExValid),
    .iExRdAddr     (rIdExRdAddr),
    .iExIsLoad     (rIdExLoadType != rv32i_pkg::LOAD_NONE),
    .oLoadUseStall (wHazard2Top_LoadUseStall)
  );

  ForwardingUnit uForwardingUnit (
    .iExRs1Addr    (rIdExRs1Addr),
    .iExRs2Addr    (rIdExRs2Addr),
    .iExUsesRs1    (rIdExUsesRs1),
    .iExUsesRs2    (rIdExUsesRs2),
    .iMemRdAddr    (rExMemRdAddr),
    .iMemForwardEn (rExMemForwardEn),
    .iWbRdAddr     (rMemWbRdAddr),
    .iWbForwardEn  (rMemWbForwardEn),
    .oForwardA     (wForwardA),
    .oForwardB     (wForwardB)
  );

  ExecuteStage uExecuteStage (
    .iValid             (rIdExValid),
    .iPcRedirectPending (rPcRedirectEn),
    .iInstrAccessFault  (1'b0),
    .iEarlyJal          (rIdExEarlyJal),
    .iEarlyBranch       (rIdExEarlyBranch),
    .iIllegal           (rIdExIllegal),
    .iCsrAddrValid      (rIdExCsrAddrValid),
    .iInstr             (rIdExInstr),
    .iPc                (rIdExPc),
    .iPcPlus4           (rIdExPcPlus4),
    .iImm               (rIdExImm),
    .iRs1Data           (wExRs1Data),
    .iRs2Data           (wExRs2Data),
    .iRs1Addr           (rIdExRs1Addr),
    .iAluSrc            (rIdExAluSrc),
    .iAluOp             (rIdExAluOp),
    .iWbSel             (rIdExWbSel),
    .iLoadType          (rIdExLoadType),
    .iStoreType         (rIdExStoreType),
    .iBranchType        (rIdExBranchType),
    .iJumpType          (rIdExJumpType),
    .iCsrOp             (rIdExCsrOp),
    .iSysOp             (rIdExSysOp),
    .iCsrRdData         (wCsrRdData),
    .iCsrMtvec          (wCsrMtvec),
    .iCsrMepc           (wCsrMepc),
    .oAluResult         (wExAluResult),
    .oStoreData         (wExStoreData),
    .oWbDataNonMem      (wExWbDataNonMem),
    .oBranchTaken       (wExBranchTaken),
    .oPcRedirectEn      (wExPcRedirectEn),
    .oPcRedirectTarget  (wExPcRedirectTarget),
    .oTrapEn            (wExTrapEn),
    .oTrapCause         (wExTrapCause),
    .oTrapTval          (wExTrapTval),
    .oMretEn            (wExMretEn),
    .oCsrAddr           (wExCsrAddr),
    .oCsrWrOperand      (wExCsrWrOperand),
    .oCsrWriteEn        (wExCsrWriteEn)
  );

  DataRam uDataRam (
    .iClk       (iClk),
    .iWrEn      (rExMemValid && rExMemMemWrite),
    .iAddr      (rExMemAluResult),
    .iWrData    (rExMemStoreData),
    .iLoadType  (rExMemValid ? rExMemLoadType : rv32i_pkg::LOAD_NONE),
    .iStoreType (rExMemStoreType),
    .oRdData    (wDataRam2Top_RdData)
  );

  CsrFile uCsrFile (
    .iClk          (iClk),
    .iRstn         (iRstn),
    .iCsrAddr      (wExCsrAddr),
    .iCsrOp        (rIdExCsrOp),
    .iCsrWrData    (wExCsrWrOperand),
    .iCsrWriteEn   (wExCsrWriteEn),
    .iTrapEn       (wExTrapEn),
    .iTrapIsInterrupt(1'b0),
    .iTrapPc       (rIdExPc),
    .iTrapCause    (wExTrapCause),
    .iTrapTval     (wExTrapTval),
    .iMretEn       (wExMretEn),
    .iMip          (wMip),
    .oCsrRdData    (wCsrRdData),
    .oCsrAddrValid (wCsrAddrValid),
    .oMstatus      (wCsrMstatus),
    .oMie          (wCsrMie),
    .oMtvec        (wCsrMtvec),
    .oMepc         (wCsrMepc),
    .oMcause       (wCsrMcause),
    .oMtval        (wCsrMtval),
    .oMipSw        (wCsrMipSw)
  );

  MachineInterruptController uMachineInterruptController (
    .iSoftwareIrq      (1'b0),
    .iTimerIrq         (1'b0),
    .iExternalIrq      (1'b0),
    .iMstatus          (wCsrMstatus),
    .iMie              (wCsrMie),
    .iMipSw            (wCsrMipSw),
    .oMip              (wMip),
    .oInterruptPending (),
    .oInterruptCause   ()
  );

  always_comb begin
    wIdCsrAddrValid = 1'b1;

    if (wIdCsrOp != rv32i_pkg::CSR_NONE) begin
      unique case (rIfIdInstr[31:20])
        rv32i_pkg::LP_CSR_MSTATUS,
        rv32i_pkg::LP_CSR_MIE,
        rv32i_pkg::LP_CSR_MTVEC,
        rv32i_pkg::LP_CSR_MEPC,
        rv32i_pkg::LP_CSR_MCAUSE,
        rv32i_pkg::LP_CSR_MTVAL,
        rv32i_pkg::LP_CSR_MIP: begin
          wIdCsrAddrValid = 1'b1;
        end
        default: begin
          wIdCsrAddrValid = 1'b0;
        end
      endcase
    end
  end

  assign wIdRs1Data =
    (wIdRs1Addr != 5'd0) && wMemWb2Regfile_WrEn && (rMemWbRdAddr == wIdRs1Addr) ?
    rMemWbWrData : wRegfile2Top_Rs1DataRaw;

  assign wIdRs2Data =
    (wIdRs2Addr != 5'd0) && wMemWb2Regfile_WrEn && (rMemWbRdAddr == wIdRs2Addr) ?
    rMemWbWrData : wRegfile2Top_Rs2DataRaw;

  assign wIdBranchRedirectTarget = rIfIdPc + wIdImm;

  always_comb begin
    wIdBranchRs1Data = wIdRs1Data;
    wIdBranchRs2Data = wIdRs2Data;

    if ((wIdRs1Addr != 5'd0) && rExMemForwardEn &&
        (rExMemRdAddr == wIdRs1Addr) && (rExMemWbSel != rv32i_pkg::WB_MEM)) begin
      wIdBranchRs1Data = rExMemWbDataNonMem;
    end

    if ((wIdRs2Addr != 5'd0) && rExMemForwardEn &&
        (rExMemRdAddr == wIdRs2Addr) && (rExMemWbSel != rv32i_pkg::WB_MEM)) begin
      wIdBranchRs2Data = rExMemWbDataNonMem;
    end
  end

  assign wIdBranchSrcBlocked =
    (rIdExValid && rIdExRegWrite && (rIdExRdAddr != 5'd0) &&
     ((wIdUsesRs1 && (rIdExRdAddr == wIdRs1Addr)) ||
      (wIdUsesRs2 && (rIdExRdAddr == wIdRs2Addr)))) ||
    (rExMemRegWrite && (rExMemWbSel == rv32i_pkg::WB_MEM) && (rExMemRdAddr != 5'd0) &&
     ((wIdUsesRs1 && (rExMemRdAddr == wIdRs1Addr)) ||
      (wIdUsesRs2 && (rExMemRdAddr == wIdRs2Addr))));

  always_comb begin
    wIdBranchTaken = 1'b0;

    unique case (wIdBranchType)
      rv32i_pkg::BR_BEQ:  wIdBranchTaken = (wIdBranchRs1Data == wIdBranchRs2Data);
      rv32i_pkg::BR_BNE:  wIdBranchTaken = (wIdBranchRs1Data != wIdBranchRs2Data);
      rv32i_pkg::BR_BLT:  wIdBranchTaken = ($signed(wIdBranchRs1Data) < $signed(wIdBranchRs2Data));
      rv32i_pkg::BR_BGE:  wIdBranchTaken = !($signed(wIdBranchRs1Data) < $signed(wIdBranchRs2Data));
      rv32i_pkg::BR_BLTU: wIdBranchTaken = (wIdBranchRs1Data < wIdBranchRs2Data);
      rv32i_pkg::BR_BGEU: wIdBranchTaken = !(wIdBranchRs1Data < wIdBranchRs2Data);
      default:            wIdBranchTaken = 1'b0;
    endcase
  end

  assign wIdBranchRedirectEn =
    P_ID_EARLY_BRANCH &&
    rIfIdValid &&
    (wIdBranchType != rv32i_pkg::BR_NONE) &&
    wIdBranchTaken &&
    !wIdIllegal &&
    !wIdBranchSrcBlocked &&
    !rPcRedirectEn &&
    !rIdJalRedirectEn &&
    !rIdBranchRedirectEn &&
    !wExPcRedirectEn &&
    !wHazard2Top_LoadUseStall &&
    (wIdBranchRedirectTarget[1:0] == 2'b00);

  assign wIdJalRedirectTarget = rIfIdPc + wIdImm;
  assign wIdOlderMayRedirect =
    rIdExValid &&
    ((rIdExBranchType != rv32i_pkg::BR_NONE) ||
     (rIdExJumpType != rv32i_pkg::JUMP_NONE) ||
     (rIdExLoadType != rv32i_pkg::LOAD_NONE) ||
     (rIdExStoreType != rv32i_pkg::STORE_NONE) ||
     (rIdExCsrOp != rv32i_pkg::CSR_NONE) ||
     (rIdExSysOp != rv32i_pkg::SYS_NONE) ||
     rIdExIllegal ||
     !rIdExCsrAddrValid);

  assign wIdJalX0RedirectEn =
    P_FAST_JAL_X0 &&
    rIfIdValid &&
    (wIdJumpType == rv32i_pkg::JUMP_JAL) &&
    (wIdRdAddr == 5'd0) &&
    !wIdIllegal &&
    !rPcRedirectEn &&
    !rIdJalRedirectEn &&
    !rIdBranchRedirectEn &&
    !wIdOlderMayRedirect &&
    !wHazard2Top_LoadUseStall &&
    (wIdJalRedirectTarget[1:0] == 2'b00);

  assign wIdJalRedirectEn =
    rIfIdValid &&
    (wIdJumpType == rv32i_pkg::JUMP_JAL) &&
    !wIdJalX0RedirectEn &&
    !wIdIllegal &&
    !rPcRedirectEn &&
    !rIdJalRedirectEn &&
    !rIdBranchRedirectEn &&
    !wExPcRedirectEn &&
    !wHazard2Top_LoadUseStall &&
    (wIdJalRedirectTarget[1:0] == 2'b00);

  always_comb begin
    wIdUsesRs1 = 1'b0;
    wIdUsesRs2 = 1'b0;

    if (rIfIdValid) begin
      unique case (wIdOpcode)
        rv32i_pkg::LP_OPCODE_RTYPE: begin
          wIdUsesRs1 = 1'b1;
          wIdUsesRs2 = 1'b1;
        end
        rv32i_pkg::LP_OPCODE_OPIMM,
        rv32i_pkg::LP_OPCODE_LOAD,
        rv32i_pkg::LP_OPCODE_JALR: begin
          wIdUsesRs1 = 1'b1;
        end
        rv32i_pkg::LP_OPCODE_STORE,
        rv32i_pkg::LP_OPCODE_BRANCH: begin
          wIdUsesRs1 = 1'b1;
          wIdUsesRs2 = 1'b1;
        end
        rv32i_pkg::LP_OPCODE_SYSTEM: begin
          if ((wIdFunct3 == 3'b001) || (wIdFunct3 == 3'b010) ||
              (wIdFunct3 == 3'b011)) begin
            wIdUsesRs1 = 1'b1;
          end
        end
        default: begin end
      endcase
    end
  end

  always_comb begin
    unique case (wForwardA)
      2'b10:   wExRs1Data = rExMemWbDataNonMem;
      2'b01:   wExRs1Data = rMemWbWrData;
      default: wExRs1Data = rIdExRs1Data;
    endcase
  end

  always_comb begin
    unique case (wForwardB)
      2'b10:   wExRs2Data = rExMemWbDataNonMem;
      2'b01:   wExRs2Data = rMemWbWrData;
      default: wExRs2Data = rIdExRs2Data;
    endcase
  end

  assign wMemStageWbData =
    (rExMemWbSel == rv32i_pkg::WB_MEM) ? wDataRam2Top_RdData : rExMemWbDataNonMem;

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rPcRedirectEn     <= 1'b0;
      rPcRedirectTarget <= 32'd0;
      rIdJalRedirectEn     <= 1'b0;
      rIdJalRedirectTarget <= 32'd0;
      rIdBranchRedirectEn     <= 1'b0;
      rIdBranchRedirectTarget <= 32'd0;
    end
    else begin
      rPcRedirectEn     <= wExPcRedirectEn && !rPcRedirectEn;
      rPcRedirectTarget <= wExPcRedirectTarget;
      rIdJalRedirectEn     <= wIdJalRedirectEn && !rPcRedirectEn;
      rIdJalRedirectTarget <= wIdJalRedirectTarget;
      rIdBranchRedirectEn     <= wIdBranchRedirectEn && !rPcRedirectEn;
      rIdBranchRedirectTarget <= wIdBranchRedirectTarget;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rIfIdValid   <= 1'b0;
      rIfIdPc      <= 32'd0;
      rIfIdPcPlus4 <= 32'd0;
      rIfIdInstr   <= LP_NOP;
    end else if (rPcRedirectEn || wIdJalX0RedirectEn || rIdJalRedirectEn || rIdBranchRedirectEn) begin
      rIfIdValid   <= 1'b0;
      rIfIdPc      <= 32'd0;
      rIfIdPcPlus4 <= 32'd0;
      rIfIdInstr   <= LP_NOP;
    end else if (!wHazard2Top_LoadUseStall) begin
      rIfIdValid   <= 1'b1;
      rIfIdPc      <= wPc2Top_Pc;
      rIfIdPcPlus4 <= wPc2Top_PcPlus4;
      rIfIdInstr   <= wInstrRom2Top_Instr;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rIdExValid     <= 1'b0;
      rIdExIllegal   <= 1'b0;
      rIdExCsrAddrValid <= 1'b1;
      rIdExInstr     <= LP_NOP;
      rIdExPc        <= 32'd0;
      rIdExPcPlus4   <= 32'd0;
      rIdExImm       <= 32'd0;
      rIdExRs1Data   <= 32'd0;
      rIdExRs2Data   <= 32'd0;
      rIdExRs1Addr   <= 5'd0;
      rIdExRs2Addr   <= 5'd0;
      rIdExRdAddr    <= 5'd0;
      rIdExRegWrite  <= 1'b0;
      rIdExMemWrite  <= 1'b0;
      rIdExAluSrc    <= 1'b0;
      rIdExUsesRs1   <= 1'b0;
      rIdExUsesRs2   <= 1'b0;
      rIdExEarlyJal  <= 1'b0;
      rIdExEarlyBranch <= 1'b0;
      rIdExWbSel     <= rv32i_pkg::WB_ALU;
      rIdExAluOp     <= rv32i_pkg::ALU_ADD;
      rIdExLoadType  <= rv32i_pkg::LOAD_NONE;
      rIdExStoreType <= rv32i_pkg::STORE_NONE;
      rIdExBranchType<= rv32i_pkg::BR_NONE;
      rIdExJumpType  <= rv32i_pkg::JUMP_NONE;
      rIdExCsrOp     <= rv32i_pkg::CSR_NONE;
      rIdExSysOp     <= rv32i_pkg::SYS_NONE;
    end else if (rPcRedirectEn || wIdJalX0RedirectEn || rIdJalRedirectEn || rIdBranchRedirectEn || wHazard2Top_LoadUseStall) begin
      rIdExValid     <= 1'b0;
      rIdExIllegal   <= 1'b0;
      rIdExCsrAddrValid <= 1'b1;
      rIdExInstr     <= LP_NOP;
      rIdExPc        <= 32'd0;
      rIdExPcPlus4   <= 32'd0;
      rIdExImm       <= 32'd0;
      rIdExRs1Data   <= 32'd0;
      rIdExRs2Data   <= 32'd0;
      rIdExRs1Addr   <= 5'd0;
      rIdExRs2Addr   <= 5'd0;
      rIdExRdAddr    <= 5'd0;
      rIdExRegWrite  <= 1'b0;
      rIdExMemWrite  <= 1'b0;
      rIdExAluSrc    <= 1'b0;
      rIdExUsesRs1   <= 1'b0;
      rIdExUsesRs2   <= 1'b0;
      rIdExEarlyJal  <= 1'b0;
      rIdExEarlyBranch <= 1'b0;
      rIdExWbSel     <= rv32i_pkg::WB_ALU;
      rIdExAluOp     <= rv32i_pkg::ALU_ADD;
      rIdExLoadType  <= rv32i_pkg::LOAD_NONE;
      rIdExStoreType <= rv32i_pkg::STORE_NONE;
      rIdExBranchType<= rv32i_pkg::BR_NONE;
      rIdExJumpType  <= rv32i_pkg::JUMP_NONE;
      rIdExCsrOp     <= rv32i_pkg::CSR_NONE;
      rIdExSysOp     <= rv32i_pkg::SYS_NONE;
    end else begin
      rIdExValid      <= rIfIdValid;
      rIdExIllegal    <= wIdIllegal;
      rIdExCsrAddrValid <= wIdCsrAddrValid;
      rIdExInstr      <= rIfIdInstr;
      rIdExPc         <= rIfIdPc;
      rIdExPcPlus4    <= rIfIdPcPlus4;
      rIdExImm        <= wIdImm;
      rIdExRs1Data    <= wIdRs1Data;
      rIdExRs2Data    <= wIdRs2Data;
      rIdExRs1Addr    <= wIdRs1Addr;
      rIdExRs2Addr    <= wIdRs2Addr;
      rIdExRdAddr     <= wIdRdAddr;
      rIdExRegWrite   <= wIdRegWrite;
      rIdExMemWrite   <= wIdMemWrite;
      rIdExAluSrc     <= wIdAluSrc;
      rIdExUsesRs1    <= wIdUsesRs1;
      rIdExUsesRs2    <= wIdUsesRs2;
      rIdExEarlyJal   <= wIdJalRedirectEn;
      rIdExEarlyBranch <= wIdBranchRedirectEn;
      rIdExWbSel      <= wIdWbSel;
      rIdExAluOp      <= wIdAluOp;
      rIdExLoadType   <= wIdLoadType;
      rIdExStoreType  <= wIdStoreType;
      rIdExBranchType <= wIdBranchType;
      rIdExJumpType   <= wIdJumpType;
      rIdExCsrOp      <= wIdCsrOp;
      rIdExSysOp      <= wIdSysOp;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rExMemValid      <= 1'b0;
      rExMemIllegal    <= 1'b0;
      rExMemRegWrite   <= 1'b0;
      rExMemMemWrite   <= 1'b0;
      rExMemForwardEn  <= 1'b0;
      rExMemRdAddr     <= 5'd0;
      rExMemAluResult  <= 32'd0;
      rExMemStoreData  <= 32'd0;
      rExMemWbDataNonMem <= 32'd0;
      rExMemWbSel      <= rv32i_pkg::WB_ALU;
      rExMemLoadType   <= rv32i_pkg::LOAD_NONE;
      rExMemStoreType  <= rv32i_pkg::STORE_NONE;
    end else begin
      rExMemValid        <= rIdExValid && !rPcRedirectEn && !wExTrapEn && !wExMretEn;
      rExMemIllegal      <= rIdExIllegal;
      rExMemRegWrite     <= rIdExRegWrite && !rPcRedirectEn && !wExTrapEn && !wExMretEn;
      rExMemMemWrite     <= rIdExMemWrite && !rPcRedirectEn && !wExTrapEn && !wExMretEn;
      rExMemForwardEn    <= rIdExValid && rIdExRegWrite &&
                             (rIdExRdAddr != 5'd0) &&
                             (rIdExLoadType == rv32i_pkg::LOAD_NONE) &&
                             !rPcRedirectEn && !wExTrapEn && !wExMretEn;
      rExMemRdAddr       <= rIdExRdAddr;
      rExMemAluResult    <= wExAluResult;
      rExMemStoreData    <= wExStoreData;
      rExMemWbDataNonMem <= wExWbDataNonMem;
      rExMemWbSel        <= rIdExWbSel;
      rExMemLoadType     <= rIdExLoadType;
      rExMemStoreType    <= rIdExStoreType;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rMemWbValid    <= 1'b0;
      rMemWbIllegal  <= 1'b0;
      rMemWbRegWrite <= 1'b0;
      rMemWbForwardEn <= 1'b0;
      rMemWbRdAddr   <= 5'd0;
      rMemWbWrData   <= 32'd0;
    end else begin
      rMemWbValid    <= rExMemValid;
      rMemWbIllegal  <= rExMemIllegal;
      rMemWbRegWrite <= rExMemRegWrite;
      rMemWbForwardEn <= rExMemRegWrite && (rExMemRdAddr != 5'd0);
      rMemWbRdAddr   <= rExMemRdAddr;
      rMemWbWrData   <= wMemStageWbData;
    end
  end

endmodule
