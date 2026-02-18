module top (
	input wire iClk,
	input wire iClkTFT,
	input wire iRstButton,
	output wire oLcdHSync,
    output wire oLcdVSync,
    output wire [4:0] oLcdR,
    output wire [5:0] oLcdG,
    output wire [4:0] oLcdB,
	input wire [31:0] iReg0,
	input wire [31:0] iReg1,
	input wire [31:0] iReg2,
	input wire [31:0] iReg3,
	input wire wStart	
);

wire [23:0] lcd_rd_data_w;

wire oCs;
wire [16:0] lcd_rd_addr_w;

cnn_top u_cnn_top(
	.iClk(iClk),
	.iClkTFT(iClkTFT),
	.iRstButton(iRstButton),

	.lcd_rd_data_w(lcd_rd_data_w),

	 .oCs(oCs),
	 .lcd_rd_addr_w(lcd_rd_addr_w),
	
    .oLcdHSync(oLcdHSync),
    .oLcdVSync(oLcdVSync),
    .oLcdR(oLcdR),
    .oLcdG(oLcdG),
    .oLcdB(oLcdB),

	// axi lite interface
	.iReg0(iReg0),
	.iReg1(iReg1),
	.iReg2(iReg2),
	.iReg3(iReg3),
	.wStart(wStart)	
);

inbuf_wrapper u_inbuf_wrapper(//rom
	.clka(iClk),
    .ena(oCs),
    .wea(0),     // 1'b1 write, 1'b0 read
    .addra(lcd_rd_addr_w),   // 0..DEPTH-1
    .dina(24'b0),
    .douta(lcd_rd_data_w)
);
endmodule