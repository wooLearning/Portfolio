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
    .iClk             (iClk),              // core clock from SocTop
    .iRstn            (iRstn),             // active-low core reset from SocTop
    .iPcWriteEn       (wPcWriteEn),        // from PipelineControl: PC update enable
    .iPcTargetEn      (wPcTargetEn),       // from PipelineControl: force PC to target
    .iPcTarget        (wPcTarget),         // from PipelineControl: redirect target PC

    .iBtbUpdateValid  (rBtbUpdateValid),   // from registered Decode BTB feedback
    .iBtbUpdateTaken  (rBtbUpdateTaken),   // from registered Decode branch result
    .iBtbUpdatePc     (rBtbUpdatePc),      // from registered Decode branch/JAL PC
    .iBtbUpdateTarget (rBtbUpdateTarget),  // from registered Decode resolved target

    .iIBusReady       (iIBusReady),        // from SocTop IBus: instruction data ready
    .iIBusRData       (iIBusRData),        // from SocTop IBus: fetched instruction
    .iIBusError       (iIBusError),        // from SocTop IBus: fetch error flag

    .oIBusValid       (oIBusValid),        // to SocTop IBus: fetch request valid
    .oIBusAddr        (oIBusAddr),         // to SocTop IBus: fetch PC address

    .oFetchWaitStall  (wFetchWaitStall),   // to PipelineControl: fetch waits for IBus
    .oFetchPacket     (wFetchPacket),      // to IF/ID register: fetched instruction packet

    .oDbgPc           (oDbgPc)             // to SocTop/debug: current fetch PC
  );

  DecodeStage #(
    .P_ID_EARLY_BRANCH (P_ID_EARLY_BRANCH),
    .P_FAST_JAL_X0     (P_FAST_JAL_X0)
  ) uDecodeStage (
    .iClk                (iClk),                // core clock
    .iRstn               (iRstn),               // active-low core reset
    .iIfIdPacket         (rIfId),               // from IF/ID register: instruction to decode
    .iIdExPacket         (rIdEx),               // from ID/EX register: older instruction info
    .iExMemPacket        (rExMem),              // from EX/MEM register: forwarding/write info
    .iMemWbPacket        (rMemWb),              // from MEM/WB register: writeback info
    .iWbRegWriteEn       (wWbRegWriteEn),       // from WritebackStage: regfile write enable
    .iIdJalRedirectEn    (wIdJalRedirectEn),    // from PipelineControl: ID JAL redirect accepted
    .iIdBranchRedirectEn (wIdBranchRedirectEn), // from PipelineControl: ID branch redirect accepted

    .oDecodePacket       (wDecodePacket),       // to ID/EX register: decoded control/data packet
    .oIdJalCandidate     (wIdJalCandidate),     // to PipelineControl: ID JAL wants redirect
    .oIdJalX0Candidate   (wIdJalX0Candidate),   // to PipelineControl: fast JAL x0 redirect
    .oIdBranchCandidate  (wIdBranchCandidate),  // to PipelineControl: branch redirect/mispredict
    .oIdJalTarget        (wIdJalTarget),        // to PipelineControl: ID JAL target PC
    .oIdBranchTarget     (wIdBranchTarget),     // to PipelineControl: ID branch correct PC
    .oIdBtbUpdateValid   (wIdBtbUpdateValid),   // to BTB feedback register: update pulse
    .oIdBtbUpdateTaken   (wIdBtbUpdateTaken),   // to BTB feedback register: resolved taken
    .oIdBtbUpdatePc      (wIdBtbUpdatePc),      // to BTB feedback register: branch/JAL PC
    .oIdBtbUpdateTarget  (wIdBtbUpdateTarget),  // to BTB feedback register: resolved target
    .oIdRs1Addr          (wIdRs1Addr),          // to HazardUnit: ID source rs1
    .oIdRs2Addr          (wIdRs2Addr),          // to HazardUnit: ID source rs2
    .oIdUsesRs1          (wIdUsesRs1),          // to HazardUnit: ID actually uses rs1
    .oIdUsesRs2          (wIdUsesRs2)           // to HazardUnit: ID actually uses rs2
  );

  HazardUnit uHazardUnit (
    .iIdValid      (rIfId.valid),                          // from IF/ID: ID instruction valid
    .iIdRs1Addr    (wIdRs1Addr),                           // from DecodeStage: ID rs1 address
    .iIdRs2Addr    (wIdRs2Addr),                           // from DecodeStage: ID rs2 address
    .iIdUsesRs1    (wIdUsesRs1),                           // from DecodeStage: ID reads rs1
    .iIdUsesRs2    (wIdUsesRs2),                           // from DecodeStage: ID reads rs2
    .iExValid      (rIdEx.valid),                          // from ID/EX: EX instruction valid
    .iExRdAddr     (rIdEx.rd_addr),                        // from ID/EX: EX destination rd
    .iExIsLoad     (rIdEx.load_type != rv32i_pkg::LOAD_NONE), // from ID/EX: EX is load
    .oLoadUseStall (wLoadUseStall)                         // to PipelineControl: need load-use bubble
  );

  ForwardingUnit uForwardingUnit (
    .iExRs1Addr    (rIdEx.rs1_addr),    // from ID/EX: EX operand A source register
    .iExRs2Addr    (rIdEx.rs2_addr),    // from ID/EX: EX operand B source register
    .iExUsesRs1    (rIdEx.uses_rs1),    // from ID/EX: EX actually uses rs1
    .iExUsesRs2    (rIdEx.uses_rs2),    // from ID/EX: EX actually uses rs2
    .iMemRdAddr    (rExMem.rd_addr),    // from EX/MEM: MEM-stage destination rd
    .iMemForwardEn (rExMem.forward_en), // from EX/MEM: MEM result can forward
    .iWbRdAddr     (rMemWb.rd_addr),    // from MEM/WB: WB-stage destination rd
    .iWbForwardEn  (rMemWb.forward_en), // from MEM/WB: WB result can forward
    .oForwardA     (wForwardA),         // to EX operand mux: select rs1 source
    .oForwardB     (wForwardB)          // to EX operand mux: select rs2 source
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
    .iValid             (rIdEx.valid),            // from ID/EX: EX instruction valid
    .iPcRedirectPending (wExRedirectPending),     // from PipelineControl: older redirect pending
    .iInstrAccessFault  (rIdEx.instr_error),      // from ID/EX: fetch bus error
    .iPredictedTaken    (rIdEx.predicted_taken),  // from ID/EX: BTB predicted taken
    .iEarlyJal          (rIdEx.early_jal),        // from DecodeStage packet: ID already handled JAL
    .iEarlyBranch       (rIdEx.early_branch),     // from DecodeStage packet: ID already handled branch
    .iIllegal           (rIdEx.illegal),          // from ID/EX: illegal instruction flag
    .iCsrAddrValid      (rIdEx.csr_addr_valid),   // from ID/EX: CSR address decode result
    .iInstr             (rIdEx.instr),            // from ID/EX: raw instruction
    .iPc                (rIdEx.pc),               // from ID/EX: instruction PC
    .iPcPlus4           (rIdEx.pc_plus4),         // from ID/EX: sequential PC
    .iPredictedTarget   (rIdEx.predicted_target), // from ID/EX: BTB predicted target
    .iImm               (rIdEx.imm),              // from ID/EX: decoded immediate
    .iRs1Data           (wExRs1Data),             // from forwarding mux: final rs1 operand
    .iRs2Data           (wExRs2Data),             // from forwarding mux: final rs2 operand
    .iRs1Addr           (rIdEx.rs1_addr),         // from ID/EX: rs1 address for CSR immediate cases
    .iAluSrc            (rIdEx.alu_src),          // from ID/EX: ALU B operand select
    .iAluOp             (rIdEx.alu_op),           // from ID/EX: ALU operation
    .iWbSel             (rIdEx.wb_sel),           // from ID/EX: writeback data select
    .iLoadType          (rIdEx.load_type),        // from ID/EX: load type
    .iStoreType         (rIdEx.store_type),       // from ID/EX: store type
    .iBranchType        (rIdEx.branch_type),      // from ID/EX: branch condition type
    .iJumpType          (rIdEx.jump_type),        // from ID/EX: JAL/JALR type
    .iCsrOp             (rIdEx.csr_op),           // from ID/EX: CSR operation
    .iSysOp             (rIdEx.sys_op),           // from ID/EX: ECALL/MRET/etc.
    .iCsrRdData         (wCsrRdData),             // from CsrFile: CSR read data
    .iCsrMtvec          (wCsrMtvec),              // from CsrFile: trap vector
    .iCsrMepc           (wCsrMepc),               // from CsrFile: exception return PC
    .oAluResult         (wExAluResult),           // to EX/MEM packet: ALU result
    .oStoreData         (wExStoreData),           // to EX/MEM packet: store write data
    .oWbDataNonMem      (wExWbDataNonMem),        // to EX/MEM forwarding: non-load WB data
    .oBranchTaken       (wExBranchTaken),         // debug/internal: branch actual result
    .oPcRedirectEn      (wExPcRedirectEn),        // to TrapController: EX resolved redirect
    .oPcRedirectTarget  (wExPcRedirectTarget),    // to TrapController: EX redirect target
    .oTrapEn            (wExTrapEn),              // to TrapController: EX exception/trap
    .oTrapCause         (wExTrapCause),           // to TrapController: EX trap cause
    .oTrapTval          (wExTrapTval),            // to TrapController: EX trap value
    .oMretEn            (wExMretEn),              // to CsrFile/EXMEM gating: MRET seen
    .oCsrAddr           (wExCsrAddr),             // to CsrFile: CSR address
    .oCsrWrOperand      (wExCsrWrOperand),        // to CsrFile: CSR write operand
    .oCsrWriteEn        (wExCsrWriteEn)           // to CsrFile: CSR write enable
  );

  CsrFile uCsrFile (
    .iClk          (iClk),              // core clock
    .iRstn         (iRstn),             // active-low core reset
    .iCsrAddr      (wExCsrAddr),        // from ExecuteStage: CSR address
    .iCsrOp        (rIdEx.csr_op),      // from ID/EX: CSR operation type
    .iCsrWrData    (wExCsrWrOperand),   // from ExecuteStage: CSR write data
    .iCsrWriteEn   (wExCsrWriteEn),     // from ExecuteStage: CSR write enable
    .iTrapEn       (wTrapEn),           // from TrapController: take trap now
    .iTrapIsInterrupt(wTrapIsInterrupt), // from TrapController: trap is interrupt
    .iTrapPc       (wTrapPc),           // from TrapController: PC to save into mepc
    .iTrapCause    (wTrapCause),        // from TrapController: mcause value
    .iTrapTval     (wTrapTval),         // from TrapController: mtval value
    .iMretEn       (wExMretEn),         // from ExecuteStage: MRET updates status
    .iMip          (wMip),              // from MachineInterruptController: pending IRQ bits
    .oCsrRdData    (wCsrRdData),        // to ExecuteStage: CSR read data
    .oCsrAddrValid (wCsrAddrValid),     // to ExecuteStage: CSR address legal
    .oMstatus      (wCsrMstatus),       // to IRQ controller/debug: mstatus
    .oMie          (wCsrMie),           // to IRQ controller/debug: mie
    .oMtvec        (wCsrMtvec),         // to TrapController/debug: trap vector
    .oMepc         (wCsrMepc),          // to ExecuteStage/debug: exception return PC
    .oMcause       (wCsrMcause),        // to debug: last trap cause
    .oMtval        (wCsrMtval),         // to debug: last trap value
    .oMipSw        (wCsrMipSw)          // to MachineInterruptController: software IRQ bit
  );

  MachineInterruptController uMachineInterruptController (
    .iSoftwareIrq      (iSoftwareIrq),      // from SocTop/PLIC path: software IRQ input
    .iTimerIrq         (iTimerIrq),         // from SocTop timer: timer IRQ input
    .iExternalIrq      (iExternalIrq),      // from SocTop PLIC: external IRQ input
    .iMstatus          (wCsrMstatus),       // from CsrFile: global interrupt enable
    .iMie              (wCsrMie),           // from CsrFile: per-source interrupt enables
    .iMipSw            (wCsrMipSw),         // from CsrFile: software pending bit
    .oMip              (wMip),              // to CsrFile: full mip pending bits
    .oInterruptPending (wInterruptPending), // to TrapController: interrupt should trap
    .oInterruptCause   (wInterruptCause)    // to TrapController: selected interrupt cause
  );

  TrapController uTrapController (
    .iInterruptPending    (wInterruptPending),    // from IRQ controller: interrupt pending and enabled
    .iInterruptCause      (wInterruptCause),      // from IRQ controller: interrupt cause code
    .iMtvec               (wCsrMtvec),            // from CsrFile: trap vector target
    .iBusWaitStall        (wBusWaitStall),        // from PipelineControl: hold traps during bus wait
    .iExRedirectPending   (wExRedirectPending),   // from PipelineControl: redirect already pending
    .iMemTrapEn           (wMemTrapEn),           // from MemoryStage: load/store access fault
    .iMemTrapCause        (wMemTrapCause),        // from MemoryStage: memory trap cause
    .iMemTrapTval         (wMemTrapTval),         // from MemoryStage: bad memory address
    .iMemTrapPc           (wMemTrapPc),           // from MemoryStage: trapped instruction PC
    .iExTrapEn            (wExTrapEn),            // from ExecuteStage: execute exception
    .iExTrapCause         (wExTrapCause),         // from ExecuteStage: execute trap cause
    .iExTrapTval          (wExTrapTval),          // from ExecuteStage: execute trap value
    .iExTrapPc            (rIdEx.pc),             // from ID/EX: EX instruction PC
    .iExPcRedirectEn      (wExPcRedirectEn),      // from ExecuteStage: EX PC redirect request
    .iExPcRedirectTarget  (wExPcRedirectTarget),  // from ExecuteStage: EX redirect target
    .iFetchPc             (oDbgPc),               // from FetchStage/debug: current fetch PC for IRQ mepc
    .oIrqTrapEn           (wIrqTrapEn),           // internal/debug: interrupt trap accepted
    .oTrapEn              (wTrapEn),              // to CsrFile/PipelineControl: take trap
    .oTrapIsInterrupt     (wTrapIsInterrupt),     // to CsrFile: encode interrupt bit
    .oTrapCause           (wTrapCause),           // to CsrFile: mcause value
    .oTrapPc              (wTrapPc),              // to CsrFile: mepc value
    .oTrapTval            (wTrapTval),            // to CsrFile: mtval value
    .oTrapRedirectEn      (wTrapRedirectEn),      // to PipelineControl: redirect to mtvec
    .oTrapRedirectTarget  (wTrapRedirectTarget),  // to PipelineControl: trap vector target
    .oExOnlyPcRedirectEn  (wExOnlyPcRedirectEn),  // to PipelineControl: EX redirect without trap
    .oExOnlyPcRedirectTarget(wExOnlyPcRedirectTarget) // to PipelineControl: EX-only target
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
    .iExMemPacket  (rExMem),          // from EX/MEM register: memory-stage packet
    .iDBusReady    (iDBusReady),      // from SocTop DBus: data response ready
    .iDBusRData    (iDBusRData),      // from SocTop DBus: load read data
    .iDBusError    (iDBusError),      // from SocTop DBus: load/store bus error
    .oDBusValid    (oDBusValid),      // to SocTop DBus: data request valid
    .oDBusWrite    (oDBusWrite),      // to SocTop DBus: 1=store, 0=load
    .oDBusAddr     (oDBusAddr),       // to SocTop DBus: load/store address
    .oDBusSize     (oDBusSize),       // to SocTop DBus: byte/half/word size
    .oDBusWData    (oDBusWData),      // to SocTop DBus: store data
    .oDataWaitStall(wDataWaitStall),  // to PipelineControl: memory waits for DBus
    .oMemTrapEn    (wMemTrapEn),      // to TrapController: memory access fault
    .oMemTrapCause (wMemTrapCause),   // to TrapController: load/store fault cause
    .oMemTrapTval  (wMemTrapTval),    // to TrapController: faulting address
    .oMemTrapPc    (wMemTrapPc),      // to TrapController: faulting instruction PC
    .oMemWbPacket  (wMemWbPacket)     // to MEM/WB register: writeback packet
  );

  WritebackStage uWritebackStage (
    .iMemWbPacket (rMemWb),        // from MEM/WB register: final WB packet
    .iBusWaitStall(wBusWaitStall), // from PipelineControl: suppress retire while bus holds
    .oRegWriteEn  (wWbRegWriteEn), // to DecodeStage/regfile: write enable
    .oRdAddr      (wWbRdAddr),     // to DecodeStage/regfile: destination rd
    .oRdWrData    (wWbRdWrData),   // to DecodeStage/regfile: writeback data
    .oRetireValid (wWbRetireValid) // to debug/perf: instruction retired
  );

  PipelineControl uPipelineControl (
    .iClk                (iClk),                   // core clock
    .iRstn               (iRstn),                  // active-low core reset
    .iFetchWaitStall     (wFetchWaitStall),        // from FetchStage: IBus wait
    .iDataWaitStall      (wDataWaitStall),         // from MemoryStage: DBus wait
    .iLoadUseStall       (wLoadUseStall),          // from HazardUnit: load-use bubble
    .iTrapRedirectEn     (wTrapRedirectEn),        // from TrapController: trap redirect request
    .iTrapRedirectTarget (wTrapRedirectTarget),    // from TrapController: trap target PC
    .iExPcRedirectEn     (wExOnlyPcRedirectEn),    // from TrapController: EX redirect request
    .iExPcRedirectTarget (wExOnlyPcRedirectTarget), // from TrapController: EX redirect target
    .iIdJalCandidate     (wIdJalCandidate),        // from DecodeStage: JAL redirect candidate
    .iIdJalX0Candidate   (wIdJalX0Candidate),      // from DecodeStage: fast JAL x0 candidate
    .iIdBranchCandidate  (wIdBranchCandidate),     // from DecodeStage: branch redirect candidate
    .iIdJalTarget        (wIdJalTarget),           // from DecodeStage: JAL target PC
    .iIdBranchTarget     (wIdBranchTarget),        // from DecodeStage: branch correct PC

    .oBusWaitStall       (wBusWaitStall),          // to Trap/WB/pipeline regs: bus wait hold
    .oPipelineStall      (wPipelineStall),         // to BTB feedback: block update on stall

    .oPcWriteEn          (wPcWriteEn),             // to FetchStage: PC register write enable
    .oPcTargetEn         (wPcTargetEn),            // to FetchStage: redirect PC now
    .oPcTarget           (wPcTarget),              // to FetchStage: selected redirect target
    .oIfIdFlush          (wIfIdFlush),             // to IF/ID register: inject NOP/invalid
    .oIfIdWriteEn        (wIfIdWriteEn),           // to IF/ID register: accept fetch packet
    .oIdExFlush          (wIdExFlush),             // to ID/EX register: inject bubble
    .oIdExHold           (wIdExHold),              // to ID/EX register: hold during bus wait
    .oExMemHold          (wExMemHold),             // to EX/MEM register: hold during bus wait
    .oMemWbHold          (wMemWbHold),             // to MEM/WB register: hold during bus wait
    .oExRedirectPending  (wExRedirectPending),     // to Execute/Trap/EXMEM gating: redirect pending
    .oIdJalRedirectEn    (wIdJalRedirectEn),       // to DecodeStage/debug: ID JAL accepted
    .oIdJalX0RedirectEn  (wIdJalX0RedirectEn),     // to debug/redirect mux: fast JAL x0 accepted
    .oIdBranchRedirectEn (wIdBranchRedirectEn)     // to DecodeStage/debug: ID branch accepted
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
