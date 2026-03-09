module adder_tree2 (
	input 				 clk,
	input 				 rstn,
	input 				 vld_i,

	input  		  [19:0] iOut0,
	input  		  [19:0] iOut1,
	input  		  [19:0] iOut2,
	input  		  [19:0] iOut3,
	input  		  [19:0] iOut4,
	input  		  [19:0] iOut5,
	input  		  [19:0] iOut6,
	input  		  [19:0] iOut7,
	input  		  [19:0] iOut8,
	input  		  [19:0] iOut9,
	input  		  [19:0] iOut10,
	input  		  [19:0] iOut11,

	input  		  [15:0] iBias,

	output 		  [21:0] oOut0,
	output 		  [21:0] oOut1,
	output 		  [21:0] oOut2,
	output 		  [21:0] oOut3,

	output add_vld

);
	
reg 	[20:0] 	y0_0, y1_0, y2_0, y3_0, y4_0, y5_0, y6_0, y7_0;//level0
reg 	[21:0] 	y0_1, y1_1, y2_1, y3_1;//level1
reg 			rAdd_vld1, rAdd_vld2, rAdd_vld3;


assign add_vld = rAdd_vld2;
assign oOut0 = y0_1;
assign oOut1 = y1_1;
assign oOut2 = y2_1;
assign oOut3 = y3_1;

always @(posedge clk, negedge rstn) begin
	if(!rstn) begin
		y0_0 <= 21'd0;
		y1_0 <= 21'd0;
		y2_0 <= 21'd0;
		y3_0 <= 21'd0;
		y4_0 <= 21'd0;
		y5_0 <= 21'd0;
		y6_0 <= 21'd0;
		y7_0 <= 21'd0;
	end

	else begin 
		y0_0 <= $signed(iOut0)  + $signed(iOut1);
		y1_0 <= $signed(iOut2)  + $signed(iBias);

		y2_0 <= $signed(iOut3)  + $signed(iOut4);
		y3_0 <= $signed(iOut5)  + $signed(iBias);

		y4_0 <= $signed(iOut6)  + $signed(iOut7);
		y5_0 <= $signed(iOut8)  + $signed(iBias);

		y6_0 <= $signed(iOut9)  + $signed(iOut10);
		y7_0 <= $signed(iOut11) + $signed(iBias);
	end

end


always @(posedge clk, negedge rstn) begin
	if(!rstn) begin
		y0_1 <= 22'd0;
		y1_1 <= 22'd0;
		y2_1 <= 22'd0;
		y3_1 <= 22'd0;
	end
	else begin 
		y0_1 <= $signed(y0_0) + $signed(y1_0);
		y1_1 <= $signed(y2_0) + $signed(y3_0);
		y2_1 <= $signed(y4_0) + $signed(y5_0);
		y3_1 <= $signed(y6_0) + $signed(y7_0);
	end
end


always @(posedge clk, negedge rstn) begin//2clk dealy
	if (!rstn) begin
		rAdd_vld1 <= 0;
		rAdd_vld2 <= 0;
		rAdd_vld3 <= 0;
	end

	else begin
		rAdd_vld1 <= vld_i;
		rAdd_vld2 <= rAdd_vld1;
		rAdd_vld3 <= rAdd_vld2;
	end

end


endmodule