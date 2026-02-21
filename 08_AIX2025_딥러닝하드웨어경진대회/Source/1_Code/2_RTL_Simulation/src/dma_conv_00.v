//----------------------------------------------------------------+
// Project: AIX 2025
// Module: dma_conv_00.v
// Description:
//      Load parameters and input feature map from DRAM via AXI4
//
// History: 2025.05.15 
//----------------------------------------------------------------+

module dma_conv_00  #(
    parameter AXI_WIDTH_AD       = 32,
    parameter AXI_WIDTH_ID       = 4,
    parameter AXI_WIDTH_DA       = 32,
    parameter AXI_WIDTH_DS       = AXI_WIDTH_DA/8,
    parameter OUT_BITS_TRANS     = 18,
    parameter ADDR_WIDTH         = 14,
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
    , output                         o_cal
    , output                         o_break
    , output [15:0]                  o_bram_en
    , output [15:0]                  o_bram_cs
    , input                          mem_we

    , input                          i_done_00
    , input                          i_done_02

    // test
    , output                         o_stop

    , output                         o_conv_00
    , output                         o_conv_02
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_00
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_01
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_02
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_03
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_04
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_05
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_06
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_07
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_08
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_09
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_10
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_11
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_12
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_13
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_14
    , output [ADDR_WIDTH-7:0 ]       o_bram_addr_15

    , output [AXI_WIDTH_DA-1:0]      o_bram_data_00
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_01
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_02
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_03
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_04
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_05
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_06
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_07
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_08
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_09
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_10
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_11
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_12
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_13
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_14
    , output [AXI_WIDTH_DA-1:0]      o_bram_data_15
    
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

`include "define.v"

parameter BUFF_DEPTH    = 256;
parameter BUFF_ADDR_W   = $clog2(BUFF_DEPTH);
localparam BIT_TRANS    = BUFF_ADDR_W;

//CSR
reg ap_start;
reg ap_ready;
reg ap_done;
reg interrupt;

reg [31:0]              dram_base_addr_rd;
reg [31:0]              dram_base_addr_wr;
reg [31:0]              reserved_register;

// Signals for dma read  
wire ctrl_read;
wire read_done;
wire [AXI_WIDTH_AD-1:0] read_addr;
wire [AXI_WIDTH_DA-1:0] read_data;
wire                    read_data_vld;
wire [BIT_TRANS   -1:0] read_data_cnt;

// Signals for dma write
wire                    ctrl_write_done;
wire                    ctrl_write;
wire                    write_done;
wire                    indata_req_wr;
wire [BIT_TRANS   -1:0] write_data_cnt;
wire [AXI_WIDTH_AD-1:0] write_addr;
wire [AXI_WIDTH_DA-1:0] write_data;

// FIX ME
wire [BIT_TRANS   -1:0] num_trans       = 16;           // BURST_LENGTH = 16
wire [            15:0] max_req_blk_idx = (256*256)/16; // The number of blocks

reg          r_restart;
wire         w_restart;

assign       w_restart = (i_done_00) && (((o_conv_02) && (i_done_02)) || (!o_conv_02));

// Operation configuration (r_restart)
always@ (posedge clk or negedge rstn)  begin
    if(!rstn)  
        r_restart   <= 1'b0;

    else if(w_restart)
        r_restart   <= 1'b1;

    else 
        r_restart   <= 1'b0;
 
end



//----------------------------------------------------------------
// Control signals
//----------------------------------------------------------------
always @ (*) begin
    ap_done     = ctrl_write_done;
    ap_ready    = 1;

end

assign network_done     = interrupt;
assign network_done_led = interrupt;

always @ (posedge clk, negedge rstn) begin
    if(~rstn) 
        ap_start <= 0;

    else begin 
        if(!ap_start && i_ctrl_reg0[0])
            ap_start <= 1;

        else if (ap_done)
            ap_start <= 0;    

    end 

end

always @(posedge clk, negedge rstn) begin
    if(~rstn) 
        interrupt <= 0;
    
    else begin        
        if(i_ctrl_reg0[0])
            interrupt <= 0;   

        else if (ap_done)
            interrupt <= 1;   

    end

end

// Parse the control registers
always @ (posedge clk, negedge rstn) begin
    if(~rstn) begin
        dram_base_addr_rd <= 0;
        dram_base_addr_wr <= 0;
        reserved_register <= 0;               // unused 

    end

    else begin 
        if(!ap_start && i_ctrl_reg0[0]) begin 
            dram_base_addr_rd <= i_ctrl_reg1; // Base Address for READ  (Input image, Model parameters)
            dram_base_addr_wr <= i_ctrl_reg2; // Base Address for WRITE (Intermediate feature maps, Outputs)
            reserved_register <= i_ctrl_reg3; // reserved

        end 

        else if (ap_done) begin 
            dram_base_addr_rd <= 0;
            dram_base_addr_wr <= 0;
            reserved_register <= 0; 

        end 

    end 

end

bram_ctrl_top #(

)
u_bram_ctrl_top(
    .i_clk              (clk),
    .i_rstn             (rstn),
    .i_start            (i_ctrl_reg0[0]   ),
    .i_end              (i_end),
    .i_restart          (r_restart),
    .i_read_data_vld    (read_data_vld),
    .i_read_data_cnt    (read_data_cnt),

    .i_done_00          (i_done_00          ),
    .i_done_02          (i_done_02          ),

    // test
    .o_stop             (o_stop),

    .o_conv_00          (o_conv_00          ),
    .o_conv_02          (o_conv_02          ),
    .o_cal              (o_cal),
    .o_break            (o_break),
    .o_bram_en          (o_bram_en),
    .o_bram_cs          (o_bram_cs),

    .o_bram_addr_00     (o_bram_addr_00     ),
    .o_bram_addr_01     (o_bram_addr_01     ),
    .o_bram_addr_02     (o_bram_addr_02     ),
    .o_bram_addr_03     (o_bram_addr_03     ),
    .o_bram_addr_04     (o_bram_addr_04     ),
    .o_bram_addr_05     (o_bram_addr_05     ),
    .o_bram_addr_06     (o_bram_addr_06     ),
    .o_bram_addr_07     (o_bram_addr_07     ),
    .o_bram_addr_08     (o_bram_addr_08     ),
    .o_bram_addr_09     (o_bram_addr_09     ),
    .o_bram_addr_10     (o_bram_addr_10     ),
    .o_bram_addr_11     (o_bram_addr_11     ),
    .o_bram_addr_12     (o_bram_addr_12     ),
    .o_bram_addr_13     (o_bram_addr_13     ),
    .o_bram_addr_14     (o_bram_addr_14     ),
    .o_bram_addr_15     (o_bram_addr_15     ),

    .o_bram_data_00     (o_bram_data_00     ),
    .o_bram_data_01     (o_bram_data_01     ),
    .o_bram_data_02     (o_bram_data_02     ),
    .o_bram_data_03     (o_bram_data_03     ),
    .o_bram_data_04     (o_bram_data_04     ),
    .o_bram_data_05     (o_bram_data_05     ),
    .o_bram_data_06     (o_bram_data_06     ),
    .o_bram_data_07     (o_bram_data_07     ),
    .o_bram_data_08     (o_bram_data_08     ),
    .o_bram_data_09     (o_bram_data_09     ),
    .o_bram_data_10     (o_bram_data_10     ),
    .o_bram_data_11     (o_bram_data_11     ),
    .o_bram_data_12     (o_bram_data_12     ),
    .o_bram_data_13     (o_bram_data_13     ),
    .o_bram_data_14     (o_bram_data_14     ),
    .o_bram_data_15     (o_bram_data_15     ),

    //.i_base_address_rd (dram_base_addr_rd),
    .i_base_address_wr (dram_base_addr_wr),
    .i_num_trans       (16        ),
    .i_max_req_blk_idx (max_req_blk_idx  ),
 
    // DMA Read
    .i_read_done       (read_done        ),
    .o_ctrl_read       (ctrl_read        ),
    .o_read_addr       (read_addr        ),
 
    // DMA Write
    .i_indata_req_wr   (indata_req_wr    ),
    .i_write_done      (write_done       ),
    .o_ctrl_write      (ctrl_write       ),
    .o_write_addr      (write_addr       ),
    .o_write_data_cnt  (write_data_cnt   ),
    .o_ctrl_write_done (ctrl_write_done  ),

    .M_ARVALID  (M_ARVALID  ),            // address/control valid handshake   
    .M_ARREADY  (M_ARREADY    ),            // Read addr ready
    .M_ARADDR   (M_ARADDR     ),            // Address Read 
    .M_ARID     (M_ARID       ),            // Read addr ID
    .M_ARLEN    (M_ARLEN      ),            // Transfer length
    .M_ARSIZE   (M_ARSIZE     ),            // Transfer width
    .M_ARBURST  (M_ARBURST    ),            // Burst type
    .M_ARLOCK   (M_ARLOCK     ),            // Atomic access information
    .M_ARCACHE  (M_ARCACHE    ),            // Cachable/bufferable infor
    .M_ARPROT   (M_ARPROT     ),            // Protection info
    .M_ARQOS    (M_ARQOS      ),            // Quality of Service
    .M_ARREGION (M_ARREGION   ),            // Region signaling
    .M_ARUSER   (M_ARUSER     ),            // User defined signal

    //Read data channel
    .M_RVALID   (M_RVALID     ),            // Read data valid 
    .M_RREADY   (M_RREADY     ),            // Read data ready (to Slave)
    .M_RDATA    (M_RDATA      ),            // Read data bus
    .M_RLAST    (M_RLAST      ),            // Last beat of a burst transfer
    .M_RID      (M_RID        ),            // Read ID
    .M_RUSER    (M_RUSER      ),            // User defined signal
    .M_RRESP    (M_RRESP      ),            // Read response
    
    //Functional Ports
    .start_dma  (ctrl_read    ),
    .data_o     (read_data    ),
    .data_vld_o (read_data_vld),
    .data_cnt_o (read_data_cnt),
    .done_o     (read_done    )

);

// DMA write module
axi_dma_wr #(
        .BITS_TRANS(BIT_TRANS),
        .OUT_BITS_TRANS(BIT_TRANS),    
        .AXI_WIDTH_USER(1),                 // Master ID
        .AXI_WIDTH_ID(4),                   // ID width in bits
        .AXI_WIDTH_AD(AXI_WIDTH_AD),        // address width
        .AXI_WIDTH_DA(AXI_WIDTH_DA),        // data width
        .AXI_WIDTH_DS(AXI_WIDTH_DS)         // data strobe width
    )
u_dma_write(
    .M_AWID     (M_AWID     ),              // Address ID
    .M_AWADDR   (M_AWADDR   ),              // Address Write
    .M_AWLEN    (M_AWLEN    ),              // Transfer length
    .M_AWSIZE   (M_AWSIZE   ),              // Transfer width
    .M_AWBURST  (M_AWBURST  ),              // Burst type
    .M_AWLOCK   (M_AWLOCK   ),              // Atomic access information
    .M_AWCACHE  (M_AWCACHE  ),              // Cachable/bufferable infor
    .M_AWPROT   (M_AWPROT   ),              // Protection info
    .M_AWREGION (M_AWREGION ),
    .M_AWQOS    (M_AWQOS    ),
    .M_AWVALID  (M_AWVALID  ),              // address/control valid handshake
    .M_AWREADY  (M_AWREADY  ),
    .M_AWUSER   (           ),

    //Write data channel
    .M_WID      (M_WID      ),              // Write ID
    .M_WDATA    (M_WDATA    ),              // Write Data bus
    .M_WSTRB    (M_WSTRB    ),              // Write Data byte lane strobes
    .M_WLAST    (M_WLAST    ),              // Last beat of a burst transfer
    .M_WVALID   (M_WVALID   ),              // Write data valid
    .M_WREADY   (M_WREADY   ),              // Write data ready
    .M_WUSER    (           ),
    .M_BUSER    (           ),   

    //Write response chaDnel
    .M_BID      (M_BID      ),              // buffered response ID
    .M_BRESP    (M_BRESP    ),              // Buffered write response
    .M_BVALID   (M_BVALID   ),              // Response info valid
    .M_BREADY   (M_BREADY   ),              // Response info ready (to slave)

    //Read address channDl
    //User interface
    .start_dma  (ctrl_write     ),
    .num_trans  (num_trans      ),          //Number of words transferred
    .start_addr (write_addr     ),
    .indata     (write_data     ),
    .indata_req_o(indata_req_wr ),
    .done_o     (write_done     ),          //Blk transfer done
    .fail_check (               ),

    //User signals
    .clk        (clk            ),
    .rstn       (rstn           )

);

    
endmodule