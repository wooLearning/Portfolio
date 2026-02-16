module parsing_top_layer00 (
	input clk,
	input rstn,
	input iStart,
	input i_fromYolo,

	input [127:0] iData0,
	input [127:0] iData1,
	input [127:0] iData2,
	input [127:0] iData3,
	input [127:0] iData4,
	input [127:0] iData5,
	input [127:0] iData6,
	input [127:0] iData7,
	input [127:0] iData8,
	input [127:0] iData9,
	input [127:0] iData10,
	input [127:0] iData11,
	input [127:0] iData12,
	input [127:0] iData13,
	input [127:0] iData14,
	input [127:0] iData15,

	/*for bram read siganl*/
	output [8:0] oAddr0,
	output [8:0] oAddr1,
	output [8:0] oAddr2,
	output [8:0] oAddr3,
	output [8:0] oAddr4,
	output [8:0] oAddr5,
	output [8:0] oAddr6,
	output [8:0] oAddr7,
	output [8:0] oAddr8,
	output [8:0] oAddr9,
	output [8:0] oAddr10,
	output [8:0] oAddr11,
	output [8:0] oAddr12,
	output [8:0] oAddr13,
	output [8:0] oAddr14,
	output [8:0] oAddr15,

	output [15:0] oCs,

	/* AFTER ZERO PADDING */
	output [127:0] oDin0,
	output [127:0] oDin1,
	output [127:0] oDin2,

	output oColEnd,
	output oMac_vld// mac에 이 신호 전달에서 mul 시작
);
	



//wire [7:0] w_oDin[0:15];

parsing_data_layer00 parsing_dut(
    .clk(clk),
    .rstn(rstn),
	.iStart(iStart),
	.i_fromYolo(i_fromYolo),
	
	.oCs(oCs), // chip enable

	.oAddr0(oAddr0),
	.oAddr1(oAddr1),
	.oAddr2(oAddr2),
	.oAddr3(oAddr3),
	.oAddr4(oAddr4),
	.oAddr5(oAddr5),
	.oAddr6(oAddr6),
	.oAddr7(oAddr7),
	.oAddr8(oAddr8),
	.oAddr9(oAddr9),
	.oAddr10(oAddr10),
	.oAddr11(oAddr11),
	.oAddr12(oAddr12),
	.oAddr13(oAddr13),
	.oAddr14(oAddr14),
	.oAddr15(oAddr15),

	.iData0(iData0), //from bram data
	.iData1(iData1),
	.iData2(iData2),
	.iData3(iData3),
	.iData4(iData4),
	.iData5(iData5),
	.iData6(iData6),
	.iData7(iData7),
	.iData8(iData8),
	.iData9(iData9),
	.iData10(iData10),
	.iData11(iData11),
	.iData12(iData12),
	.iData13(iData13),
	.iData14(iData14),
	.iData15(iData15),

	.oDin0_0(oDin0[0+:8]),
	.oDin0_1(oDin0[8+:8]),
	.oDin0_2(oDin0[16+:8]),
	.oDin0_3(oDin0[24+:8]),
	.oDin0_4(oDin0[32+:8]),
	.oDin0_5(oDin0[40+:8]),
	.oDin0_6(oDin0[48+:8]),
	.oDin0_7(oDin0[56+:8]),
	.oDin0_8(oDin0[64+:8]),
	.oDin0_9(oDin0[72+:8]),
	.oDin0_10(oDin0[80+:8]),
	.oDin0_11(oDin0[88+:8]),
	.oDin0_12(oDin0[96+:8]),
	.oDin0_13(oDin0[104+:8]),
	.oDin0_14(oDin0[112+:8]),
	.oDin0_15(oDin0[120+:8]),

	.oDin1_0(oDin1[0+:8]),
	.oDin1_1(oDin1[8+:8]),
	.oDin1_2(oDin1[16+:8]),
	.oDin1_3(oDin1[24+:8]),
	.oDin1_4(oDin1[32+:8]),
	.oDin1_5(oDin1[40+:8]),
	.oDin1_6(oDin1[48+:8]),
	.oDin1_7(oDin1[56+:8]),
	.oDin1_8(oDin1[64+:8]),
	.oDin1_9(oDin1[72+:8]),
	.oDin1_10(oDin1[80+:8]),
	.oDin1_11(oDin1[88+:8]),
	.oDin1_12(oDin1[96+:8]),
	.oDin1_13(oDin1[104+:8]),
	.oDin1_14(oDin1[112+:8]),
	.oDin1_15(oDin1[120+:8]),

	.oDin2_0(oDin2[0+:8]),
	.oDin2_1(oDin2[8+:8]),
	.oDin2_2(oDin2[16+:8]),
	.oDin2_3(oDin2[24+:8]),
	.oDin2_4(oDin2[32+:8]),
	.oDin2_5(oDin2[40+:8]),
	.oDin2_6(oDin2[48+:8]),
	.oDin2_7(oDin2[56+:8]),
	.oDin2_8(oDin2[64+:8]),
	.oDin2_9(oDin2[72+:8]),
	.oDin2_10(oDin2[80+:8]),
	.oDin2_11(oDin2[88+:8]),
	.oDin2_12(oDin2[96+:8]),
	.oDin2_13(oDin2[104+:8]),
	.oDin2_14(oDin2[112+:8]),
	.oDin2_15(oDin2[120+:8]),

	.oColEnd(oColEnd),
	.oMac_vld(oMac_vld)
);




endmodule