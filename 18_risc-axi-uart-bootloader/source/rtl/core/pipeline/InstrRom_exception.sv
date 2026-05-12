`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: InstrRom_exception
Role: Instruction ROM for CSR and exception bring-up
Summary:
  - Exercises ECALL, EBREAK, illegal instruction, misaligned load, MRET, and CSR ops
  - Places a small trap handler at mtvec=0x80
StateDescription:
  - Combinational ROM indexed by word-aligned PC
[MODULE_INFO_END]
*/
module InstrRom_exception #(
  parameter integer P_ADDR_WIDTH = 8,
  parameter integer P_DATA_WIDTH = 32
) (
  input  logic [31:0]             iAddr,
  output logic [P_DATA_WIDTH-1:0] oInstr
);

  localparam integer LP_DEPTH = 38;
  localparam integer LP_WORD_ADDR_WIDTH = (P_ADDR_WIDTH < 7) ? P_ADDR_WIDTH : 7;

  wire [31:0] wMem[0:LP_DEPTH-1];
  wire [LP_WORD_ADDR_WIDTH-1:0] wWordAddr;
  wire [31:0]                  wWordAddrExt;
  wire                         wAddrInRange;

  assign wWordAddr    = iAddr[LP_WORD_ADDR_WIDTH+1:2];
  assign wWordAddrExt = {{(32-LP_WORD_ADDR_WIDTH){1'b0}}, wWordAddr};
  assign wAddrInRange = (iAddr[31:LP_WORD_ADDR_WIDTH+2] == '0) && (wWordAddrExt < LP_DEPTH);

  assign wMem[0]  = 32'h08000093; // addi  x1, x0, 128
  assign wMem[1]  = 32'h30509073; // csrrw x0, mtvec, x1
  assign wMem[2]  = 32'h00000073; // ecall
  assign wMem[3]  = 32'h00500293; // addi  x5, x0, 5
  assign wMem[4]  = 32'h00100073; // ebreak
  assign wMem[5]  = 32'h00600313; // addi  x6, x0, 6
  assign wMem[6]  = 32'hFFFFFFFF; // illegal instruction
  assign wMem[7]  = 32'h00700393; // addi  x7, x0, 7
  assign wMem[8]  = 32'h04000693; // addi  x13, x0, 64
  assign wMem[9]  = 32'h00169703; // lh    x14, 1(x13), misaligned
  assign wMem[10] = 32'h00F00793; // addi  x15, x0, 15
  assign wMem[11] = 32'h00100413; // addi  x8, x0, 1
  assign wMem[12] = 32'h300414F3; // csrrw x9, mstatus, x8
  assign wMem[13] = 32'h30002573; // csrrs x10, mstatus, x0
  assign wMem[14] = 32'h30016073; // csrsi x0, mstatus, 2
  assign wMem[15] = 32'h300435F3; // csrrc x11, mstatus, x8
  assign wMem[16] = 32'h30002673; // csrrs x12, mstatus, x0
  assign wMem[17] = 32'h00100F93; // addi  x31, x0, 1
  assign wMem[18] = 32'h00000063; // beq   x0, x0, 0
  assign wMem[19] = 32'h00000013;
  assign wMem[20] = 32'h00000013;
  assign wMem[21] = 32'h00000013;
  assign wMem[22] = 32'h00000013;
  assign wMem[23] = 32'h00000013;
  assign wMem[24] = 32'h00000013;
  assign wMem[25] = 32'h00000013;
  assign wMem[26] = 32'h00000013;
  assign wMem[27] = 32'h00000013;
  assign wMem[28] = 32'h00000013;
  assign wMem[29] = 32'h00000013;
  assign wMem[30] = 32'h00000013;
  assign wMem[31] = 32'h00000013;
  assign wMem[32] = 32'h34202173; // csrrs x2, mcause, x0
  assign wMem[33] = 32'h341021F3; // csrrs x3, mepc, x0
  assign wMem[34] = 32'h00418193; // addi  x3, x3, 4
  assign wMem[35] = 32'h34119073; // csrrw x0, mepc, x3
  assign wMem[36] = 32'h34302273; // csrrs x4, mtval, x0
  assign wMem[37] = 32'h30200073; // mret

  assign oInstr = wAddrInRange ? wMem[wWordAddr] : 32'h00000013;

endmodule
