`timescale 1ns / 1ps

// 카메라 → camera_to_ram → in_buf_ctrl 까지 한 번에 묶는 상위 DUT
module cam_inbuf_top #(
    parameter DATA_W = 16,
    parameter ADDR_W = 17      // 480*272 = 130,560
)(
    //==============================
    // 1) 카메라 / PCLK 도메인
    //==============================
    input  wire                 i_clk,         // PCLK (48MHz 근처)
    input  wire                 i_rst_n,

    input  wire                 i_cam_vsync,   // 센서 VSYNC
    input  wire                 i_cam_hsync,   // 센서 HSYNC/HREF
    input  wire [7:0]           i_cam_data,    // 센서 8bit 데이터
    input  wire                 i_sw,

    //==============================
    // 2) CNN / Window (100MHz) 도메인
    //==============================
    input  wire                 i_clk_100M,    // 100MHz
    input  wire                 i_rd_en,
    input  wire [ADDR_W-1:0]    i_rd_addr,
    input  wire [ADDR_W-1:0]    i_lcd_addr,
    output wire [23:0]          o_rd_data,     // RGB888
    output wire                 o_start        // in_buf_ctrl에서 나오는 start
);

    //==============================================================
    // 내부 연결 신호 (camera_to_ram → in_buf_ctrl)
    //==============================================================
    wire                 w_ram_wr_en;
    wire [ADDR_W-1:0]    w_ram_wr_addr;
    wire [DATA_W-1:0]    w_ram_wr_data;

    //==============================================================
    // 1. 카메라 8bit 스트림 → RAM write 제어 (camera_to_ram)
    //==============================================================
    camera_to_ram u_cam2ram (
        .clk_i         (i_clk),
        .sw_i          (i_sw),
        .cam_vsync_i   (i_cam_vsync),
        .cam_hsync_i   (i_cam_hsync),
        .cam_data_i    (i_cam_data),

        .ram_wr_en_o   (w_ram_wr_en),
        .ram_wr_addr_o (w_ram_wr_addr),
        .ram_wr_data_o (w_ram_wr_data)
    );

    //==============================================================
    // 2. Ping-Pong Input Buffer (in_buf_ctrl)
    //    - VSYNC으로 bank toggle
    //    - camera_to_ram이 만든 write 신호 사용
    //==============================================================
    in_buf_ctrl #(
        .DATA_W (DATA_W),
        .ADDR_W (ADDR_W)
    ) u_inbuf (
        .i_clk        (i_clk),
        .i_clk_100M   (i_clk_100M),
        .i_rst_n      (i_rst_n),

        // 카메라 write 인터페이스
        .i_cam_vsync  (i_cam_vsync),      // VSYNC 그대로 사용
        .i_wr_en      (w_ram_wr_en),
        .i_wr_addr    (w_ram_wr_addr),
        .i_wr_data    (w_ram_wr_data),

        // Window/CNN read 인터페이스
        .i_rd_en      (i_rd_en),
        .i_rd_addr    (i_rd_addr),
        .i_Lcd_addr   (i_lcd_addr),
        .o_rd_data    (o_rd_data),
        .start        (o_start)
    );

endmodule