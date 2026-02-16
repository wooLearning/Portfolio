module ShiftRows(
  input[127:0] iText,
  output[127:0] oShiftRowsOut
);
/*
  // no shift 0, 4, 8, 12
  assign oShiftRowsOut[0:7] = iText[0:7];
  assign oShiftRowsOut[32:39] = iText[32:39];
  assign oShiftRowsOut[64:71] = iText[64:71];
  assign oShiftRowsOut[96:103] = iText[96:103];
	
  // shift 1 (1,5,9,13)
  assign oShiftRowsOut[:8] = iText[47:40];
  assign oShiftRowsOut[47:40] = iText[79:72];
  assign oShiftRowsOut[79:72] = iText[111:104];
  assign oShiftRowsOut[111:104] = iText[15:8];
	
  // shift 2 (2,6,10,14)
  assign oShiftRowsOut[23:16] = iText[87:80];
  assign oShiftRowsOut[55:48] = iText[119:112];
  assign oShiftRowsOut[87:80] = iText[23:16];
  assign oShiftRowsOut[119:112] = iText[55:48];
	
  // shift 3 (3,7,11,15)
  assign oShiftRowsOut[31:24] = iText[127:120];
  assign oShiftRowsOut[63:56] = iText[31:24];
  assign oShiftRowsOut[95:88] = iText[63:56];
  assign oShiftRowsOut[127:120] = iText[95:88];
*/

//shift3
assign oShiftRowsOut[0+:8] = iText[32+:8];
assign oShiftRowsOut[32+:8] = iText[64+:8];
assign oShiftRowsOut[64+:8] = iText[96+:8];
assign oShiftRowsOut[96+:8] = iText[0+:8];

//shift 2
assign oShiftRowsOut[8+:8] = iText[72+:8];
assign oShiftRowsOut[40+:8] = iText[104+:8];
assign oShiftRowsOut[72+:8] = iText[8+:8];
assign oShiftRowsOut[104+:8] = iText[40+:8];

//shift 1
assign oShiftRowsOut[16+:8] = iText[112+:8];
assign oShiftRowsOut[48+:8] = iText[16+:8];
assign oShiftRowsOut[80+:8] = iText[48+:8];
assign oShiftRowsOut[112+:8] = iText[80+:8];

//no shift
assign oShiftRowsOut[24+:8] = iText[24+:8];
assign oShiftRowsOut[56+:8] = iText[56+:8];
assign oShiftRowsOut[88+:8] = iText[88+:8];
assign oShiftRowsOut[120+:8] = iText[120+:8];

endmodule
