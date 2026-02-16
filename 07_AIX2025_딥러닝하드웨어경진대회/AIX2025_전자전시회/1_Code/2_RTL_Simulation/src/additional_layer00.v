module additional_layer00 (
	input clk, 
	input rstn, 
	input i_vld,
	
	input [21:0] in0,
	input [21:0] in1,
	input [21:0] in2,
	input [21:0] in3,

	output [7:0] oOut
);
//activation
wire [31:0] wSum_act[0:3];
assign wSum_act[0] = (i_vld) ? ((in0[21]==1)?0:in0): 0;
assign wSum_act[1] = (i_vld) ? ((in1[21]==1)?0:in1): 0;
assign wSum_act[2] = (i_vld) ? ((in2[21]==1)?0:in2): 0;
assign wSum_act[3] = (i_vld) ? ((in3[21]==1)?0:in3): 0;

//descaling
wire [7:0] wDes[0:3];
assign wDes[0] = (i_vld) ? ((wSum_act[0][31:7]>127)?127:wSum_act[0][14:7]):0; // Descaling: * 1/2^11	
assign wDes[1] = (i_vld) ? ((wSum_act[1][31:7]>127)?127:wSum_act[1][14:7]):0; // Descaling: * 1/2^11	
assign wDes[2] = (i_vld) ? ((wSum_act[2][31:7]>127)?127:wSum_act[2][14:7]):0; // Descaling: * 1/2^11	
assign wDes[3] = (i_vld) ? ((wSum_act[3][31:7]>127)?127:wSum_act[3][14:7]):0; // Descaling: * 1/2^11

/*max pooling*/
wire [7:0] wMax0, wMax1;
assign wMax0 = (wDes[0] > wDes[1]) ? wDes[0] : wDes[1];
assign wMax1 = (wDes[2] > wDes[3]) ? wDes[2] : wDes[3];
assign oOut = (wMax0 > wMax1) ? wMax0 : wMax1;

endmodule