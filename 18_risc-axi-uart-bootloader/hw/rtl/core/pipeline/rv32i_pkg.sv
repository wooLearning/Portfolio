`timescale 1ns / 1ps

// Shared enums and opcode constants for the RV32I subset in this project.
package rv32i_pkg;
  // ALU operation select used by arithmetic, load/store address calc, and shifts.
  typedef enum logic [3:0] {
    ALU_ADD,
    ALU_SUB,
    ALU_SLL,
    ALU_SLT,
    ALU_SLTU,
    ALU_XOR,
    ALU_SRL,
    ALU_SRA,
    ALU_OR,
    ALU_AND
  } alu_op_e;

  typedef enum logic [2:0] {
    WB_ALU,
    WB_MEM,
    WB_PC4,
    WB_IMM,
    WB_PCIMM,
    WB_CSR
  } wb_sel_e;

  typedef enum logic [2:0] {
    LOAD_NONE,
    LOAD_LB,
    LOAD_LH,
    LOAD_LW,
    LOAD_LBU,
    LOAD_LHU
  } load_type_e;

  typedef enum logic [1:0] {
    STORE_NONE,
    STORE_SB,
    STORE_SH,
    STORE_SW
  } store_type_e;

  typedef enum logic [2:0] {
    IMM_NONE,
    IMM_I,
    IMM_S,
    IMM_B,
    IMM_J,
    IMM_U
  } imm_sel_e;

  typedef enum logic [2:0] {
    BR_NONE,
    BR_BEQ,
    BR_BNE,
    BR_BLT,
    BR_BGE,
    BR_BLTU,
    BR_BGEU
  } branch_e;

  typedef enum logic [1:0] {
    JUMP_NONE,
    JUMP_JAL,
    JUMP_JALR
  } jump_e;

  typedef enum logic [2:0] {
    CSR_NONE,
    CSR_RW,
    CSR_RS,
    CSR_RC,
    CSR_RWI,
    CSR_RSI,
    CSR_RCI
  } csr_op_e;

  typedef enum logic [1:0] {
    SYS_NONE,
    SYS_ECALL,
    SYS_EBREAK,
    SYS_MRET
  } sys_op_e;

  typedef enum logic [3:0] {
    EXC_NONE                  = 4'd15,
    EXC_INSTR_ADDR_MISALIGNED = 4'd0,
    EXC_INSTR_ACCESS_FAULT    = 4'd1,
    EXC_ILLEGAL_INSTR         = 4'd2,
    EXC_BREAKPOINT            = 4'd3,
    EXC_LOAD_ADDR_MISALIGNED  = 4'd4,
    EXC_LOAD_ACCESS_FAULT     = 4'd5,
    EXC_STORE_ADDR_MISALIGNED = 4'd6,
    EXC_STORE_ACCESS_FAULT    = 4'd7,
    EXC_ECALL_MMODE           = 4'd11
  } exc_cause_e;

  typedef enum logic [3:0] {
    IRQ_SOFTWARE = 4'd3,
    IRQ_TIMER    = 4'd7,
    IRQ_EXTERNAL = 4'd11
  } irq_cause_e;

  // Opcode constants currently decoded by this core.
  // Note:
  // - These are opcode-group names, not full instruction-format categories.
  // - LP_OPCODE_OPIMM refers to OP-IMM (0010011) only.
  // - Other instructions that also use an I-type bit layout, such as LOAD,
  //   are decoded with their own opcode constants below.
  localparam logic [6:0] LP_OPCODE_RTYPE  = 7'b0110011;//r type
  localparam logic [6:0] LP_OPCODE_OPIMM  = 7'b0010011;//i type
  localparam logic [6:0] LP_OPCODE_AUIPC  = 7'b0010111;//u type
  localparam logic [6:0] LP_OPCODE_LOAD   = 7'b0000011;//i type
  localparam logic [6:0] LP_OPCODE_JALR   = 7'b1100111;//i type
  localparam logic [6:0] LP_OPCODE_STORE  = 7'b0100011;//s type
  localparam logic [6:0] LP_OPCODE_BRANCH = 7'b1100011;//b type
  localparam logic [6:0] LP_OPCODE_JAL    = 7'b1101111;//j type
  localparam logic [6:0] LP_OPCODE_LUI    = 7'b0110111;//u type
  localparam logic [6:0] LP_OPCODE_FENCE  = 7'b0001111;
  localparam logic [6:0] LP_OPCODE_SYSTEM = 7'b1110011;

  localparam logic [11:0] LP_CSR_MSTATUS = 12'h300;
  localparam logic [11:0] LP_CSR_MIE     = 12'h304;
  localparam logic [11:0] LP_CSR_MTVEC   = 12'h305;
  localparam logic [11:0] LP_CSR_MIP     = 12'h344;
  localparam logic [11:0] LP_CSR_MEPC    = 12'h341;
  localparam logic [11:0] LP_CSR_MCAUSE  = 12'h342;
  localparam logic [11:0] LP_CSR_MTVAL   = 12'h343;

  localparam integer LP_MSTATUS_MIE_BIT  = 3;
  localparam integer LP_MSTATUS_MPIE_BIT = 7;
  localparam integer LP_IRQ_MSIP_BIT     = 3;
  localparam integer LP_IRQ_MTIP_BIT     = 7;
  localparam integer LP_IRQ_MEIP_BIT     = 11;

  typedef struct packed {
    logic        valid;
    logic        instr_error;
    logic        predicted_taken;
    logic [31:0] pc;
    logic [31:0] pc_plus4;
    logic [31:0] predicted_target;
    logic [31:0] instr;
  } if_id_packet_t;

  typedef struct packed {
    logic        valid;
    logic        instr_error;
    logic        illegal;
    logic        csr_addr_valid;
    logic        predicted_taken;
    logic [31:0] instr;
    logic [31:0] pc;
    logic [31:0] pc_plus4;
    logic [31:0] predicted_target;
    logic [31:0] imm;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic        reg_write;
    logic        mem_write;
    logic        alu_src;
    logic        uses_rs1;
    logic        uses_rs2;
    logic        early_jal;
    logic        early_branch;
    wb_sel_e     wb_sel;
    alu_op_e     alu_op;
    load_type_e  load_type;
    store_type_e store_type;
    branch_e     branch_type;
    jump_e       jump_type;
    csr_op_e     csr_op;
    sys_op_e     sys_op;
  } id_ex_packet_t;

  typedef struct packed {
    logic        valid;
    logic [31:0] pc;
    logic        illegal;
    logic        reg_write;
    logic        mem_write;
    logic        forward_en;
    logic [4:0]  rd_addr;
    logic [31:0] alu_result;
    logic [31:0] store_data;
    logic [31:0] wb_data_non_mem;
    wb_sel_e     wb_sel;
    load_type_e  load_type;
    store_type_e store_type;
  } ex_mem_packet_t;

  typedef struct packed {
    logic        valid;
    logic        illegal;
    logic        reg_write;
    logic        forward_en;
    logic [4:0]  rd_addr;
    logic [31:0] wr_data;
  } mem_wb_packet_t;
endpackage
