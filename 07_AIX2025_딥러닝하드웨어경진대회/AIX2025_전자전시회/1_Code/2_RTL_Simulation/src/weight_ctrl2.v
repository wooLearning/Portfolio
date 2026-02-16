module weight_ctrl #(
    parameter KERNEL_WIDTH  = 72
) (
    input                       clk,
    input                       rstn,
    input                       i_load_en,                       
    
    output o_ready,

    // each kernel has 9 weights (9*8=72 bits)
    output  [KERNEL_WIDTH-1:0]  o_kernel0, // main outputs
    output  [KERNEL_WIDTH-1:0]  o_kernel1,
    output  [KERNEL_WIDTH-1:0]  o_kernel2,

    output  [KERNEL_WIDTH-1:0]  o_kernel3,
    output  [KERNEL_WIDTH-1:0]  o_kernel4,
    output  [KERNEL_WIDTH-1:0]  o_kernel5,

    output  [KERNEL_WIDTH-1:0]  o_kernel6,
    output  [KERNEL_WIDTH-1:0]  o_kernel7,
    output  [KERNEL_WIDTH-1:0]  o_kernel8,

    output  [KERNEL_WIDTH-1:0]  o_kernel9,
    output  [KERNEL_WIDTH-1:0]  o_kernel10,
    output  [KERNEL_WIDTH-1:0]  o_kernel11
    
);

integer i;

localparam ADDR_WIDTH = 5;
reg [ADDR_WIDTH-1:0] addr_cnt;
wire [71:0] w_rom[0:3];
wire w_cs = i_load_en;
wire [9:0] w_rom_addr;


reg r_vld0, r_vld1, r_vld2;// delay 
always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        r_vld0 <=0;
        r_vld1 <=0;
        r_vld2 <=0;
    end
    else if(i_load_en) begin
        r_vld0 <= i_load_en;
        r_vld1 <= r_vld0;
        r_vld2 <= r_vld1;
    end
    else begin
        r_vld0 <=0;
        r_vld1 <=0;
        r_vld2 <= 0;
    end
end

reg [2:0] r_cnt;
always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        r_cnt <= 0;
    end
    else if(!i_load_en) begin
        r_cnt <= 0;
    end
    else if(r_cnt == 4)begin
        r_cnt <= 0;
    end
    else if(r_vld2) begin
        r_cnt <= r_cnt + 1;
    end
end

reg [3:0] r_select;

always @(*) begin
    case (r_cnt)
        3'd0: r_select = 3'b001; 
        3'd1: r_select = 3'b010;
        3'd2: r_select = 3'b100;
        default: r_select = 3'b000;
    endcase
end

reg [71:0] weight[0:11];

always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        for(i=0;i<3;i=i+1) begin
            weight[i] <= 0;
        end
    end
    else if(r_select[0]) begin
        weight[0] <= w_rom[0];
    end
    else if(r_select[1]) begin
        weight[1] <= w_rom[0];
    end
    else if(r_select[2]) begin
        weight[2] <= w_rom[0];
    end
    else begin
        for(i=0;i<3;i=i+1) begin
            weight[i] <= weight[i];
        end
    end
end

always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        for(i=3;i<6;i=i+1) begin
            weight[i] <= 0;
        end
    end
    else if(r_select[0]) begin
        weight[3] <= w_rom[1];
    end
    else if(r_select[1]) begin
        weight[4] <= w_rom[1];
    end
    else if(r_select[2]) begin
        weight[5] <= w_rom[1];
    end
    else begin
        for(i=3;i<6;i=i+1) begin
            weight[i] <= weight[i];
        end
    end
end

always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        for(i=6;i<9;i=i+1) begin
            weight[i] <= 0;
        end
    end
    else if(r_select[0]) begin
        weight[6] <= w_rom[2];
    end
    else if(r_select[1]) begin
        weight[7] <= w_rom[2];
    end
    else if(r_select[2]) begin
        weight[8] <= w_rom[2];
    end
    else begin
        for(i=6;i<9;i=i+1) begin
            weight[i] <= weight[i];
        end
    end
end
always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        for(i=9;i<12;i=i+1) begin
            weight[i] <= 0;
        end
    end
    else if(r_select[0]) begin
        weight[9] <= w_rom[3];
    end
    else if(r_select[1]) begin
        weight[10] <= w_rom[3];
    end
    else if(r_select[2]) begin
        weight[11] <= w_rom[3];
    end
    else begin
        for(i=9;i<12;i=i+1) begin
            weight[i] <= weight[i];
        end
    end
end
assign w_rom_addr = {6'b0,addr_cnt[3:0]};
// main outputs
assign o_kernel0 = weight[0];
assign o_kernel1 = weight[1];
assign o_kernel2 = weight[2];

assign o_kernel3 = weight[3];
assign o_kernel4 = weight[4];
assign o_kernel5 = weight[5];

assign o_kernel6 = weight[6];
assign o_kernel7 = weight[7];
assign o_kernel8 = weight[8];

assign o_kernel9 = weight[9];
assign o_kernel10 = weight[10];
assign o_kernel11 = weight[11];


always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
        addr_cnt <=0;
    end
    else if(!i_load_en) begin
        addr_cnt <= 0;
    end
    else if(addr_cnt == 11)begin
        addr_cnt <= 0;
    end
    else if(r_vld0 && (r_cnt != 1 && r_cnt != 2)) begin
        addr_cnt <= addr_cnt + 1;
    end
    else begin
        addr_cnt <= addr_cnt;
    end
end

assign o_ready = (r_cnt == 4) && i_load_en;

generate
rom_1024x72_0 u_rom_1024x72_0( 
    // write
    .clka(clk),
    .ena(w_cs ),
    .wea(1'b0  ),
    .addra(w_rom_addr ),
    .dina(0),//don't care for this rom 
    // read-out
    .douta(w_rom[0])
);
rom_1024x72_1 u_rom_1024x72_1( 
    // write
    .clka(clk),
    .ena(w_cs ),
    .wea(1'b0  ),
    .addra(w_rom_addr ),
    .dina(0),//don't care for this rom 
    // read-out
    .douta(w_rom[1])
);
rom_1024x72_2 u_rom_1024x72_2( 
    // write
    .clka(clk),
    .ena(w_cs ),
    .wea(1'b0  ),
    .addra(w_rom_addr ),
    .dina(0),//don't care for this rom 
    // read-out
    .douta(w_rom[2])
);
rom_1024x72_3 u_rom_1024x72_3( 
    // write
    .clka(clk),
    .ena(w_cs ),
    .wea(1'b0  ),
    .addra(w_rom_addr ),
    .dina(0),//don't care for this rom 
    // read-out
    .douta(w_rom[3])
);

endgenerate


endmodule