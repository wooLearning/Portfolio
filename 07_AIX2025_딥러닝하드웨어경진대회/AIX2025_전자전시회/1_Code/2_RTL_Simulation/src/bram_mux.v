//----------------------------------------------------------------------------------------------------------------+
//----------------------------------------------------------------------------------------------------------------+
// Project: AIX 2025
// Module: bram_ctrl_mux.v
// Description:
//      Address control module for CNN (Only read from RAM to Reg)
//
// History: 2025.05.15 
//----------------------------------------------------------------------------------------------------------------+

module bram_mux #(                           
    parameter ADDR_WIDTH        = 14,
    parameter BRAM_DATA_WD      = 32,
    parameter BUF_NUM           = 16,
    parameter CONV02            = 1'b0,
    parameter CONV04            = 1'b0    

) ( input   [ADDR_WIDTH-1:0  ]  i_bram_addr,
    input   [BRAM_DATA_WD-1:0]  i_bram_data,

    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_00,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_01,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_02,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_03,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_04,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_05,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_06,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_07,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_08,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_09,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_10,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_11,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_12,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_13,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_14,
    output  [ADDR_WIDTH-7:0  ]  o_bram_addr_15,

    output  [BRAM_DATA_WD-1:0]  o_bram_data_00,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_01,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_02,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_03,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_04,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_05,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_06,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_07,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_08,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_09,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_10,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_11,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_12,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_13,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_14,
    output  [BRAM_DATA_WD-1:0]  o_bram_data_15

);


//-----------------------------------------------------------------------------------------------------------------
// Define
//-----------------------------------------------------------------------------------------------------------------
    // Define Wire
    wire [3:0]  w_pixel_num;


//-----------------------------------------------------------------------------------------------------------------
// Assignment
//-----------------------------------------------------------------------------------------------------------------
    assign  w_pixel_num     = i_bram_addr[12:9];


//-----------------------------------------------------------------------------------------------------------------
// Operation
//-----------------------------------------------------------------------------------------------------------------
    // Operation configuration (o_bram_addr)
    assign o_bram_addr_00   = (w_pixel_num == 4'd0 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_01   = (w_pixel_num == 4'd1 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_02   = (w_pixel_num == 4'd2 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_03   = (w_pixel_num == 4'd3 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_04   = (w_pixel_num == 4'd4 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_05   = (w_pixel_num == 4'd5 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_06   = (w_pixel_num == 4'd6 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_07   = (w_pixel_num == 4'd7 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_08   = (w_pixel_num == 4'd8 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_09   = (w_pixel_num == 4'd9 ) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_10   = (w_pixel_num == 4'd10) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_11   = (w_pixel_num == 4'd11) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_12   = (w_pixel_num == 4'd12) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_13   = (w_pixel_num == 4'd13) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_14   = (w_pixel_num == 4'd14) ? i_bram_addr[7:0] : 8'b0;
    assign o_bram_addr_15   = (w_pixel_num == 4'd15) ? i_bram_addr[7:0] : 8'b0;


    // Operation configuration (o_bram_data)
    assign o_bram_data_00   = (w_pixel_num == 4'd0 ) ? i_bram_data : 32'b0;
    assign o_bram_data_01   = (w_pixel_num == 4'd1 ) ? i_bram_data : 32'b0;
    assign o_bram_data_02   = (w_pixel_num == 4'd2 ) ? i_bram_data : 32'b0;
    assign o_bram_data_03   = (w_pixel_num == 4'd3 ) ? i_bram_data : 32'b0;
    assign o_bram_data_04   = (w_pixel_num == 4'd4 ) ? i_bram_data : 32'b0;
    assign o_bram_data_05   = (w_pixel_num == 4'd5 ) ? i_bram_data : 32'b0;
    assign o_bram_data_06   = (w_pixel_num == 4'd6 ) ? i_bram_data : 32'b0;
    assign o_bram_data_07   = (w_pixel_num == 4'd7 ) ? i_bram_data : 32'b0;
    assign o_bram_data_08   = (w_pixel_num == 4'd8 ) ? i_bram_data : 32'b0;
    assign o_bram_data_09   = (w_pixel_num == 4'd9 ) ? i_bram_data : 32'b0;
    assign o_bram_data_10   = (w_pixel_num == 4'd10) ? i_bram_data : 32'b0;
    assign o_bram_data_11   = (w_pixel_num == 4'd11) ? i_bram_data : 32'b0;
    assign o_bram_data_12   = (w_pixel_num == 4'd12) ? i_bram_data : 32'b0;
    assign o_bram_data_13   = (w_pixel_num == 4'd13) ? i_bram_data : 32'b0;
    assign o_bram_data_14   = (w_pixel_num == 4'd14) ? i_bram_data : 32'b0;
    assign o_bram_data_15   = (w_pixel_num == 4'd15) ? i_bram_data : 32'b0;


endmodule