//----------------------------------------------------------------------------------------------------------------+
//----------------------------------------------------------------------------------------------------------------+
// Project: AIX 2025
// Module: bram_ctrl_top.v
// Description:
//      Address control module for CNN (Only read from RAM to Reg)
//
// History: 2025.04.09 
//----------------------------------------------------------------------------------------------------------------+

module bram_ctrl_top #(
    parameter AXI_WIDTH_AD          = 32,                           
    parameter ADDR_WIDTH            = 14,
    parameter BUF_NUM               = 16,
    parameter CONV02                = 1'b0,
    parameter CONV04                = 1'b0, 
    
    parameter BIT_TRANS             = 18,
    parameter AXI_WIDTH_ID          = 4,
    parameter AXI_WIDTH_DA          = 32,
    parameter AXI_WIDTH_DS          = AXI_WIDTH_DA/8,
    parameter OUT_BITS_TRANS        = 18,
    parameter AXI_WIDTH_USER        = 1,
    parameter WBUF_AW               = 9,
    parameter WBUF_DW               = 8*3*3*16,
    parameter WBUF_DS               = WBUF_DW/8,
    parameter MEM_BASE_ADDR         = 'h8000_0000,
    parameter MEM_DATA_BASE_ADDR    = 4096

) ( // bram_ctrl_wr
    input                           i_clk,
    input                           i_rstn,
    input                           i_start,   
    input                           i_end,  
    input                           i_restart,    
    input                           i_read_data_vld,
    input       [7:0]               i_read_data_cnt,

    input                           i_done_00,
    input                           i_done_02,

    // test
    output                          o_stop,

    output                          o_conv_00,
    output                          o_conv_02,
    output                          o_cal,
    output                          o_break,
    output      [BUF_NUM-1:0]       o_bram_en,
    output      [BUF_NUM-1:0]       o_bram_cs,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_00,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_01,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_02,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_03,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_04,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_05,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_06,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_07,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_08,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_09,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_10,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_11,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_12,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_13,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_14,
    output      [ADDR_WIDTH-7:0]    o_bram_addr_15,

    output      [AXI_WIDTH_DA-1:0]  o_bram_data_00,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_01,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_02,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_03,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_04,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_05,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_06,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_07,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_08,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_09,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_10,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_11,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_12,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_13,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_14,
    output      [AXI_WIDTH_DA-1:0]  o_bram_data_15,

    // axi_dam_ctrl     
    input [31:0]                    i_base_address_wr,
    input [BIT_TRANS-1:0]           i_num_trans,
    input [15:0]                    i_max_req_blk_idx,

    // DMA Read
    input                           i_read_done,
    output                          o_ctrl_read,
    output [31:0]                   o_read_addr,

    // DMA Write
    input                           i_write_done,
    input                           i_indata_req_wr,
    output                          o_ctrl_write,
    output [31:0]                   o_write_addr,
    output [BIT_TRANS-1:0]          o_write_data_cnt,
    output                          o_ctrl_write_done,

    // axi_dma_rd
    //Read address channel
    output                          M_ARVALID,  // address/control valid handshake
    input                           M_ARREADY,
    output  [AXI_WIDTH_AD-1:0]      M_ARADDR,   // Address Read 
    output  [AXI_WIDTH_ID-1:0]      M_ARID,     // Read addr ID
    output  [7:0]                   M_ARLEN,    // Transfer length
    output  [2:0]                   M_ARSIZE,   // Transfer width
    output  [1:0]                   M_ARBURST,  // Burst type
    output  [1:0]                   M_ARLOCK,   // Atomic access information
    output  [3:0]                   M_ARCACHE,  // Cachable/bufferable infor
    output  [2:0]                   M_ARPROT,   // Protection info
    output  [3:0]                   M_ARQOS,    // Quality of Service
    output  [3:0]                   M_ARREGION, // Region signaling
    output  [3:0]                   M_ARUSER,   // User defined signal
   
    //Read data channel
    input                           M_RVALID,   // Read data valid 
    output                          M_RREADY,   // Read data ready (to Slave)
    input   [AXI_WIDTH_DA-1:0]      M_RDATA,    // Read data bus
    input                           M_RLAST,    // Last beat of a burst transfer
    input   [AXI_WIDTH_ID-1:0]      M_RID,      // Read ID
    input   [3:0]                   M_RUSER,    // User defiend signal
    input   [1:0]                   M_RRESP,    // Read response

    //Functional Ports
    input                           start_dma,
    output [AXI_WIDTH_DA-1:0]       data_o,
    output                          data_vld_o,
    output     [BIT_TRANS-1:0]      data_cnt_o,
    output     [2:0]                r_cstate,
    output                          done_o

);
    wire [ADDR_WIDTH-1:0 ]  w_bram_addr;
    wire                    w_bram_en;
    assign o_bram_en = w_bram_en ? 16'hffff : 16'h0000; 

    bram_ctrl_wr    u_bram_ctrl (
        .i_clk              (i_clk              ),
        .i_rstn             (i_rstn             ),
        .i_start            (i_start            ),
        .i_end              (i_end              ),
        .i_restart          (i_restart          ),
        .i_rvalid           (M_RVALID           ),
        .i_read_done        (done_o             ),
        .i_read_data_vld    (i_read_data_vld    ),
        .i_read_data_cnt    (i_read_data_cnt    ),

        .i_done_00          (i_done_00          ),
        .i_done_02          (i_done_02          ),

        // test
        .o_stop             (o_stop             ),

        .o_conv_00          (o_conv_00          ),
        .o_conv_02          (o_conv_02          ),
        .o_cal              (o_cal              ),
        .o_break            (o_break            ),
        .o_bram_en          (w_bram_en          ),
        .o_bram_cs          (o_bram_cs          ),
        .o_bram_addr        (w_bram_addr        )

    );

    bram_mux        u_bram_mux  (   
        .i_bram_addr        (w_bram_addr        ),
        .i_bram_data        (data_o             ),

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
        .o_bram_data_15     (o_bram_data_15     )

    );

    axi_dma_rd  #(
        .BITS_TRANS     (BIT_TRANS),
        .OUT_BITS_TRANS (OUT_BITS_TRANS),    
        .AXI_WIDTH_USER (1),                // Master ID
        .AXI_WIDTH_ID   (4),                // ID width in bits
        .AXI_WIDTH_AD   (AXI_WIDTH_AD),     // address width
        .AXI_WIDTH_DA   (AXI_WIDTH_DA),     // data width
        .AXI_WIDTH_DS   (AXI_WIDTH_DS)      // data strobe width

    )    u_axi_dma_rd (
        .clk                (i_clk              ),
        .rstn               (i_rstn             ),

        //Read address channel
        .M_ARVALID          (M_ARVALID          ),      // address/control valid handshake
        .M_ARREADY          (M_ARREADY          ),      // Read addr ready
        .M_ARADDR           (M_ARADDR           ),      // Address Read 
        .M_ARID             (M_ARID             ),      // Read addr ID
        .M_ARLEN            (M_ARLEN            ),      // Transfer length
        .M_ARSIZE           (M_ARSIZE           ),      // Transfer width
        .M_ARBURST          (M_ARBURST          ),      // Burst type
        .M_ARLOCK           (M_ARLOCK           ),      // Atomic access information
        .M_ARCACHE          (M_ARCACHE          ),      // Cachable/bufferable infor
        .M_ARPROT           (M_ARPROT           ),      // Protection info
        .M_ARQOS            (M_ARQOS            ),      // Quality of Service
        .M_ARREGION         (M_ARREGION         ),      // Region signaling
        .M_ARUSER           (M_ARUSER           ),      // User defined signal
    
        //Read data channel
        .M_RVALID           (M_RVALID           ),      // Read data valid 
        .M_RREADY           (M_RREADY           ),      // Read data ready (to Slave)
        .M_RDATA            (M_RDATA            ),      // Read data bus
        .M_RLAST            (M_RLAST            ),      // Last beat of a burst transfer
        .M_RID              (M_RID              ),      // Read ID
        .M_RUSER            (M_RUSER            ),      // User defined signal
        .M_RRESP            (M_RRESP            ),      // Read response
        
        //Functional Ports
        .i_break            (o_break            ),
        .start_dma          (start_dma          ),
        .num_trans          (i_num_trans        ),                                     
        .start_addr         (o_read_addr        ),
        .data_o             (data_o             ),
        .data_vld_o         (data_vld_o         ),
        .data_cnt_o         (data_cnt_o         ),
        .done_o             (done_o             )

    );

    axi_dma_ctrl    #(
        .BIT_TRANS(BIT_TRANS)

    )
    u_axi_dma_ctrl  (
        .clk                (i_clk              ), 
        .rstn               (i_rstn             ),
        .i_start            (i_start            ),
        .i_base_address_rd  (32'b0              ),
        .i_base_address_wr  (i_base_address_wr  ),
        .i_num_trans        (i_num_trans        ),                                       
        .i_max_req_blk_idx  (i_max_req_blk_idx  ),
    
        // DMA Read
        .i_read_done        (done_o             ),
        .o_ctrl_read        (start_dma          ),
        .o_read_addr        (o_read_addr        ),
    
        // DMA Write
        .i_write_done       (i_write_done       ),
        .i_indata_req_wr    (i_indata_req_wr    ),
        .o_ctrl_write       (o_ctrl_write       ),
        .o_write_addr       (o_write_addr       ),
        .o_write_data_cnt   (o_write_data_cnt   ),
        .o_ctrl_write_done  (o_ctrl_write_done  )

    );

    
endmodule