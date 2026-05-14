`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: InstrRom_hazard
Role: RTL module implementing a mixed data/control hazard instruction ROM
Summary:
  - Exercises forwarding, load-use stalls, and mixed store/load interactions
  - Includes not-taken branches, taken branches, back-to-back branch/jump control flow
  - Uses FENCE as a no-side-effect instruction near completion
StateDescription:
  - ROM only: no internal state
[MODULE_INFO_END]
*/
module InstrRom_hazard #(
  parameter integer P_ADDR_WIDTH = 8,
  parameter integer P_DATA_WIDTH = 32
) (
  input  logic [31:0]             iAddr,
  output logic [P_DATA_WIDTH-1:0] oInstr
);

  localparam integer LP_DEPTH = 38;
  localparam integer LP_WORD_ADDR_WIDTH = (LP_DEPTH <= 1) ? 1 : $clog2(LP_DEPTH);

  wire [31:0] wMem[0:LP_DEPTH-1];
  wire [LP_WORD_ADDR_WIDTH-1:0] wWordAddr;
  wire [31:0]                  wWordAddrExt;
  wire                         wAddrInRange;

  assign wWordAddr    = iAddr[LP_WORD_ADDR_WIDTH+1:2];
  assign wWordAddrExt = {{(32-LP_WORD_ADDR_WIDTH){1'b0}}, wWordAddr};
  assign wAddrInRange = (iAddr[31:LP_WORD_ADDR_WIDTH+2] == '0) && (wWordAddrExt < LP_DEPTH);

  assign wMem[0]  = 32'h04000A13; // addi x20, x0, 64
  assign wMem[1]  = 32'h04400A93; // addi x21, x0, 68
  assign wMem[2]  = 32'h03700913; // addi x18, x0, 55
  assign wMem[3]  = 32'h00500093; // addi x1, x0, 5
  assign wMem[4]  = 32'h00700113; // addi x2, x0, 7
  assign wMem[5]  = 32'h002081B3; // add x3, x1, x2
  assign wMem[6]  = 32'h00118233; // add x4, x3, x1
  assign wMem[7]  = 32'h00100F13; // addi x30, x0, 1
  assign wMem[8]  = 32'h402202B3; // sub x5, x4, x2
  assign wMem[9]  = 32'h00328333; // add x6, x5, x3
  assign wMem[10] = 32'h006A2023; // sw x6, 0(x20)
  assign wMem[11] = 32'h000A2383; // lw x7, 0(x20)
  assign wMem[12] = 32'h00138413; // addi x8, x7, 1
  assign wMem[13] = 32'h006404B3; // add x9, x8, x6
  assign wMem[14] = 32'h008A0B13; // addi x22, x20, 8
  assign wMem[15] = 32'h009B2023; // sw x9, 0(x22)
  assign wMem[16] = 32'h00100513; // addi x10, x0, 1
  assign wMem[17] = 32'h00050463; // beq x10, x0, +8 (not taken, branch operand forwarding)
  assign wMem[18] = 32'h00B00593; // addi x11, x0, 11
  assign wMem[19] = 32'h000A2603; // lw x12, 0(x20)
  assign wMem[20] = 32'h00660463; // beq x12, x6, +8 (load->branch mixed, taken)
  assign wMem[21] = 32'h06300693; // addi x13, x0, 99 (must be flushed)
  assign wMem[22] = 32'h00D00693; // addi x13, x0, 13
  assign wMem[23] = 32'h00100713; // addi x14, x0, 1
  assign wMem[24] = 32'h00070463; // beq x14, x0, +8 (not taken)
  assign wMem[25] = 32'h008007EF; // jal x15, +8
  assign wMem[26] = 32'h06300813; // addi x16, x0, 99 (must be flushed)
  assign wMem[27] = 32'h01000813; // addi x16, x0, 16
  assign wMem[28] = 32'h07C00893; // addi x17, x0, 124
  assign wMem[29] = 32'h000889E7; // jalr x19, x17, 0
  assign wMem[30] = 32'h06F00B93; // addi x23, x0, 111 (must be flushed)
  assign wMem[31] = 32'h01700B93; // addi x23, x0, 23
  assign wMem[32] = 32'h00100C13; // addi x24, x0, 1
  assign wMem[33] = 32'h000C1463; // bne x24, x0, +8 (taken, branch operand forwarding)
  assign wMem[34] = 32'h00800CEF; // jal x25, +8 (must be flushed by taken branch)
  assign wMem[35] = 32'h01900C93; // addi x25, x0, 25
  assign wMem[36] = 32'h0000000F; // fence as legal no-op
  assign wMem[37] = 32'h00100F93; // addi x31, x0, 1

  assign oInstr = wAddrInRange ? wMem[wWordAddr] : 32'h00000013;

endmodule
