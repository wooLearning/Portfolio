`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: Rv32Core
Role: Five-stage RV32I pipeline core with external instruction/data memory ports
Summary:
  - Connects Fetch, Decode, Execute, Memory, and Writeback stage modules
  - Keeps pipeline registers and stage-level control visible at the core boundary
  - Uses packed pipeline packets to avoid stage-port explosion
  - Preserves the original bus wait, load-use bubble, forwarding, early redirect, and trap behavior
StateDescription:
  - rIfId: IF/ID pipeline packet
  - rIdEx: ID/EX pipeline packet
  - rExMem: EX/MEM pipeline packet
  - rMemWb: MEM/WB pipeline packet
[MODULE_INFO_END]
*/
module Rv32Core #(
  parameter bit P_ID_EARLY_BRANCH = 1'b1,
  parameter bit P_FAST_JAL_X0 = 1'b1
) (
  input logic iClk,
  input logic iRstn,
  output logic        oIBusValid,
  output logic [31:0] oIBusAddr,
  input  logic        iIBusReady,
  input  logic [31:0] iIBusRData,
  input  logic        iIBusError,
  output logic        oDBusValid,
  output logic        oDBusWrite,
  output logic [31:0] oDBusAddr,
  output logic [1:0]  oDBusSize,
  output logic [31:0] oDBusWData,
  input  logic        iDBusReady,
  input  logic [31:0] iDBusRData,
  input  logic        iDBusError,
  input  logic        iSoftwareIrq,
  input  logic        iTimerIrq,
  input  logic        iExternalIrq,
  output logic [31:0] oDbgPc,
  output logic        oDbgLoadUseStall,
  output logic        oDbgBusWaitStall,
  output logic        oDbgRetireValid,
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

  rv32i_pkg::if_id_packet_t  wFetchPacket;
  rv32i_pkg::if_id_packet_t  rIfId;
  rv32i_pkg::id_ex_packet_t  wDecodePacket;
  rv32i_pkg::id_ex_packet_t  rIdEx;
  rv32i_pkg::ex_mem_packet_t wExMemPacket;
  rv32i_pkg::ex_mem_packet_t rExMem;
  rv32i_pkg::mem_wb_packet_t wMemWbPacket;
  rv32i_pkg::mem_wb_packet_t rMemWb;

  logic        wPcWriteEn;
  logic        wPcTargetEn;
  logic [31:0] wPcTarget;
  logic        wIfIdFlush;
  logic        wIfIdWriteEn;
  logic        wIdExFlush;
  logic        wIdExHold;
  logic        wExMemHold;
  logic        wMemWbHold;
  logic        wFetchWaitStall;
  logic        wDataWaitStall;
  logic        wBusWaitStall;
  logic        wPipelineStall;
  logic        wLoadUseStall;
  logic        wExRedirectPending;

  logic        wIdJalCandidate;
  logic        wIdJalX0Candidate;
  logic        wIdBranchCandidate;
  logic [31:0] wIdJalTarget;
  logic [31:0] wIdBranchTarget;
  logic        wIdBtbUpdateValid;
  logic        wIdBtbUpdateTaken;
  logic [31:0] wIdBtbUpdatePc;
  logic [31:0] wIdBtbUpdateTarget;
  logic        rBtbUpdateValid;
  logic        rBtbUpdateTaken;
  logic [31:0] rBtbUpdatePc;
  logic [31:0] rBtbUpdateTarget;
  logic        wIdJalRedirectEn;
  logic        wIdJalX0RedirectEn;
  logic        wIdBranchRedirectEn;
  logic [4:0]  wIdRs1Addr;
  logic [4:0]  wIdRs2Addr;
  logic        wIdUsesRs1;
  logic        wIdUsesRs2;

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
  logic        wInterruptPending;
  logic [3:0]  wInterruptCause;

  logic        wMemTrapEn;
  logic [3:0]  wMemTrapCause;
  logic [31:0] wMemTrapTval;
  logic [31:0] wMemTrapPc;
  logic        wIrqTrapEn;
  logic        wTrapEn;
  logic        wTrapIsInterrupt;
  logic [31:0] wTrapPc;
  logic [3:0]  wTrapCause;
  logic [31:0] wTrapTval;
  logic        wTrapRedirectEn;
  logic [31:0] wTrapRedirectTarget;
  logic        wExOnlyPcRedirectEn;
  logic [31:0] wExOnlyPcRedirectTarget;

  logic        wWbRegWriteEn;
  logic [4:0]  wWbRdAddr;
  logic [31:0] wWbRdWrData;
  logic        wWbRetireValid;

  assign oDbgLoadUseStall   = wLoadUseStall;
  assign oDbgBusWaitStall   = wBusWaitStall;
  assign oDbgRetireValid    = wWbRetireValid;
  assign oDbgForwardA       = wForwardA;
  assign oDbgForwardB       = wForwardB;
  assign oDbgExPcRedirectEn = wTrapRedirectEn || wExOnlyPcRedirectEn ||
                              wIdJalRedirectEn || wIdBranchRedirectEn;
  assign oDbgTrapEn         = wTrapEn;
  assign oDbgTrapCause      = rv32i_pkg::exc_cause_e'(wTrapCause);
  assign oDbgMtvec          = wCsrMtvec;
  assign oDbgMepc           = wCsrMepc;
  assign oDbgMcause         = wCsrMcause;
  assign oDbgMtval          = wCsrMtval;

  FetchStage uFetchStage (
    .iClk             (iClk),
    .iRstn            (iRstn),
    .iPcWriteEn       (wPcWriteEn),
    .iPcTargetEn      (wPcTargetEn),
    .iPcTarget        (wPcTarget),
    .iBtbUpdateValid  (rBtbUpdateValid),
    .iBtbUpdateTaken  (rBtbUpdateTaken),
    .iBtbUpdatePc     (rBtbUpdatePc),
    .iBtbUpdateTarget (rBtbUpdateTarget),
    .iIBusReady       (iIBusReady),
    .iIBusRData       (iIBusRData),
    .iIBusError       (iIBusError),
    .oIBusValid       (oIBusValid),
    .oIBusAddr        (oIBusAddr),
    .oFetchWaitStall  (wFetchWaitStall),
    .oFetchPacket     (wFetchPacket),
    .oDbgPc           (oDbgPc)
  );

  DecodeStage #(
    .P_ID_EARLY_BRANCH (P_ID_EARLY_BRANCH),
    .P_FAST_JAL_X0     (P_FAST_JAL_X0)
  ) uDecodeStage (
    .iClk                (iClk),
    .iRstn               (iRstn),
    .iIfIdPacket         (rIfId),
    .iIdExPacket         (rIdEx),
    .iExMemPacket        (rExMem),
    .iMemWbPacket        (rMemWb),
    .iWbRegWriteEn       (wWbRegWriteEn),
    .iIdJalRedirectEn    (wIdJalRedirectEn),
    .iIdBranchRedirectEn (wIdBranchRedirectEn),
    .oDecodePacket       (wDecodePacket),
    .oIdJalCandidate     (wIdJalCandidate),
    .oIdJalX0Candidate   (wIdJalX0Candidate),
    .oIdBranchCandidate  (wIdBranchCandidate),
    .oIdJalTarget        (wIdJalTarget),
    .oIdBranchTarget     (wIdBranchTarget),
    .oIdBtbUpdateValid   (wIdBtbUpdateValid),
    .oIdBtbUpdateTaken   (wIdBtbUpdateTaken),
    .oIdBtbUpdatePc      (wIdBtbUpdatePc),
    .oIdBtbUpdateTarget  (wIdBtbUpdateTarget),
    .oIdRs1Addr          (wIdRs1Addr),
    .oIdRs2Addr          (wIdRs2Addr),
    .oIdUsesRs1          (wIdUsesRs1),
    .oIdUsesRs2          (wIdUsesRs2)
  );

  HazardUnit uHazardUnit (
    .iIdValid      (rIfId.valid),
    .iIdRs1Addr    (wIdRs1Addr),
    .iIdRs2Addr    (wIdRs2Addr),
    .iIdUsesRs1    (wIdUsesRs1),
    .iIdUsesRs2    (wIdUsesRs2),
    .iExValid      (rIdEx.valid),
    .iExRdAddr     (rIdEx.rd_addr),
    .iExIsLoad     (rIdEx.load_type != rv32i_pkg::LOAD_NONE),
    .oLoadUseStall (wLoadUseStall)
  );

  ForwardingUnit uForwardingUnit (
    .iExRs1Addr    (rIdEx.rs1_addr),
    .iExRs2Addr    (rIdEx.rs2_addr),
    .iExUsesRs1    (rIdEx.uses_rs1),
    .iExUsesRs2    (rIdEx.uses_rs2),
    .iMemRdAddr    (rExMem.rd_addr),
    .iMemForwardEn (rExMem.forward_en),
    .iWbRdAddr     (rMemWb.rd_addr),
    .iWbForwardEn  (rMemWb.forward_en),
    .oForwardA     (wForwardA),
    .oForwardB     (wForwardB)
  );

  always_comb begin
    unique case (wForwardA)
      2'b10:   wExRs1Data = rExMem.wb_data_non_mem;
      2'b01:   wExRs1Data = rMemWb.wr_data;
      default: wExRs1Data = rIdEx.rs1_data;
    endcase
  end

  always_comb begin
    unique case (wForwardB)
      2'b10:   wExRs2Data = rExMem.wb_data_non_mem;
      2'b01:   wExRs2Data = rMemWb.wr_data;
      default: wExRs2Data = rIdEx.rs2_data;
    endcase
  end

  ExecuteStage uExecuteStage (
    .iValid             (rIdEx.valid),
    .iPcRedirectPending (wExRedirectPending),
    .iInstrAccessFault  (rIdEx.instr_error),
    .iPredictedTaken    (rIdEx.predicted_taken),
    .iEarlyJal          (rIdEx.early_jal),
    .iEarlyBranch       (rIdEx.early_branch),
    .iIllegal           (rIdEx.illegal),
    .iCsrAddrValid      (rIdEx.csr_addr_valid),
    .iInstr             (rIdEx.instr),
    .iPc                (rIdEx.pc),
    .iPcPlus4           (rIdEx.pc_plus4),
    .iPredictedTarget   (rIdEx.predicted_target),
    .iImm               (rIdEx.imm),
    .iRs1Data           (wExRs1Data),
    .iRs2Data           (wExRs2Data),
    .iRs1Addr           (rIdEx.rs1_addr),
    .iAluSrc            (rIdEx.alu_src),
    .iAluOp             (rIdEx.alu_op),
    .iWbSel             (rIdEx.wb_sel),
    .iLoadType          (rIdEx.load_type),
    .iStoreType         (rIdEx.store_type),
    .iBranchType        (rIdEx.branch_type),
    .iJumpType          (rIdEx.jump_type),
    .iCsrOp             (rIdEx.csr_op),
    .iSysOp             (rIdEx.sys_op),
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

  CsrFile uCsrFile (
    .iClk          (iClk),
    .iRstn         (iRstn),
    .iCsrAddr      (wExCsrAddr),
    .iCsrOp        (rIdEx.csr_op),
    .iCsrWrData    (wExCsrWrOperand),
    .iCsrWriteEn   (wExCsrWriteEn),
    .iTrapEn       (wTrapEn),
    .iTrapIsInterrupt(wTrapIsInterrupt),
    .iTrapPc       (wTrapPc),
    .iTrapCause    (wTrapCause),
    .iTrapTval     (wTrapTval),
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
    .iSoftwareIrq      (iSoftwareIrq),
    .iTimerIrq         (iTimerIrq),
    .iExternalIrq      (iExternalIrq),
    .iMstatus          (wCsrMstatus),
    .iMie              (wCsrMie),
    .iMipSw            (wCsrMipSw),
    .oMip              (wMip),
    .oInterruptPending (wInterruptPending),
    .oInterruptCause   (wInterruptCause)
  );

  TrapController uTrapController (
    .iInterruptPending    (wInterruptPending),
    .iInterruptCause      (wInterruptCause),
    .iMtvec               (wCsrMtvec),
    .iBusWaitStall        (wBusWaitStall),
    .iExRedirectPending   (wExRedirectPending),
    .iMemTrapEn           (wMemTrapEn),
    .iMemTrapCause        (wMemTrapCause),
    .iMemTrapTval         (wMemTrapTval),
    .iMemTrapPc           (wMemTrapPc),
    .iExTrapEn            (wExTrapEn),
    .iExTrapCause         (wExTrapCause),
    .iExTrapTval          (wExTrapTval),
    .iExTrapPc            (rIdEx.pc),
    .iExPcRedirectEn      (wExPcRedirectEn),
    .iExPcRedirectTarget  (wExPcRedirectTarget),
    .iFetchPc             (oDbgPc),
    .oIrqTrapEn           (wIrqTrapEn),
    .oTrapEn              (wTrapEn),
    .oTrapIsInterrupt     (wTrapIsInterrupt),
    .oTrapCause           (wTrapCause),
    .oTrapPc              (wTrapPc),
    .oTrapTval            (wTrapTval),
    .oTrapRedirectEn      (wTrapRedirectEn),
    .oTrapRedirectTarget  (wTrapRedirectTarget),
    .oExOnlyPcRedirectEn  (wExOnlyPcRedirectEn),
    .oExOnlyPcRedirectTarget(wExOnlyPcRedirectTarget)
  );

  always_comb begin
    wExMemPacket.valid           = rIdEx.valid && !wExRedirectPending && !wExTrapEn && !wExMretEn;
    wExMemPacket.pc              = rIdEx.pc;
    wExMemPacket.illegal         = rIdEx.illegal;
    wExMemPacket.reg_write       = rIdEx.reg_write && !wExRedirectPending && !wExTrapEn && !wExMretEn;
    wExMemPacket.mem_write       = rIdEx.mem_write && !wExRedirectPending && !wExTrapEn && !wExMretEn;
    wExMemPacket.forward_en      = rIdEx.valid && rIdEx.reg_write &&
                                   (rIdEx.rd_addr != 5'd0) &&
                                   (rIdEx.load_type == rv32i_pkg::LOAD_NONE) &&
                                   !wExRedirectPending && !wExTrapEn && !wExMretEn;
    wExMemPacket.rd_addr         = rIdEx.rd_addr;
    wExMemPacket.alu_result      = wExAluResult;
    wExMemPacket.store_data      = wExStoreData;
    wExMemPacket.wb_data_non_mem = wExWbDataNonMem;
    wExMemPacket.wb_sel          = rIdEx.wb_sel;
    wExMemPacket.load_type       = rIdEx.load_type;
    wExMemPacket.store_type      = rIdEx.store_type;
  end

  MemoryStage uMemoryStage (
    .iExMemPacket  (rExMem),
    .iDBusReady    (iDBusReady),
    .iDBusRData    (iDBusRData),
    .iDBusError    (iDBusError),
    .oDBusValid    (oDBusValid),
    .oDBusWrite    (oDBusWrite),
    .oDBusAddr     (oDBusAddr),
    .oDBusSize     (oDBusSize),
    .oDBusWData    (oDBusWData),
    .oDataWaitStall(wDataWaitStall),
    .oMemTrapEn    (wMemTrapEn),
    .oMemTrapCause (wMemTrapCause),
    .oMemTrapTval  (wMemTrapTval),
    .oMemTrapPc    (wMemTrapPc),
    .oMemWbPacket  (wMemWbPacket)
  );

  WritebackStage uWritebackStage (
    .iMemWbPacket (rMemWb),
    .iBusWaitStall(wBusWaitStall),
    .oRegWriteEn  (wWbRegWriteEn),
    .oRdAddr      (wWbRdAddr),
    .oRdWrData    (wWbRdWrData),
    .oRetireValid (wWbRetireValid)
  );

  PipelineControl uPipelineControl (
    .iClk                (iClk),
    .iRstn               (iRstn),
    .iFetchWaitStall     (wFetchWaitStall),
    .iDataWaitStall      (wDataWaitStall),
    .iLoadUseStall       (wLoadUseStall),
    .iTrapRedirectEn     (wTrapRedirectEn),
    .iTrapRedirectTarget (wTrapRedirectTarget),
    .iExPcRedirectEn     (wExOnlyPcRedirectEn),
    .iExPcRedirectTarget (wExOnlyPcRedirectTarget),
    .iIdJalCandidate     (wIdJalCandidate),
    .iIdJalX0Candidate   (wIdJalX0Candidate),
    .iIdBranchCandidate  (wIdBranchCandidate),
    .iIdJalTarget        (wIdJalTarget),
    .iIdBranchTarget     (wIdBranchTarget),
    .oBusWaitStall       (wBusWaitStall),
    .oPipelineStall      (wPipelineStall),
    .oPcWriteEn          (wPcWriteEn),
    .oPcTargetEn         (wPcTargetEn),
    .oPcTarget           (wPcTarget),
    .oIfIdFlush          (wIfIdFlush),
    .oIfIdWriteEn        (wIfIdWriteEn),
    .oIdExFlush          (wIdExFlush),
    .oIdExHold           (wIdExHold),
    .oExMemHold          (wExMemHold),
    .oMemWbHold          (wMemWbHold),
    .oExRedirectPending  (wExRedirectPending),
    .oIdJalRedirectEn    (wIdJalRedirectEn),
    .oIdJalX0RedirectEn  (wIdJalX0RedirectEn),
    .oIdBranchRedirectEn (wIdBranchRedirectEn)
  );

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rBtbUpdateValid  <= 1'b0;
      rBtbUpdateTaken  <= 1'b0;
      rBtbUpdatePc     <= 32'd0;
      rBtbUpdateTarget <= 32'd0;
    end
    else begin
      rBtbUpdateValid  <= wIdBtbUpdateValid && !wPipelineStall;
      rBtbUpdateTaken  <= wIdBtbUpdateTaken;
      rBtbUpdatePc     <= wIdBtbUpdatePc;
      rBtbUpdateTarget <= wIdBtbUpdateTarget;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rIfId <= '{
        valid:    1'b0,
        instr_error: 1'b0,
        predicted_taken: 1'b0,
        pc:       32'd0,
        pc_plus4: 32'd0,
        predicted_target: 32'd0,
        instr:    LP_NOP
      };
    end
    else if (wIfIdFlush) begin
      rIfId <= '{
        valid:    1'b0,
        instr_error: 1'b0,
        predicted_taken: 1'b0,
        pc:       32'd0,
        pc_plus4: 32'd0,
        predicted_target: 32'd0,
        instr:    LP_NOP
      };
    end
    else if (wIfIdWriteEn) begin
      rIfId <= wFetchPacket;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rIdEx <= '{
        valid:          1'b0,
        instr_error:    1'b0,
        illegal:        1'b0,
        csr_addr_valid: 1'b1,
        predicted_taken: 1'b0,
        instr:          LP_NOP,
        pc:             32'd0,
        pc_plus4:       32'd0,
        predicted_target: 32'd0,
        imm:            32'd0,
        rs1_data:       32'd0,
        rs2_data:       32'd0,
        rs1_addr:       5'd0,
        rs2_addr:       5'd0,
        rd_addr:        5'd0,
        reg_write:      1'b0,
        mem_write:      1'b0,
        alu_src:        1'b0,
        uses_rs1:       1'b0,
        uses_rs2:       1'b0,
        early_jal:      1'b0,
        early_branch:   1'b0,
        wb_sel:         rv32i_pkg::WB_ALU,
        alu_op:         rv32i_pkg::ALU_ADD,
        load_type:      rv32i_pkg::LOAD_NONE,
        store_type:     rv32i_pkg::STORE_NONE,
        branch_type:    rv32i_pkg::BR_NONE,
        jump_type:      rv32i_pkg::JUMP_NONE,
        csr_op:         rv32i_pkg::CSR_NONE,
        sys_op:         rv32i_pkg::SYS_NONE
      };
    end
    else if (wIdExFlush) begin
      rIdEx <= '{
        valid:          1'b0,
        instr_error:    1'b0,
        illegal:        1'b0,
        csr_addr_valid: 1'b1,
        predicted_taken: 1'b0,
        instr:          LP_NOP,
        pc:             32'd0,
        pc_plus4:       32'd0,
        predicted_target: 32'd0,
        imm:            32'd0,
        rs1_data:       32'd0,
        rs2_data:       32'd0,
        rs1_addr:       5'd0,
        rs2_addr:       5'd0,
        rd_addr:        5'd0,
        reg_write:      1'b0,
        mem_write:      1'b0,
        alu_src:        1'b0,
        uses_rs1:       1'b0,
        uses_rs2:       1'b0,
        early_jal:      1'b0,
        early_branch:   1'b0,
        wb_sel:         rv32i_pkg::WB_ALU,
        alu_op:         rv32i_pkg::ALU_ADD,
        load_type:      rv32i_pkg::LOAD_NONE,
        store_type:     rv32i_pkg::STORE_NONE,
        branch_type:    rv32i_pkg::BR_NONE,
        jump_type:      rv32i_pkg::JUMP_NONE,
        csr_op:         rv32i_pkg::CSR_NONE,
        sys_op:         rv32i_pkg::SYS_NONE
      };
    end
    else if (wIdExHold) begin
    end
    else begin
      rIdEx <= wDecodePacket;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rExMem <= '{
        valid:           1'b0,
        pc:              32'd0,
        illegal:         1'b0,
        reg_write:       1'b0,
        mem_write:       1'b0,
        forward_en:      1'b0,
        rd_addr:         5'd0,
        alu_result:      32'd0,
        store_data:      32'd0,
        wb_data_non_mem: 32'd0,
        wb_sel:          rv32i_pkg::WB_ALU,
        load_type:       rv32i_pkg::LOAD_NONE,
        store_type:      rv32i_pkg::STORE_NONE
      };
    end
    else if (wExMemHold) begin
    end
    else begin
      rExMem <= wExMemPacket;
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rMemWb <= '{
        valid:      1'b0,
        illegal:    1'b0,
        reg_write:  1'b0,
        forward_en: 1'b0,
        rd_addr:    5'd0,
        wr_data:    32'd0
      };
    end
    else if (wMemWbHold) begin
    end
    else begin
      rMemWb <= wMemWbPacket;
    end
  end

endmodule
