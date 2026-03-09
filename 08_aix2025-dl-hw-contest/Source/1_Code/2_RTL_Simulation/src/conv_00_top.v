module conv_00_top  #(
    parameter MEM_ADDRW          = 22,
    parameter MEM_DW             = 16,
    parameter A                  = 32,
    parameter D                  = 32,
    parameter I                  = 4,
    parameter L                  = 8,
    parameter M                  = D/8,
    parameter AXI_WIDTH_AD       = 32,
    parameter AXI_WIDTH_ID       = 4,
    parameter AXI_WIDTH_DA       = 32,
    parameter AXI_WIDTH_DS       = AXI_WIDTH_DA/8,
    parameter OUT_BITS_TRANS     = 18,
    parameter ADDR_WIDTH         = 14,
    parameter BUF_NUM            = 16,
    parameter DATA_WIDTH         = 32,
    parameter BRAM_DATA_WD       = 128,
    parameter WBUF_AW            = 9,
    parameter WBUF_DW            = 8*3*3*16,
    parameter WBUF_DS            = WBUF_DW/8,
    parameter MEM_BASE_ADDR      = 'h8000_0000,
    parameter MEM_DATA_BASE_ADDR = 4096

)

(     input                          clk
    , input                          rstn

    , input [31:0]                   i_ctrl_reg0    // network_start, // {debug_big(1), debug_buf_select(16), debug_buf_addr(9)}
    , input [31:0]                   i_ctrl_reg1    // Read address base
    , input [31:0]                   i_ctrl_reg2    // Write address base
	, input [31:0]                   i_ctrl_reg3    // Write address base

    , input                          i_end
    , input                          mem_we

    , output                         M_ARVALID
    , input                          M_ARREADY
    , output  [AXI_WIDTH_AD-1:0]     M_ARADDR
    , output  [AXI_WIDTH_ID-1:0]     M_ARID
    , output  [7:0]                  M_ARLEN
    , output  [2:0]                  M_ARSIZE
    , output  [1:0]                  M_ARBURST
    , output  [1:0]                  M_ARLOCK
    , output  [3:0]                  M_ARCACHE
    , output  [2:0]                  M_ARPROT
    , output  [3:0]                  M_ARQOS
    , output  [3:0]                  M_ARREGION
    , output  [3:0]                  M_ARUSER
    , input                          M_RVALID
    , output                         M_RREADY
    , input  [AXI_WIDTH_DA-1:0]      M_RDATA
    , input                          M_RLAST
    , input  [AXI_WIDTH_ID-1:0]      M_RID
    , input  [3:0]                   M_RUSER
    , input  [1:0]                   M_RRESP
       
    , output                         M_AWVALID
    , input                          M_AWREADY
    , output  [AXI_WIDTH_AD-1:0]     M_AWADDR
    , output  [AXI_WIDTH_ID-1:0]     M_AWID
    , output  [7:0]                  M_AWLEN
    , output  [2:0]                  M_AWSIZE
    , output  [1:0]                  M_AWBURST
    , output  [1:0]                  M_AWLOCK
    , output  [3:0]                  M_AWCACHE
    , output  [2:0]                  M_AWPROT
    , output  [3:0]                  M_AWQOS
    , output  [3:0]                  M_AWREGION
    , output  [3:0]                  M_AWUSER
    
    , output                         M_WVALID
    , input                          M_WREADY
    , output  [AXI_WIDTH_DA-1:0]     M_WDATA
    , output  [AXI_WIDTH_DS-1:0]     M_WSTRB
    , output                         M_WLAST
    , output  [AXI_WIDTH_ID-1:0]     M_WID
    , output  [3:0]                  M_WUSER
    
    , input                          M_BVALID
    , output                         M_BREADY
    , input  [1:0]                   M_BRESP
    , input  [AXI_WIDTH_ID-1:0]      M_BID
    , input                          M_BUSER
    
    , output network_done
    , output network_done_led

);

`include "C:/Download/dma_conv/src/define.v"

//////////////////////////////////////////// fix me ////////////////////////////////////////////
wire                   w_conv_00;
wire                   w_conv_02;
wire                   w_done_00;  
wire                   w_done_02;
wire                   w_mac_en; 

reg                    r_mac_en;
reg                    r_mac_delay;   

assign w_mac_en     = (w_conv_00) && (((w_done_02) && (w_conv_02)) || (!w_conv_02));
////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////// test /////////////////////////////////////////////
reg [11:0]  r_cnt;
reg         r_done_02;

wire        w_stop;

assign  w_done_02   = r_done_02;

always @(posedge clk or negedge rstn)   begin
    if(!rstn)           begin
        r_cnt       <= 12'd0;
        r_done_02   <= 1'b1;
    end
        
    else if((w_conv_02) && (w_done_00))  begin
        if(r_cnt == 12'd3999)  begin
            r_cnt       <= 12'b0;
            r_done_02   <= 1'b1;
        end

        else                begin
            r_cnt       <= r_cnt + 1;
            r_done_02   <= 1'b0;
        end

    end

    else if(w_stop)  begin
        r_cnt       <= 6'd0;
        r_done_02   <= 1'b0;
    end

    else                begin
        r_cnt       <= 6'b0;
        r_done_02   <= 1'b1;
    end

end
////////////////////////////////////////////////////////////////////////////////////////////////

wire  [ADDR_WIDTH-7:0  ]  o_bram_addr_00[0:BUF_NUM-1];
wire  [DATA_WIDTH-1:0  ]  o_bram_data_00[0:BUF_NUM-1];
wire  [ADDR_WIDTH-8:0  ]  o_bram_addr_02[0:BUF_NUM-1];
wire  [BRAM_DATA_WD-1:0]  o_bram_data_02[0:BUF_NUM-1];
wire  [BUF_NUM-1:0     ]  o_bram_en_00;  
wire  [BUF_NUM-1:0     ]  o_bram_cs_00;
wire  [BUF_NUM-1:0     ]  o_bram_en_02;  
wire  [BUF_NUM-1:0     ]  o_bram_cs_02; 

//--------------------------------------------------------------------
// CNN Accelerator
//--------------------------------------------------------------------  
dma_conv_00  #(
    .AXI_WIDTH_AD(A),
    .AXI_WIDTH_ID(4),
    .AXI_WIDTH_DA(D),
    .AXI_WIDTH_DS(M),
    .MEM_BASE_ADDR(2048),
    .MEM_DATA_BASE_ADDR(2048)
)
u_dma_conv_00
(
    .clk(clk),
    .rstn(rstn),
       
    .i_ctrl_reg0(i_ctrl_reg0), // network_start // {debug_big(1), debug_buf_select(16), debug_buf_addr(9)}
    .i_ctrl_reg1(i_ctrl_reg1), // Read_address (INPUT)
    .i_ctrl_reg2(i_ctrl_reg2), // Write_address
    .i_ctrl_reg3(32'd0      ), // Reserved

    .i_end  (i_end),

////////////////////// fix me //////////////////////
    .i_done_00 (w_done_00),
    .i_done_02 (w_done_02),
    .o_stop    (w_stop),

    .o_conv_00 (w_conv_00),
    .o_conv_02 (w_conv_02),
////////////////////////////////////////////////////

    .o_bram_en          (o_bram_en_00       ),
    .o_bram_cs          (o_bram_cs_00       ),

    .o_bram_addr_00     (o_bram_addr_00[ 0] ),
    .o_bram_addr_01     (o_bram_addr_00[ 1] ),
    .o_bram_addr_02     (o_bram_addr_00[ 2] ),
    .o_bram_addr_03     (o_bram_addr_00[ 3] ),
    .o_bram_addr_04     (o_bram_addr_00[ 4] ),
    .o_bram_addr_05     (o_bram_addr_00[ 5] ),
    .o_bram_addr_06     (o_bram_addr_00[ 6] ),
    .o_bram_addr_07     (o_bram_addr_00[ 7] ),
    .o_bram_addr_08     (o_bram_addr_00[ 8] ),
    .o_bram_addr_09     (o_bram_addr_00[ 9] ),
    .o_bram_addr_10     (o_bram_addr_00[10] ),
    .o_bram_addr_11     (o_bram_addr_00[11] ),
    .o_bram_addr_12     (o_bram_addr_00[12] ),
    .o_bram_addr_13     (o_bram_addr_00[13] ),
    .o_bram_addr_14     (o_bram_addr_00[14] ),
    .o_bram_addr_15     (o_bram_addr_00[15] ),

    .o_bram_data_00     (o_bram_data_00[ 0] ),
    .o_bram_data_01     (o_bram_data_00[ 1] ),
    .o_bram_data_02     (o_bram_data_00[ 2] ),
    .o_bram_data_03     (o_bram_data_00[ 3] ),
    .o_bram_data_04     (o_bram_data_00[ 4] ),
    .o_bram_data_05     (o_bram_data_00[ 5] ),
    .o_bram_data_06     (o_bram_data_00[ 6] ),
    .o_bram_data_07     (o_bram_data_00[ 7] ),
    .o_bram_data_08     (o_bram_data_00[ 8] ),
    .o_bram_data_09     (o_bram_data_00[ 9] ),
    .o_bram_data_10     (o_bram_data_00[10] ),
    .o_bram_data_11     (o_bram_data_00[11] ),
    .o_bram_data_12     (o_bram_data_00[12] ),
    .o_bram_data_13     (o_bram_data_00[13] ),
    .o_bram_data_14     (o_bram_data_00[14] ),
    .o_bram_data_15     (o_bram_data_00[15] ),
    
    .M_ARVALID (M_ARVALID),
    .M_ARREADY (M_ARREADY),
    .M_ARADDR  (M_ARADDR ),
    .M_ARID    (M_ARID   ),
    .M_ARLEN   (M_ARLEN  ),
    .M_ARSIZE  (M_ARSIZE ),
    .M_ARBURST (M_ARBURST),
    .M_ARLOCK  (M_ARLOCK ),
    .M_ARCACHE (M_ARCACHE),
    .M_ARPROT  (M_ARPROT ),
    .M_ARQOS   (         ),
    .M_ARREGION(         ),
    .M_ARUSER  (         ),
    .M_RVALID  (M_RVALID ),
    .M_RREADY  (M_RREADY ),
    .M_RDATA   (M_RDATA  ),
    .M_RLAST   (M_RLAST  ),
    .M_RID     (M_RID    ),
    .M_RUSER   (         ),
    .M_RRESP   (M_RRESP  ),
    
    .M_AWVALID (M_AWVALID),
    .M_AWREADY (M_AWREADY),
    .M_AWADDR  (M_AWADDR ),
    .M_AWID    (M_AWID   ),
    .M_AWLEN   (M_AWLEN  ),
    .M_AWSIZE  (M_AWSIZE ),
    .M_AWBURST (M_AWBURST),
    .M_AWLOCK  (M_AWLOCK ),
    .M_AWCACHE (M_AWCACHE),
    .M_AWPROT  (M_AWPROT ),
    .M_AWQOS   (         ),
    .M_AWREGION(         ),
    .M_AWUSER  (         ),
    
    .M_WVALID  (M_WVALID ),
    .M_WREADY  (M_WREADY ),
    .M_WDATA   (M_WDATA  ),
    .M_WSTRB   (M_WSTRB  ),
    .M_WLAST   (M_WLAST  ),
    .M_WID     (M_WID    ),
    .M_WUSER   (         ),
    
    .M_BVALID  (M_BVALID ),
    .M_BREADY  (M_BREADY ),
    .M_BRESP   (M_BRESP  ),
    .M_BID     (M_BID    ),
    .M_BUSER   (         ),

    .mem_we    (mem_we   ),
    
    .network_done(network_done),
    .network_done_led(network_done_led)
    
);


//////////////////////////////////////// Grobal Buffer_A ////////////////////////////////////////

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A00(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[0]),     // enable for read address
    .addrb(w_oAddr[0]),     // input address for read
    .dob(w_iData[0]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[0]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 0]}),      // input address for write
    .wea(o_bram_en_00[0]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 0]})   // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A01(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[1]),     // enable for read address
    .addrb(w_oAddr[1]),     // input address for read
    .dob(w_iData[1]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[1]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 1]}),      // input address for write
    .wea(o_bram_en_00[1]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 1]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A02(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[2]),     // enable for read address
    .addrb(w_oAddr[2]),     // input address for read
    .dob(w_iData[2]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[2]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 2]}),      // input address for write
    .wea(o_bram_en_00[2]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 2]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A03(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[3]),     // enable for read address
    .addrb(w_oAddr[3]),     // input address for read
    .dob(w_iData[3]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[3]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 3]}),      // input address for write
    .wea(o_bram_en_00[3]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 3]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A04(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[4]),     // enable for read address
    .addrb(w_oAddr[4]),     // input address for read
    .dob(w_iData[4]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[4]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 4]}),      // input address for write
    .wea(o_bram_en_00[4]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 4]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A05(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[5]),     // enable for read address
    .addrb(w_oAddr[5]),     // input address for read
    .dob(w_iData[5]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[5]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 5]}),      // input address for write
    .wea(o_bram_en_00[5]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 5]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A06(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[6]),     // enable for read address
    .addrb(w_oAddr[6]),     // input address for read
    .dob(w_iData[6]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[6]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 6]}),      // input address for write
    .wea(o_bram_en_00[6]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 6]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A07(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[7]),     // enable for read address
    .addrb(w_oAddr[7]),     // input address for read
    .dob(w_iData[7]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[7]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 7]}),      // input address for write
    .wea(o_bram_en_00[7]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 7]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A08(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[8]),     // enable for read address
    .addrb(w_oAddr[8]),     // input address for read
    .dob(w_iData[8]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[8]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 8]}),      // input address for write
    .wea(o_bram_en_00[8]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 8]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A09(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[9]),     // enable for read address
    .addrb(w_oAddr[9]),     // input address for read
    .dob(w_iData[9]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[9]),      // enable for write address
    .addra({1'b0,o_bram_addr_00[ 9]}),      // input address for write
    .wea(o_bram_en_00[9]),      // input write enable
    .dia({96'b0, o_bram_data_00[ 9]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A10(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[10]),        // enable for read address
    .addrb(w_oAddr[10]),        // input address for read
    .dob(w_iData[10]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[10]),     // enable for write address
    .addra({1'b0,o_bram_addr_00[10]}),      // input address for write
    .wea(o_bram_en_00[10]),     // input write enable
    .dia({96'b0, o_bram_data_00[10]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A11(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[11]),        // enable for read address
    .addrb(w_oAddr[11]),        // input address for read
    .dob(w_iData[11]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[11]),     // enable for write address
    .addra({1'b0,o_bram_addr_00[11]}),      // input address for write
    .wea(o_bram_en_00[11]),     // input write enable
    .dia({96'b0, o_bram_data_00[11]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A12(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[12]),        // enable for read address
    .addrb(w_oAddr[12]),        // input address for read
    .dob(w_iData[12]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[12]),     // enable for write address
    .addra({1'b0,o_bram_addr_00[12]}),      // input address for write
    .wea(o_bram_en_00[12]),     // input write enable
    .dia({96'b0, o_bram_data_00[12]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A13(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[13]),        // enable for read address
    .addrb(w_oAddr[13]),        // input address for read
    .dob(w_iData[13]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[13]),     // enable for write address
    .addra({1'b0,o_bram_addr_00[13]}),      // input address for write
    .wea(o_bram_en_00[13]),     // input write enable
    .dia({96'b0, o_bram_data_00[13]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A14(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[14]),        // enable for read address
    .addrb(w_oAddr[14]),        // input address for read
    .dob(w_iData[14]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[14]),     // enable for write address
    .addra({1'b0,o_bram_addr_00[14]}),      // input address for write
    .wea(o_bram_en_00[14]),     // input write enable
    .dia({96'b0, o_bram_data_00[14]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_A15(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(w_oCs[15]),        // enable for read address
    .addrb(w_oAddr[15]),        // input address for read
    .dob(w_iData[15]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_00[15]),     // enable for write address
    .addra({1'b0,o_bram_addr_00[15]}),      // input address for write
    .wea(o_bram_en_00[15]),     // input write enable
    .dia({96'b0, o_bram_data_00[15]})       // input write data
);

////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////// Grobal Buffer_B ////////////////////////////////////////

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B00(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[0]),     // enable for read address
    .addrb(),//(w_oAddr[0]),     // input address for read
    .dob(),//(w_iData[0]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[0]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 0]}),      // input address for write
    .wea(o_bram_en_02[0]),      // input write enable
    .dia({o_bram_data_02[ 0]})   // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B01(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[1]),     // enable for read address
    .addrb(),//(w_oAddr[1]),     // input address for read
    .dob(),//(w_iData[1]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[1]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 1]}),      // input address for write
    .wea(o_bram_en_02[1]),      // input write enable
    .dia({o_bram_data_02[ 1]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B02(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[2]),     // enable for read address
    .addrb(),//(w_oAddr[2]),     // input address for read
    .dob(),//(w_iData[2]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[2]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 2]}),      // input address for write
    .wea(o_bram_en_02[2]),      // input write enable
    .dia({o_bram_data_02[ 2]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B03(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[3]),     // enable for read address
    .addrb(),//(w_oAddr[3]),     // input address for read
    .dob(),//(w_iData[3]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[3]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 3]}),      // input address for write
    .wea(o_bram_en_02[3]),      // input write enable
    .dia({o_bram_data_02[ 3]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B04(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[4]),     // enable for read address
    .addrb(),//(w_oAddr[4]),     // input address for read
    .dob(),//(w_iData[4]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[4]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 4]}),      // input address for write
    .wea(o_bram_en_02[4]),      // input write enable
    .dia({o_bram_data_02[ 4]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B05(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[5]),     // enable for read address
    .addrb(),//(w_oAddr[5]),     // input address for read
    .dob(),//(w_iData[5]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[5]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 5]}),      // input address for write
    .wea(o_bram_en_02[5]),      // input write enable
    .dia({o_bram_data_02[ 5]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B06(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[6]),     // enable for read address
    .addrb(),//(w_oAddr[6]),     // input address for read
    .dob(),//(w_iData[6]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[6]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 6]}),      // input address for write
    .wea(o_bram_en_02[6]),      // input write enable
    .dia({o_bram_data_02[ 6]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B07(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[7]),     // enable for read address
    .addrb(),//(w_oAddr[7]),     // input address for read
    .dob(),//(w_iData[7]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[7]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 7]}),      // input address for write
    .wea(o_bram_en_02[7]),      // input write enable
    .dia({o_bram_data_02[ 7]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B08(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[8]),     // enable for read address
    .addrb(),//(w_oAddr[8]),     // input address for read
    .dob(),//(w_iData[8]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[8]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 8]}),      // input address for write
    .wea(o_bram_en_02[8]),      // input write enable
    .dia({o_bram_data_02[ 8]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B09(    
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[9]),     // enable for read address
    .addrb(),//(w_oAddr[9]),     // input address for read
    .dob(),//(w_iData[9]),           // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[9]),      // enable for write address
    .addra({2'b0,o_bram_addr_02[ 9]}),      // input address for write
    .wea(o_bram_en_02[9]),      // input write enable
    .dia({o_bram_data_02[ 9]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B10(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[10]),        // enable for read address
    .addrb(),//(w_oAddr[10]),        // input address for read
    .dob(),//(w_iData[10]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[10]),     // enable for write address
    .addra({2'b0,o_bram_addr_02[10]}),      // input address for write
    .wea(o_bram_en_02[10]),     // input write enable
    .dia({o_bram_data_02[10]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B11(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[11]),        // enable for read address
    .addrb(),//(w_oAddr[11]),        // input address for read
    .dob(),//(w_iData[11]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[11]),     // enable for write address
    .addra({2'b0,o_bram_addr_02[11]}),      // input address for write
    .wea(o_bram_en_02[11]),     // input write enable
    .dia({o_bram_data_02[11]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B12(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[12]),        // enable for read address
    .addrb(),//(w_oAddr[12]),        // input address for read
    .dob(),//(w_iData[12]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[12]),     // enable for write address
    .addra({2'b0,o_bram_addr_02[12]}),      // input address for write
    .wea(o_bram_en_02[12]),     // input write enable
    .dia({o_bram_data_02[12]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B13(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[13]),        // enable for read address
    .addrb(),//(w_oAddr[13]),        // input address for read
    .dob(),//(w_iData[13]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[13]),     // enable for write address
    .addra({2'b0,o_bram_addr_02[13]}),      // input address for write
    .wea(o_bram_en_02[13]),     // input write enable
    .dia({o_bram_data_02[13]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B14(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[14]),        // enable for read address
    .addrb(),//(w_oAddr[14]),        // input address for read
    .dob(),//(w_iData[14]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[14]),     // enable for write address
    .addra({2'b0,o_bram_addr_02[14]}),      // input address for write
    .wea(o_bram_en_02[14]),     // input write enable
    .dia({o_bram_data_02[14]})       // input write data
);

dpram_wrapper #(.DW(128), .AW(9), .DEPTH(512))
dpram_512x128_B15(   
    .clk(clk),      // clock 

    //READ SIGNAL
    .enb(),//(w_oCs[15]),        // enable for read address
    .addrb(),//(w_oAddr[15]),        // input address for read
    .dob(),//(w_iData[15]),          // output read-out data

    //WRITE SIGNAL
    .ena(o_bram_cs_02[15]),     // enable for write address
    .addra({2'b0,o_bram_addr_02[15]}),      // input address for write
    .wea(o_bram_en_02[15]),     // input write enable
    .dia({o_bram_data_02[15]})       // input write data
);

////////////////////////////////////////////////////////////////////////////////////////////////


wire [127:0]    w_iData[0:15];
wire [8:0]      w_oAddr[0:15];
wire [15:0]     w_oCs;
wire [31:0]     w_oLayer_result;
wire            w_oLayer_vld;

layer00 layer00(
    .clk(clk),
    .rstn(rstn),
    .iStart (w_conv_00),

    .i_fromYolo(w_mac_en),

    .i_layerInfo(2'b00),

    .oLayer_result(w_oLayer_result),
    .oLayer_vld(w_oLayer_vld),

    .oColEnd(w_done_00),

    /*bram communicate signal*/
    .iData0(w_iData[0]),
    .iData1(w_iData[1]),
    .iData2(w_iData[2]),
    .iData3(w_iData[3]),
    .iData4(w_iData[4]),
    .iData5(w_iData[5]),
    .iData6(w_iData[6]),
    .iData7(w_iData[7]),
    .iData8(w_iData[8]),
    .iData9(w_iData[9]),
    .iData10(w_iData[10]),
    .iData11(w_iData[11]),
    .iData12(w_iData[12]),
    .iData13(w_iData[13]),
    .iData14(w_iData[14]),
    .iData15(w_iData[15]),

    .oAddr0(w_oAddr[0]),
    .oAddr1(w_oAddr[1]),
    .oAddr2(w_oAddr[2]),
    .oAddr3(w_oAddr[3]),
    .oAddr4(w_oAddr[4]),
    .oAddr5(w_oAddr[5]),
    .oAddr6(w_oAddr[6]),
    .oAddr7(w_oAddr[7]),
    .oAddr8(w_oAddr[8]),
    .oAddr9(w_oAddr[9]),
    .oAddr10(w_oAddr[10]),
    .oAddr11(w_oAddr[11]),
    .oAddr12(w_oAddr[12]),
    .oAddr13(w_oAddr[13]),
    .oAddr14(w_oAddr[14]),
    .oAddr15(w_oAddr[15]),

    .oCs(w_oCs)
);

dma_conv_02 dma_conv_02( 

    .i_clk(clk),
    .i_rstn(rstn),
    .i_cal_fin(w_oLayer_vld),

    .i_bram_data(w_oLayer_result),

    .o_bram_en(o_bram_en_02),
    .o_bram_cs(o_bram_cs_02),
    .o_bram_addr_00(o_bram_addr_02[ 0]),
    .o_bram_addr_01(o_bram_addr_02[ 1]),
    .o_bram_addr_02(o_bram_addr_02[ 2]),
    .o_bram_addr_03(o_bram_addr_02[ 3]),
    .o_bram_addr_04(o_bram_addr_02[ 4]),
    .o_bram_addr_05(o_bram_addr_02[ 5]),
    .o_bram_addr_06(o_bram_addr_02[ 6]),
    .o_bram_addr_07(o_bram_addr_02[ 7]),
    .o_bram_addr_08(o_bram_addr_02[ 8]),
    .o_bram_addr_09(o_bram_addr_02[ 9]),
    .o_bram_addr_10(o_bram_addr_02[10]),
    .o_bram_addr_11(o_bram_addr_02[11]),
    .o_bram_addr_12(o_bram_addr_02[12]),
    .o_bram_addr_13(o_bram_addr_02[13]),
    .o_bram_addr_14(o_bram_addr_02[14]),
    .o_bram_addr_15(o_bram_addr_02[15]),

    .o_bram_data_00(o_bram_data_02[ 0]),
    .o_bram_data_01(o_bram_data_02[ 1]),
    .o_bram_data_02(o_bram_data_02[ 2]),
    .o_bram_data_03(o_bram_data_02[ 3]),
    .o_bram_data_04(o_bram_data_02[ 4]),
    .o_bram_data_05(o_bram_data_02[ 5]),
    .o_bram_data_06(o_bram_data_02[ 6]),
    .o_bram_data_07(o_bram_data_02[ 7]),
    .o_bram_data_08(o_bram_data_02[ 8]),
    .o_bram_data_09(o_bram_data_02[ 9]),
    .o_bram_data_10(o_bram_data_02[10]),
    .o_bram_data_11(o_bram_data_02[11]),
    .o_bram_data_12(o_bram_data_02[12]),
    .o_bram_data_13(o_bram_data_02[13]),
    .o_bram_data_14(o_bram_data_02[14]),
    .o_bram_data_15(o_bram_data_02[15])

);


endmodule