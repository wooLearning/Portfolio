module bias_ctrl (
	input clk,
	input rstn,
	input i_vld,
    input i_cs,
	output [63:0] o_bias
);
	
//for bias addressing
reg [3:0] r_bias_addr;
reg [63:0] r_bias;
wire [6:0] w_bias_addr = {3'b0, r_bias_addr};
wire [63:0] w_bias;

always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        r_bias_addr <= 0;
        r_bias <= 0;
    end
    else if(r_bias_addr == 4) begin
        r_bias_addr <= 0;
    end
    else if(i_vld) begin
        r_bias <= w_bias;
        r_bias_addr <= r_bias_addr + 1'b1;
    end
    else begin
        r_bias <= r_bias;
        r_bias_addr <= r_bias_addr;
    end 
       
end



generate
/*for bias rom*/
rom_bias_128x64 u_rom_bias_128x64( 
    // write
    .clka(clk),
    .ena(i_cs ),
    .wea(1'b0),
    .addra(w_bias_addr),
    .dina(0),//don't care for this rom 
    // read-out
    .douta(w_bias)
);
endgenerate

assign o_bias = r_bias;

endmodule