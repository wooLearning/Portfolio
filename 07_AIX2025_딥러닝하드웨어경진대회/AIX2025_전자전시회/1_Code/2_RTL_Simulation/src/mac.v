`timescale 1ns / 1ps

module mac(
    input clk, 
    input rstn, 
    input vld_i,

    input [127:0]        iDin,

    input [71:0]         iWeight,

    output  [19:0] oOut0,
    output  [19:0] oOut1,
    output  [19:0] oOut2,
    output  [19:0] oOut3,

    output vld_mac,
    output vld_mac_prev

);

wire    [15:0]  wmul_out0[0:8];
wire    [15:0]  wmul_out1[0:8];
wire    [15:0]  wmul_out2[0:8];
wire    [15:0]  wmul_out3[0:8];
wire    [19:0]  w_acc_o[0:3];

wire            w_vld_o;
assign vld_mac = w_vld_o;
reg vld_i_d0, vld_i_d1, vld_i_d2, vld_i_d3, vld_i_d4, vld_i_d5;

//----------------------------------------------------------------------
// Components: Array of multipliers
//----------------------------------------------------------------------

wire [7:0] iDin0  = iDin[0+:8];
wire [7:0] iDin1  = iDin[8+:8];
wire [7:0] iDin2  = iDin[16+:8];
wire [7:0] iDin3  = iDin[24+:8];
wire [7:0] iDin4  = iDin[32+:8];
wire [7:0] iDin5  = iDin[40+:8];
wire [7:0] iDin6  = iDin[48+:8];
wire [7:0] iDin7  = iDin[56+:8];
wire [7:0] iDin8  = iDin[64+:8];
wire [7:0] iDin9  = iDin[72+:8];
wire [7:0] iDin10 = iDin[80+:8];
wire [7:0] iDin11 = iDin[88+:8];
wire [7:0] iDin12 = iDin[96+:8];
wire [7:0] iDin13 = iDin[104+:8];
wire [7:0] iDin14 = iDin[112+:8];
wire [7:0] iDin15 = iDin[120+:8];

wire [7:0] iWeight0 = iWeight[0+:8];
wire [7:0] iWeight1 = iWeight[8+:8];
wire [7:0] iWeight2 = iWeight[16+:8];
wire [7:0] iWeight3 = iWeight[24+:8];
wire [7:0] iWeight4 = iWeight[32+:8];
wire [7:0] iWeight5 = iWeight[40+:8];
wire [7:0] iWeight6 = iWeight[48+:8];
wire [7:0] iWeight7 = iWeight[56+:8];
wire [7:0] iWeight8 = iWeight[64+:8];


/*weight0*/
mul mul0_0(
    .clk(clk),
    .a(iDin0),
    .b(iDin1),  
    .c(iWeight0), 
    .ac(wmul_out0[0]),
    .bc(wmul_out1[0])
);
mul mul0_1(
    .clk(clk),
    .a(iDin4),
    .b(iDin5),  
    .c(iWeight0), 
    .ac(wmul_out2[0]),
    .bc(wmul_out3[0])
);

/*weight1*/
mul mul1_0(
    .clk(clk),
    .a(iDin1),
    .b(iDin2),  
    .c(iWeight1), 
    .ac(wmul_out0[1]),
    .bc(wmul_out1[1])
);
mul mul1_1(
    .clk(clk),
    .a(iDin5),
    .b(iDin6),  
    .c(iWeight1), 
    .ac(wmul_out2[1]),
    .bc(wmul_out3[1])
);

/*weight2*/
mul mul2_0(
    .clk(clk),
    .a(iDin2),
    .b(iDin3),  
    .c(iWeight2), 
    .ac(wmul_out0[2]),
    .bc(wmul_out1[2])
);
mul mul2_1(
    .clk(clk),
    .a(iDin6),
    .b(iDin7),  
    .c(iWeight2), 
    .ac(wmul_out2[2]),
    .bc(wmul_out3[2])
);

/*weight3*/
mul mul3_0(
    .clk(clk),
    .a(iDin4),
    .b(iDin5),  
    .c(iWeight3), 
    .ac(wmul_out0[3]),
    .bc(wmul_out1[3])
);
mul mul3_1(
    .clk(clk),
    .a(iDin8),
    .b(iDin9),  
    .c(iWeight3), 
    .ac(wmul_out2[3]),
    .bc(wmul_out3[3])
);

/*weight4*/
mul mul4_0(
    .clk(clk),
    .a(iDin5),
    .b(iDin6),  
    .c(iWeight4), 
    .ac(wmul_out0[4]),
    .bc(wmul_out1[4])
);
mul mul4_1(
    .clk(clk),
    .a(iDin9),
    .b(iDin10),  
    .c(iWeight4), 
    .ac(wmul_out2[4]),
    .bc(wmul_out3[4])
);

/*weight5*/
mul mul5_0(
    .clk(clk),
    .a(iDin6),
    .b(iDin7),  
    .c(iWeight5), 
    .ac(wmul_out0[5]),
    .bc(wmul_out1[5])
);
mul mul5_1(
    .clk(clk),
    .a(iDin10),
    .b(iDin11),  
    .c(iWeight5), 
    .ac(wmul_out2[5]),
    .bc(wmul_out3[5])
);

/*weight6*/
mul mul6_0(
    .clk(clk),
    .a(iDin8),
    .b(iDin9),  
    .c(iWeight6), 
    .ac(wmul_out0[6]),
    .bc(wmul_out1[6])
);
mul mul6_1(
    .clk(clk),
    .a(iDin12),
    .b(iDin13),  
    .c(iWeight6), 
    .ac(wmul_out2[6]),
    .bc(wmul_out3[6])
);

/*weight7*/
mul mul7_0(
    .clk(clk),
    .a(iDin9),
    .b(iDin10),  
    .c(iWeight7), 
    .ac(wmul_out0[7]),
    .bc(wmul_out1[7])
);
mul mul7_1(
    .clk(clk),
    .a(iDin13),
    .b(iDin14),  
    .c(iWeight7), 
    .ac(wmul_out2[7]),
    .bc(wmul_out3[7])
);

/*weight8*/
mul mul8_0(
    .clk(clk),
    .a(iDin10),
    .b(iDin11),  
    .c(iWeight8), 
    .ac(wmul_out0[8]),
    .bc(wmul_out1[8])
);
mul mul8_1(
    .clk(clk),
    .a(iDin14),
    .b(iDin15),  
    .c(iWeight8), 
    .ac(wmul_out2[8]),
    .bc(wmul_out3[8])
);

//----------------------------------------------------------------------
// Delays
//----------------------------------------------------------------------
always@(posedge clk, negedge rstn) begin
	if(!rstn) begin
	    vld_i_d0 <= 0;
		vld_i_d1 <= 0;
		vld_i_d2 <= 0;
		vld_i_d3 <= 0;
		vld_i_d4 <= 0;
        vld_i_d5 <= 0;
	end
	else begin 
		vld_i_d0 <= vld_i   ;
		vld_i_d1 <= vld_i_d0;
		vld_i_d2 <= vld_i_d1;
		vld_i_d3 <= vld_i_d2;
		vld_i_d4 <= vld_i_d3;	
        vld_i_d5 <= vld_i_d4;
	end
end

// reg signBit;
// always @(posedge clk, negedge rstn) begin
//     if(!rstn) begin
//         signBit <=0;
//     end
//     else if(vld_i) begin
//         signBit <= iWeight0[7];
//     end
//     else if(vld_i_d4) begin
//         signBit <= 0;
//     end
//     else begin
//         signBit <= signBit;
//     end
// end

//assign wmul_out0[0] = wmul_out0[0] + signBit;

//----------------------------------------------------------------------
// Adder tree
//----------------------------------------------------------------------
wire w_vld_o_prev;
assign vld_mac_prev = w_vld_o_prev;
adder_tree u_adder_tree0(
./*input 		*/clk(clk), 
./*input 		*/rstn(rstn),
./*input 		*/vld_i(vld_i_d4),
./*input [15:0] */mul_00(wmul_out0[0]), 
./*input [15:0] */mul_01(wmul_out0[1]), 
./*input [15:0] */mul_02(wmul_out0[2]), 
./*input [15:0] */mul_03(wmul_out0[3]), 
./*input [15:0] */mul_04(wmul_out0[4]), 
./*input [15:0] */mul_05(wmul_out0[5]), 
./*input [15:0] */mul_06(wmul_out0[6]), 
./*input [15:0] */mul_07(wmul_out0[7]),
./*input [15:0] */mul_08(wmul_out0[8]), 
./*output[19:0] */acc_o(w_acc_o[0]),
./*output       */vld_o(w_vld_o) ,
                .vld_o_prev(w_vld_o_prev)
);

adder_tree u_adder_tree1(
./*input 		*/clk(clk), 
./*input 		*/rstn(rstn),
./*input 		*/vld_i(vld_i_d4),
./*input [15:0] */mul_00(wmul_out1[0]), 
./*input [15:0] */mul_01(wmul_out1[1]), 
./*input [15:0] */mul_02(wmul_out1[2]), 
./*input [15:0] */mul_03(wmul_out1[3]), 
./*input [15:0] */mul_04(wmul_out1[4]), 
./*input [15:0] */mul_05(wmul_out1[5]), 
./*input [15:0] */mul_06(wmul_out1[6]), 
./*input [15:0] */mul_07(wmul_out1[7]),
./*input [15:0] */mul_08(wmul_out1[8]), 
./*output[19:0] */acc_o(w_acc_o[1]),
./*output       */vld_o(w_vld_o) 
);

adder_tree u_adder_tree2(
./*input 		*/clk(clk), 
./*input 		*/rstn(rstn),
./*input 		*/vld_i(vld_i_d4),
./*input [15:0] */mul_00(wmul_out2[0]), 
./*input [15:0] */mul_01(wmul_out2[1]), 
./*input [15:0] */mul_02(wmul_out2[2]), 
./*input [15:0] */mul_03(wmul_out2[3]), 
./*input [15:0] */mul_04(wmul_out2[4]), 
./*input [15:0] */mul_05(wmul_out2[5]), 
./*input [15:0] */mul_06(wmul_out2[6]), 
./*input [15:0] */mul_07(wmul_out2[7]),
./*input [15:0] */mul_08(wmul_out2[8]), 
./*output[19:0] */acc_o(w_acc_o[2]),
./*output       */vld_o(w_vld_o) 

);

adder_tree u_adder_tree3(
./*input 		*/clk(clk), 
./*input 		*/rstn(rstn),
./*input 		*/vld_i(vld_i_d4),
./*input [15:0] */mul_00(wmul_out3[0]), 
./*input [15:0] */mul_01(wmul_out3[1]), 
./*input [15:0] */mul_02(wmul_out3[2]), 
./*input [15:0] */mul_03(wmul_out3[3]), 
./*input [15:0] */mul_04(wmul_out3[4]), 
./*input [15:0] */mul_05(wmul_out3[5]), 
./*input [15:0] */mul_06(wmul_out3[6]), 
./*input [15:0] */mul_07(wmul_out3[7]),
./*input [15:0] */mul_08(wmul_out3[8]), 
./*output[19:0] */acc_o(w_acc_o[3]),
./*output       */vld_o(w_vld_o) 
);

assign oOut0 = w_acc_o[0]; 
assign oOut1 = w_acc_o[1]; 
assign oOut2 = w_acc_o[2]; 
assign oOut3 = w_acc_o[3];


endmodule