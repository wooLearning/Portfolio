module layer00 (
	input clk, 
	input rstn, 
	input iStart,
	input i_fromYolo,

	input [1:0] i_layerInfo,

	output[31:0] oLayer_result,

	output oColEnd,
	
	output oLayer_vld ,

	/*bram communicate signal*/
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

	output [15:0] oCs

);

/*layer00*/
//reg vld_i_d1, vld_i_d2, vld_i_d3, vld_i_d4;

wire 		[127:0]	oDin0;
wire 		[127:0]	oDin1;
wire 		[127:0]	oDin2;
wire 		[19:0] 	oOut0[0:11];
wire 		[19:0] 	oOut1[0:11];
wire 		[19:0] 	oOut2[0:11];
wire 		[19:0] 	oOut3[0:11];

wire 		[71:0] 	iWeight[0:11];				// here

wire 		[63:0]  w_bias;
wire 		[15:0] 	iBias0 = w_bias[0+:16];
wire 		[15:0] 	iBias1 = w_bias[16+:16];
wire 		[15:0] 	iBias2 = w_bias[32+:16];
wire 		[15:0] 	iBias3 = w_bias[48+:16];

wire 		[21:0] 	w_after_add0[0:3];
wire 		[21:0] 	w_after_add1[0:3];
wire 		[21:0] 	w_after_add2[0:3];
wire 		[21:0] 	w_after_add3[0:3];

wire 		[7:0] 	oLayer0_0; 
wire 		[7:0] 	oLayer0_1; 
wire 		[7:0] 	oLayer0_2; 
wire 		[7:0] 	oLayer0_3; 

wire 				w_parsing00_vld;
wire 				w_add_vld0, w_add_vld1, w_add_vld2, w_add_vld3;
wire 				wMac_vld;

assign wMac_vld			= w_parsing00_vld && o_ready;
assign oLayer_result 	= {oLayer0_3,oLayer0_2,oLayer0_1,oLayer0_0};
assign oLayer_vld 		=  w_add_vld0;


parsing_top_layer00 parsing(
	.clk(clk),
	.rstn(rstn),
	.iStart(iStart),
	.i_fromYolo(i_fromYolo),

	.iData0(iData0),
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

	/*for bram read siganl*/
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

	.oCs(oCs),

	/* AFTER ZERO PADDING */
	.oDin0(oDin0),//r
	.oDin1(oDin1),//g
	.oDin2(oDin2),//b

	.oColEnd(oColEnd),
	.oMac_vld(w_parsing00_vld)
);


weight_ctrl#(.KERNEL_WIDTH(72)) 
weight_ctrl(
	.clk(clk),
	.rstn(rstn),
	.i_load_en(w_parsing00_vld),

	.o_ready(o_ready),

	// each kernel has 9 weights (9*8=72 bits)
   	.o_kernel0(iWeight[0]), // main outputs
	.o_kernel1(iWeight[1]),
	.o_kernel2(iWeight[2]),
	.o_kernel3(iWeight[3]),
	.o_kernel4(iWeight[4]),
	.o_kernel5(iWeight[5]),
	.o_kernel6(iWeight[6]),
	.o_kernel7(iWeight[7]),
	.o_kernel8(iWeight[8]),
	.o_kernel9(iWeight[9]),
	.o_kernel10(iWeight[10]),
	.o_kernel11(iWeight[11])
);

wire w_bank_vld;
wire w_bank_vld_prev;
mac_bank mac_bank(
	.clk(clk), 
    .rstn(rstn), 
    .vld_i(wMac_vld), 

	.iDin0(oDin0),//r
	.iDin1(oDin1),//g
	.iDin2(oDin2),//b

	.iDin3(oDin0),
	.iDin4(oDin1),
	.iDin5(oDin2),

	.iDin6(oDin0),
	.iDin7(oDin1),
	.iDin8(oDin2),

	.iDin9(oDin0),
	.iDin10(oDin1),
	.iDin11(oDin2),
	

	.iWeight0(iWeight[0]),
	.iWeight1(iWeight[1]),
	.iWeight2(iWeight[2]),
	.iWeight3(iWeight[3]),
	.iWeight4(iWeight[4]),
	.iWeight5(iWeight[5]),
	.iWeight6(iWeight[6]),
	.iWeight7(iWeight[7]),
	.iWeight8(iWeight[8]),
	.iWeight9(iWeight[9]),
	.iWeight10(iWeight[10]),
	.iWeight11(iWeight[11]),

	.oOut0_0(oOut0[0]),
	.oOut0_1(oOut1[0]),
	.oOut0_2(oOut2[0]),
	.oOut0_3(oOut3[0]),

	.oOut1_0(oOut0[1]),
	.oOut1_1(oOut1[1]),
	.oOut1_2(oOut2[1]),
	.oOut1_3(oOut3[1]),

	.oOut2_0(oOut0[2]),
	.oOut2_1(oOut1[2]),
	.oOut2_2(oOut2[2]),
	.oOut2_3(oOut3[2]),

	.oOut3_0(oOut0[3]),
	.oOut3_1(oOut1[3]),
	.oOut3_2(oOut2[3]),
	.oOut3_3(oOut3[3]),

	.oOut4_0(oOut0[4]),
	.oOut4_1(oOut1[4]),
	.oOut4_2(oOut2[4]),
	.oOut4_3(oOut3[4]),

	.oOut5_0(oOut0[5]),
	.oOut5_1(oOut1[5]),
	.oOut5_2(oOut2[5]),
	.oOut5_3(oOut3[5]),

	.oOut6_0(oOut0[6]),
	.oOut6_1(oOut1[6]),
	.oOut6_2(oOut2[6]),
	.oOut6_3(oOut3[6]),

	.oOut7_0(oOut0[7]),
	.oOut7_1(oOut1[7]),
	.oOut7_2(oOut2[7]),
	.oOut7_3(oOut3[7]),

	.oOut8_0(oOut0[8]),
	.oOut8_1(oOut1[8]),
	.oOut8_2(oOut2[8]),
	.oOut8_3(oOut3[8]),

	.oOut9_0(oOut0[9]),
	.oOut9_1(oOut1[9]),
	.oOut9_2(oOut2[9]),
	.oOut9_3(oOut3[9]),

	.oOut10_0(oOut0[10]),
	.oOut10_1(oOut1[10]),
	.oOut10_2(oOut2[10]),
	.oOut10_3(oOut3[10]),

	.oOut11_0(oOut0[11]),//[mac number]
	.oOut11_1(oOut1[11]),
	.oOut11_2(oOut2[11]),
	.oOut11_3(oOut3[11]),

	//output
	.bank_vld(w_bank_vld),
	.bank_vld_prev(w_bank_vld_prev)

);


// always@(posedge clk, negedge rstn) begin
// 	if(!rstn) begin
// 		vld_i_d1 <= 0;
// 		vld_i_d2 <= 0;
// 		vld_i_d3 <= 0;
// 		vld_i_d4 <= 0;
// 	end
// 	else begin 
// 		vld_i_d1 <= wMac_vld;
// 		vld_i_d2 <= vld_i_d1;
// 		vld_i_d3 <= vld_i_d2;
// 		vld_i_d4 <= vld_i_d3;	
// 	end
// end


bias_ctrl bias_ctrl(
	.clk(clk),
	.rstn(rstn),
	.i_vld(w_bank_vld_prev),
	.i_cs(1),
	.o_bias(w_bias)
);

reg bank_delay;
always @(posedge clk, negedge rstn) begin
	if(!rstn) begin
		bank_delay <= 0;
	end
	else begin
		bank_delay <= w_bank_vld;
	end
end
adder_tree2 addertree2_0(//filter 0
	.clk(clk),
	.rstn(rstn),
	.vld_i(bank_delay),

	.iOut0(oOut0[0]),
	.iOut1(oOut0[1]),
	.iOut2(oOut0[2]),

	.iOut3(oOut1[0]),
	.iOut4(oOut1[1]),
	.iOut5(oOut1[2]),

	.iOut6(oOut2[0]),
	.iOut7(oOut2[1]),
	.iOut8(oOut2[2]),

	.iOut9(oOut3[0]),
	.iOut10(oOut3[1]),
	.iOut11(oOut3[2]),

	.iBias(iBias0),

	.oOut0(w_after_add0[0]),
	.oOut1(w_after_add0[1]),
	.oOut2(w_after_add0[2]),
	.oOut3(w_after_add0[3]),

	.add_vld(w_add_vld0)
);


adder_tree2 addertree2_1(//filter 1
	.clk(clk),
	.rstn(rstn),
	.vld_i(bank_delay),

	.iOut0(oOut0[3]),
	.iOut1(oOut0[4]),
	.iOut2(oOut0[5]),

	.iOut3(oOut1[3]),
	.iOut4(oOut1[4]),
	.iOut5(oOut1[5]),

	.iOut6(oOut2[3]),
	.iOut7(oOut2[4]),
	.iOut8(oOut2[5]),

	.iOut9(oOut3[3]),
	.iOut10(oOut3[4]),
	.iOut11(oOut3[5]),

	.iBias(iBias1),

	.oOut0(w_after_add1[0]),
	.oOut1(w_after_add1[1]),
	.oOut2(w_after_add1[2]),
	.oOut3(w_after_add1[3]),

	.add_vld(w_add_vld1)
);


adder_tree2 addertree2_2(//filter 2
	.clk(clk),
	.rstn(rstn),
	.vld_i(bank_delay),

	.iOut0(oOut0[6]),
	.iOut1(oOut0[7]),
	.iOut2(oOut0[8]),

	.iOut3(oOut1[6]),
	.iOut4(oOut1[7]),
	.iOut5(oOut1[8]),

	.iOut6(oOut2[6]),
	.iOut7(oOut2[7]),
	.iOut8(oOut2[8]),

	.iOut9(oOut3[6]),
	.iOut10(oOut3[7]),
	.iOut11(oOut3[8]),

	.iBias(iBias2),

	.oOut0(w_after_add2[0]),
	.oOut1(w_after_add2[1]),
	.oOut2(w_after_add2[2]),
	.oOut3(w_after_add2[3]),

	.add_vld(w_add_vld2)
);


adder_tree2 addertree2_3(//filter 3
	.clk(clk),
	.rstn(rstn),
	.vld_i(bank_delay),

	.iOut0(oOut0[9]),
	.iOut1(oOut0[10]),
	.iOut2(oOut0[11]),

	.iOut3(oOut1[9]),
	.iOut4(oOut1[10]),
	.iOut5(oOut1[11]),

	.iOut6(oOut2[9]),
	.iOut7(oOut2[10]),
	.iOut8(oOut2[11]),

	.iOut9(oOut3[9]),
	.iOut10(oOut3[10]),
	.iOut11(oOut3[11]),

	.iBias(iBias3),

	.oOut0(w_after_add3[0]),
	.oOut1(w_after_add3[1]),
	.oOut2(w_after_add3[2]),
	.oOut3(w_after_add3[3]),

	.add_vld(w_add_vld3)
);


additional_layer00 addLayer0(
	.clk(clk), 
    .rstn(rstn), 
    .i_vld(w_add_vld0), 
	
	.in0(w_after_add0[0]),
	.in1(w_after_add0[1]),
	.in2(w_after_add0[2]),
	.in3(w_after_add0[3]),

	.oOut(oLayer0_0)
);


additional_layer00 addLayer1(
	.clk(clk), 
	.rstn(rstn), 
	.i_vld(w_add_vld1), 
	
	.in0(w_after_add1[0]),
	.in1(w_after_add1[1]),
	.in2(w_after_add1[2]),
	.in3(w_after_add1[3]),

	.oOut(oLayer0_1)
);


additional_layer00 addLayer2(
	.clk(clk), 
	.rstn(rstn), 
	.i_vld(w_add_vld2), 
	
	.in0(w_after_add2[0]),
	.in1(w_after_add2[1]),
	.in2(w_after_add2[2]),
	.in3(w_after_add2[3]),

	.oOut(oLayer0_2)
);


additional_layer00 addLayer3(
	.clk(clk), 
	.rstn(rstn), 
	.i_vld(w_add_vld3), 
	
	.in0(w_after_add3[0]),
	.in1(w_after_add3[1]),
	.in2(w_after_add3[2]),
	.in3(w_after_add3[3]),

	.oOut(oLayer0_3)
);


endmodule