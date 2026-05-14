`timescale 1ns / 1ps

// Bubble-sort program relocated for SocTop SRAM at 0x2000_0000.
module InstrRom_soc_bubble #(
  parameter integer P_ADDR_WIDTH = 8,
  parameter integer P_DATA_WIDTH = 32
) (
  input  logic [31:0]             iAddr,
  output logic [P_DATA_WIDTH-1:0] oInstr
);

  localparam integer LP_DEPTH = 32;
  localparam integer LP_WORD_ADDR_WIDTH = 5;

  wire [31:0] wMem[0:LP_DEPTH-1];
  wire [LP_WORD_ADDR_WIDTH-1:0] wWordAddr;
  wire [31:0] wWordAddrExt;
  wire wAddrInRange;

  assign wWordAddr = iAddr[LP_WORD_ADDR_WIDTH+1:2];
  assign wWordAddrExt = {{(32-LP_WORD_ADDR_WIDTH){1'b0}}, wWordAddr};
  assign wAddrInRange = (iAddr[31:LP_WORD_ADDR_WIDTH+2] == '0) && (wWordAddrExt < LP_DEPTH);

  assign wMem[0]  = 32'h20000437; // lui  x8,  0x20000
  assign wMem[1]  = 32'h00400493; // addi x9,  x0, 4
  assign wMem[2]  = 32'h01040913; // addi x18, x8, 16
  assign wMem[3]  = 32'h00300293;
  assign wMem[4]  = 32'h00542023;
  assign wMem[5]  = 32'h00100293;
  assign wMem[6]  = 32'h00542223;
  assign wMem[7]  = 32'h00400293;
  assign wMem[8]  = 32'h00542423;
  assign wMem[9]  = 32'h00200293;
  assign wMem[10] = 32'h00542623;
  assign wMem[11] = 32'h00092023;
  assign wMem[12] = 32'h00000293;
  assign wMem[13] = 32'hfff48393;
  assign wMem[14] = 32'h0272de63;
  assign wMem[15] = 32'h00000313;
  assign wMem[16] = 32'h40538e33;
  assign wMem[17] = 32'h03c35463;
  assign wMem[18] = 32'h00231e93;
  assign wMem[19] = 32'h01d40eb3;
  assign wMem[20] = 32'h000eaf03;
  assign wMem[21] = 32'h004eaf83;
  assign wMem[22] = 32'h01ff5663;
  assign wMem[23] = 32'h01fea023;
  assign wMem[24] = 32'h01eea223;
  assign wMem[25] = 32'h00130313;
  assign wMem[26] = 32'hfddff06f;
  assign wMem[27] = 32'h00128293;
  assign wMem[28] = 32'hfc5ff06f;
  assign wMem[29] = 32'h00100293;
  assign wMem[30] = 32'h00592023;
  assign wMem[31] = 32'h0000006f;

  assign oInstr = wAddrInRange ? wMem[wWordAddr] : 32'h00000013;

endmodule
