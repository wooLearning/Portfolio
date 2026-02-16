module weight_tb();

reg clk, rstn, i_load_en;

wire o_ready;
wire [71:0] o_kernel[0:11];

weight_ctrl dut_weight_ctrl(
	.clk(clk),
    .rstn(rstn),
    .i_load_en(i_load_en),                       
    
    .o_ready(o_ready),

	.o_kernel0(o_kernel[0]),
	.o_kernel1(o_kernel[1]),
	.o_kernel2(o_kernel[2]),
	.o_kernel3(o_kernel[3]),
	.o_kernel4(o_kernel[4]),
	.o_kernel5(o_kernel[5]),
	.o_kernel6(o_kernel[6]),
	.o_kernel7(o_kernel[7]),
	.o_kernel8(o_kernel[8]),
	.o_kernel9(o_kernel[9]),
	.o_kernel10(o_kernel[10]),
	.o_kernel11(o_kernel[11])
);

// Clock
parameter CLK_PERIOD = 10;	//100MHz
initial begin
	clk = 1'b1;
	forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
	rstn = 1'b0;
	#(CLK_PERIOD*2);
	rstn = 1'b1;
	#(CLK_PERIOD*2);
	
	i_load_en = 1;


end
endmodule

