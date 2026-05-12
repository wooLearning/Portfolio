`timescale 1ns / 1ps

// Generated from src/timing_programs/Full Coverage.mem.
module InstrRom_timing_full #(
  parameter integer P_ADDR_WIDTH = 8,
  parameter integer P_DATA_WIDTH = 32
) (
  input  logic [31:0]             iAddr,
  output logic [P_DATA_WIDTH-1:0] oInstr
);

  localparam integer LP_DEPTH = 91;
  localparam integer LP_WORD_ADDR_WIDTH = 7;

  wire [31:0] wMem[0:LP_DEPTH-1];
  wire [LP_WORD_ADDR_WIDTH-1:0] wWordAddr;
  wire [31:0] wWordAddrExt;
  wire wAddrInRange;

  assign wWordAddr = iAddr[LP_WORD_ADDR_WIDTH+1:2];
  assign wWordAddrExt = {{(32-LP_WORD_ADDR_WIDTH){1'b0}}, wWordAddr};
  assign wAddrInRange = (iAddr[31:LP_WORD_ADDR_WIDTH+2] == '0) && (wWordAddrExt < LP_DEPTH);

  assign wMem[0] = 32'h00f00093;
  assign wMem[1] = 32'h00300113;
  assign wMem[2] = 32'hff000193;
  assign wMem[3] = 32'h08000b93;
  assign wMem[4] = 32'h09000c13;
  assign wMem[5] = 32'h00208233;
  assign wMem[6] = 32'h402082b3;
  assign wMem[7] = 32'h00209333;
  assign wMem[8] = 32'h0011a3b3;
  assign wMem[9] = 32'h0011b433;
  assign wMem[10] = 32'h0020c4b3;
  assign wMem[11] = 32'h0020d533;
  assign wMem[12] = 32'h4021d5b3;
  assign wMem[13] = 32'h0020e633;
  assign wMem[14] = 32'h0020f6b3;
  assign wMem[15] = 32'h00508713;
  assign wMem[16] = 32'h0001a793;
  assign wMem[17] = 32'h0011b813;
  assign wMem[18] = 32'h0030c893;
  assign wMem[19] = 32'h0020e913;
  assign wMem[20] = 32'h0070f993;
  assign wMem[21] = 32'h00411a13;
  assign wMem[22] = 32'h0010da93;
  assign wMem[23] = 32'h4021db13;
  assign wMem[24] = 32'h12345cb7;
  assign wMem[25] = 32'h00001d17;
  assign wMem[26] = 32'h00eba023;
  assign wMem[27] = 32'h000bad83;
  assign wMem[28] = 32'h002d8e33;
  assign wMem[29] = 32'h08000213;
  assign wMem[30] = 32'h004b8223;
  assign wMem[31] = 32'h07f00293;
  assign wMem[32] = 32'h005b82a3;
  assign wMem[33] = 32'hff200313;
  assign wMem[34] = 32'h00831313;
  assign wMem[35] = 32'h03430313;
  assign wMem[36] = 32'h006b9323;
  assign wMem[37] = 32'h004b8e83;
  assign wMem[38] = 32'h004bcf03;
  assign wMem[39] = 32'h006b9f83;
  assign wMem[40] = 32'h006bd203;
  assign wMem[41] = 32'h01eec2b3;
  assign wMem[42] = 32'h004f8333;
  assign wMem[43] = 32'h00000393;
  assign wMem[44] = 32'h00000413;
  assign wMem[45] = 32'h00208463;
  assign wMem[46] = 32'h00138393;
  assign wMem[47] = 32'h00108463;
  assign wMem[48] = 32'h06340413;
  assign wMem[49] = 32'h00140413;
  assign wMem[50] = 32'h00109463;
  assign wMem[51] = 32'h00138393;
  assign wMem[52] = 32'h00209463;
  assign wMem[53] = 32'h06340413;
  assign wMem[54] = 32'h00140413;
  assign wMem[55] = 32'h0020c463;
  assign wMem[56] = 32'h00138393;
  assign wMem[57] = 32'h0011c463;
  assign wMem[58] = 32'h06340413;
  assign wMem[59] = 32'h00140413;
  assign wMem[60] = 32'h00115463;
  assign wMem[61] = 32'h00138393;
  assign wMem[62] = 32'h0020d463;
  assign wMem[63] = 32'h06340413;
  assign wMem[64] = 32'h00140413;
  assign wMem[65] = 32'h0020e463;
  assign wMem[66] = 32'h00138393;
  assign wMem[67] = 32'h00116463;
  assign wMem[68] = 32'h06340413;
  assign wMem[69] = 32'h00140413;
  assign wMem[70] = 32'h00117463;
  assign wMem[71] = 32'h00138393;
  assign wMem[72] = 32'h0020f463;
  assign wMem[73] = 32'h06340413;
  assign wMem[74] = 32'h00140413;
  assign wMem[75] = 32'h00400493;
  assign wMem[76] = 32'h00000513;
  assign wMem[77] = 32'hfff48493;
  assign wMem[78] = 32'h00950533;
  assign wMem[79] = 32'hfe049ce3;
  assign wMem[80] = 32'h008005ef;
  assign wMem[81] = 32'h06f00613;
  assign wMem[82] = 32'h00000617;
  assign wMem[83] = 32'h01060613;
  assign wMem[84] = 32'h000606e7;
  assign wMem[85] = 32'h0de00713;
  assign wMem[86] = 32'h03700793;
  assign wMem[87] = 32'h0000000f;
  assign wMem[88] = 32'h001c8833;
  assign wMem[89] = 32'h002d08b3;
  assign wMem[90] = 32'h0000006f;

  assign oInstr = wAddrInRange ? wMem[wWordAddr] : 32'h00000013;

endmodule
