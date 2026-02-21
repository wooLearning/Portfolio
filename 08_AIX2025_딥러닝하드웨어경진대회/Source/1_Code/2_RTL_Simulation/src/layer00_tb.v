`timescale 1ns/ 1ns

module layer00_tb();

reg clk, rstn, iStart;
// Clock
parameter CLK_PERIOD = 10;	//100MHz
initial begin
	clk = 1'b1;
	forever #(CLK_PERIOD/2) clk = ~clk;
end

/*for Test wire*/
reg [15:0] i_ena;		// enable for write address
reg [8:0] i_addra;	// input address for write
reg [15:0] i_wea;		// input write enable
reg [127:0] i_dia;		// input write data

reg [1:0] i_layerInfo;

wire [31:0] oLayer_result;

wire oLayer_vld;

layer00 layer00(
	.clk(clk),
	.rstn(rstn),
	.iStart(iStart),

	/*for Test wire*/
	.i_ena(i_ena),		// enable for write address
	.i_addra(i_addra),	// input address for write
	.i_wea(i_wea),		// input write enable
	.i_dia(i_dia),		// input write data
	.i_layerInfo(i_layerInfo),
	.oLayer_result(oLayer_result),

	.oLayer_vld(oLayer_vld)
);


parameter IFM00_DATA_SIZE  = 256*256;	
parameter IFM_FILE_00 = "C:/yolohw/src/row_col_fas/last_test/data/input_feature_map.hex"; 
//parameter BIAS_FILE_15 = "C:/yolohw/sim/inout_data_sw/log_param/CONV00_param_biases.hex";
reg  [31:0] in_img[0:IFM00_DATA_SIZE-1];  // Infmap
//reg  [15:0] r_Bias[0:15];  // Bias
 
integer i,j,k;
initial begin: PROC_SimmemLoad
	// Inputs
	for (i = 0; i< IFM00_DATA_SIZE; i=i+1) begin
		in_img[i] = 0;
	end
	// for(i=0; i<16; i=i+1) begin
	// 	r_Bias[i] = 0;
	// end
	$display ("Loading input feature maps from file: %s", IFM_FILE_00);
	$readmemh(IFM_FILE_00, in_img);
	// for (i = 0; i< 100; i=i+1) begin
	// 	$display ("%x", in_img[i]);
	// end
	// $display ("Loading bias from file: %s", BIAS_FILE_15 );
	// $readmemh(BIAS_FILE_15, r_Bias);
end


initial begin
	rstn = 1'b0;
	#10;
	rstn = 1'b1;
	iStart = 1'b0;
	i_layerInfo = 2'b00;
	j=0; 
	k=0;
	/*bram init*/
	i_ena = 16'b0000_0000_0000_0001;
	i_wea = 16'b0000_0000_0000_0001;
	#10;
	@(posedge clk);
	for(i = 0; i< 128; i = i + 1) begin
		@(posedge clk);
		i_addra = i;
		i_dia = in_img[j];
		j = j + 1;
	end
	@(posedge clk);//k=0 end

	for(k = 1; k < 16; k = k + 1) begin
		i_ena = i_ena << 1;
		i_wea = i_ena;
		j=4096*k;
		#10;
		@(posedge clk);
		for(i = 0; i< 128; i = i + 1) begin
			@(posedge clk);
			i_addra = i;
			i_dia = in_img[j];
			j = j + 1;
		end
		@(posedge clk);
	end


	iStart = 1'b1;

end



endmodule