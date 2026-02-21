module mac_bank (
	input clk, 
    input rstn, 
    input vld_i, 

	input [127:0] iDin0,
	input [127:0] iDin1,
	input [127:0] iDin2,
	input [127:0] iDin3,
	input [127:0] iDin4,
	input [127:0] iDin5,
	input [127:0] iDin6,
	input [127:0] iDin7,
	input [127:0] iDin8,
	input [127:0] iDin9,
	input [127:0] iDin10,
	input [127:0] iDin11,

	input [71:0] iWeight0,
	input [71:0] iWeight1,
	input [71:0] iWeight2,
	input [71:0] iWeight3,
	input [71:0] iWeight4,
	input [71:0] iWeight5,
	input [71:0] iWeight6,
	input [71:0] iWeight7,
	input [71:0] iWeight8,
	input [71:0] iWeight9,
	input [71:0] iWeight10,
	input [71:0] iWeight11,

	output [19:0] oOut0_0,
	output [19:0] oOut0_1,
	output [19:0] oOut0_2,
	output [19:0] oOut0_3,

	output [19:0] oOut1_0,
	output [19:0] oOut1_1,
	output [19:0] oOut1_2,
	output [19:0] oOut1_3,

	output [19:0] oOut2_0,
	output [19:0] oOut2_1,
	output [19:0] oOut2_2,
	output [19:0] oOut2_3,

	output [19:0] oOut3_0,
	output [19:0] oOut3_1,
	output [19:0] oOut3_2,
	output [19:0] oOut3_3,

	output [19:0] oOut4_0,
	output [19:0] oOut4_1,
	output [19:0] oOut4_2,
	output [19:0] oOut4_3,

	output [19:0] oOut5_0,
	output [19:0] oOut5_1,
	output [19:0] oOut5_2,
	output [19:0] oOut5_3,

	output [19:0] oOut6_0,
	output [19:0] oOut6_1,
	output [19:0] oOut6_2,
	output [19:0] oOut6_3,

	output [19:0] oOut7_0,
	output [19:0] oOut7_1,
	output [19:0] oOut7_2,
	output [19:0] oOut7_3,

	output [19:0] oOut8_0,
	output [19:0] oOut8_1,
	output [19:0] oOut8_2,
	output [19:0] oOut8_3,

	output [19:0] oOut9_0,
	output [19:0] oOut9_1,
	output [19:0] oOut9_2,
	output [19:0] oOut9_3,

	output [19:0] oOut10_0,
	output [19:0] oOut10_1,
	output [19:0] oOut10_2,
	output [19:0] oOut10_3,

	output [19:0] oOut11_0,
	output [19:0] oOut11_1,
	output [19:0] oOut11_2,
	output [19:0] oOut11_3,

	output bank_vld,
	output bank_vld_prev
);

genvar i;

wire 		[127:0]	w_iDin[0:11];
wire 		[72:0]  w_iWeight[0:11];

wire		[19:0]	wOut0[0:11];	
wire		[19:0] 	wOut1[0:11];
wire		[19:0] 	wOut2[0:11];
wire		[19:0] 	wOut3[0:11];

assign w_iDin[0]  = iDin0;
assign w_iDin[1]  = iDin1;
assign w_iDin[2]  = iDin2;
assign w_iDin[3]  = iDin3;
assign w_iDin[4]  = iDin4;
assign w_iDin[5]  = iDin5;
assign w_iDin[6]  = iDin6;
assign w_iDin[7]  = iDin7;
assign w_iDin[8]  = iDin8;
assign w_iDin[9]  = iDin9;
assign w_iDin[10] = iDin10;
assign w_iDin[11] = iDin11;

assign w_iWeight[0]  = iWeight0;
assign w_iWeight[1]  = iWeight1;
assign w_iWeight[2]  = iWeight2;
assign w_iWeight[3]  = iWeight3;
assign w_iWeight[4]  = iWeight4;
assign w_iWeight[5]  = iWeight5;
assign w_iWeight[6]  = iWeight6;
assign w_iWeight[7]  = iWeight7;
assign w_iWeight[8]  = iWeight8;
assign w_iWeight[9]  = iWeight9;
assign w_iWeight[10] = iWeight10;
assign w_iWeight[11] = iWeight11;

generate
    for (i = 0; i < 12; i = i + 1) begin : mac_inst
        mac mac_inst (
            .clk(clk), 
            .rstn(rstn), 
            .vld_i(vld_i), 
            .iDin(w_iDin[i]),
            .iWeight(w_iWeight[i]),
            .oOut0(wOut0[i]),
			.oOut1(wOut1[i]),
			.oOut2(wOut2[i]),
			.oOut3(wOut3[i]),
			.vld_mac(bank_vld),
			.vld_mac_prev(bank_vld_prev)
        );
    end
endgenerate

assign oOut0_0 = wOut0[0];
assign oOut0_1 = wOut1[0];
assign oOut0_2 = wOut2[0];
assign oOut0_3 = wOut3[0];

assign oOut1_0 = wOut0[1];
assign oOut1_1 = wOut1[1];
assign oOut1_2 = wOut2[1];
assign oOut1_3 = wOut3[1];

assign oOut2_0 = wOut0[2];
assign oOut2_1 = wOut1[2];
assign oOut2_2 = wOut2[2];
assign oOut2_3 = wOut3[2];

assign oOut3_0 = wOut0[3];
assign oOut3_1 = wOut1[3];
assign oOut3_2 = wOut2[3];
assign oOut3_3 = wOut3[3];

assign oOut4_0 = wOut0[4];
assign oOut4_1 = wOut1[4];
assign oOut4_2 = wOut2[4];
assign oOut4_3 = wOut3[4];

assign oOut5_0 = wOut0[5];
assign oOut5_1 = wOut1[5];
assign oOut5_2 = wOut2[5];
assign oOut5_3 = wOut3[5];

assign oOut6_0 = wOut0[6];
assign oOut6_1 = wOut1[6];
assign oOut6_2 = wOut2[6];
assign oOut6_3 = wOut3[6];

assign oOut7_0 = wOut0[7];
assign oOut7_1 = wOut1[7];
assign oOut7_2 = wOut2[7];
assign oOut7_3 = wOut3[7];

assign oOut8_0 = wOut0[8];
assign oOut8_1 = wOut1[8];
assign oOut8_2 = wOut2[8];
assign oOut8_3 = wOut3[8];

assign oOut9_0 = wOut0[9];
assign oOut9_1 = wOut1[9];
assign oOut9_2 = wOut2[9];
assign oOut9_3 = wOut3[9];

assign oOut10_0 = wOut0[10];
assign oOut10_1 = wOut1[10];
assign oOut10_2 = wOut2[10];
assign oOut10_3 = wOut3[10];

assign oOut11_0 = wOut0[11];
assign oOut11_1 = wOut1[11];
assign oOut11_2 = wOut2[11];
assign oOut11_3 = wOut3[11];


endmodule