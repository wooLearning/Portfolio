`timescale 1ns / 1ps

module tb_cam_inbuf_top;

    // ------------------------------------------------------------
    // 파라미터
    // ------------------------------------------------------------
    localparam IMG_W        = 480;
    localparam IMG_H        = 272;
    localparam ADDR_W       = 17;   // 480*272 = 130,560 < 2^17
    localparam DATA_W       = 16;   // RGB565
    localparam integer FRAME_PIXELS = IMG_W * IMG_H;

    // ------------------------------------------------------------
    // DUT 포트용 신호
    // ------------------------------------------------------------
    reg                  pclk;         // 카메라 PCLK (i_clk)
    reg                  clk_100M;     // CNN/Window 클럭 (i_clk_100M)
    reg                  rst_n;

    reg                  cam_vsync;    // VSYNC
    reg                  cam_hsync;    // HSYNC/HREF
    reg  [7:0]           cam_data;     // 8bit 카메라 데이터
    reg                  sw;           // camera_to_ram용 스위치 (고정 값)

    reg                  rd_en;        // 100MHz 도메인 read enable
    reg  [ADDR_W-1:0]    rd_addr;
    reg  [ADDR_W-1:0]    lcd_addr;
    wire [23:0]          rd_data;      // RGB888
    wire                 start;        // in_buf_ctrl에서 나오는 start

    // ------------------------------------------------------------
    // DUT 인스턴스
    // ------------------------------------------------------------
    cam_inbuf_top #(
        .DATA_W (DATA_W),
        .ADDR_W (ADDR_W)
    ) dut (
        // 카메라 도메인
        .i_clk        (pclk),
        .i_rst_n      (rst_n),

        .i_cam_vsync  (cam_vsync),
        .i_cam_hsync  (cam_hsync),
        .i_cam_data   (cam_data),
        .i_sw         (sw),

        // CNN/Window 도메인
        .i_clk_100M   (clk_100M),
        .i_rd_en      (rd_en),
        .i_rd_addr    (rd_addr),
        .i_lcd_addr   (lcd_addr),
        .o_rd_data    (rd_data),
        .o_start      (start)
    );

    // ------------------------------------------------------------
    // 클럭 생성
    //   - pclk: 20ns 주기 ≈ 50MHz (48MHz 근사)
    //   - clk_100M: 10ns 주기 = 100MHz
    // ------------------------------------------------------------
    initial begin
        pclk     = 1'b0;
        clk_100M = 1'b0;
    end

    always #10 pclk     = ~pclk;
    always #5  clk_100M = ~clk_100M;

    // ------------------------------------------------------------
    // 이미지 메모리 로드 (두 개 파일)
    //   image1.txt → img1_mem
    //   image2.txt → img2_mem
    //   각 파일은 16bit RGB565 한 줄당 한 픽셀, 총 480*272줄이라고 가정
    // ------------------------------------------------------------
    reg [15:0] img1_mem [0:FRAME_PIXELS-1];
    reg [15:0] img2_mem [0:FRAME_PIXELS-1];

    initial begin
        $readmemh("image1.txt", img1_mem);
        $readmemh("image2.txt", img2_mem);
    end

    // ------------------------------------------------------------
    // 초기화 / 리셋 / 메인 시퀀스
    // ------------------------------------------------------------
    initial begin
        // 초기값
        rst_n     = 1'b0;
        cam_vsync = 1'b0;
        cam_hsync = 1'b0;
        cam_data  = 8'd0;
        sw        = 1'b1;   // 필요 없으면 고정 0

        rd_en     = 1'b0;
        rd_addr   = {ADDR_W{1'b0}};
        lcd_addr   = {ADDR_W{1'b0}};

        // 리셋 유지
        repeat(10) @(posedge pclk);
        rst_n = 1'b1;

        // 리셋 해제 후 대기
        repeat(50) @(posedge pclk);

        // --------------------------------------------------------
        // Frame 0: image1.txt 사용
        // --------------------------------------------------------
        $display("[TB] Send Frame 0 from image1.txt");
        send_one_frame_from_mem(0);  // 0 → img1_mem 사용

        // 프레임 사이 적당히 대기
        repeat(1000) @(posedge pclk);

        // --------------------------------------------------------
        // Frame 1: image2.txt 사용
        // --------------------------------------------------------
        $display("[TB] Send Frame 1 from image2.txt");
        send_one_frame_from_mem(1);  // 1 → img2_mem 사용

         repeat(500) @(posedge clk_100M);
         
         

        // 1) 현재 읽기 뱅크에 image1이 있다고 가정
        compare_frame_with_image(0);  // image1.txt와 비교
        
         // 2) VSYNC 한번 토글해서 뱅크 전환 (예: toggle_vsync_only task 사용)
         
        // CDC 안정화
         repeat(500) @(posedge clk_100M);
         toggle_vsync_only();    
    
        // 3) 이제 읽기 뱅크에 image2가 있다고 가정
         compare_frame_with_image(1);  // image2.txt와 비교

        $display("[TB] Simulation done.");
        #1000;
        $finish;
    end

    // ------------------------------------------------------------
    // Task: 한 프레임 전송 (카메라 타이밍 포함)
    //  select_img:
    //    0 → img1_mem (image1.txt)
    //    1 → img2_mem (image2.txt)
    //
    //  - VSYNC High 100 PCLK
    //  - VSYNC Low 후 200 PCLK (vertical blank)
    //  - 각 라인:
    //      HSYNC=1 동안 480픽셀 (픽셀당 2클럭: 상위바이트, 하위바이트)
    //      라인 뒤 20클럭 HSYNC=0 (line blank)
    //  - 모든 라인 끝나면 200클럭 idle
    // ------------------------------------------------------------
    reg [15:0] pix;
    task send_one_frame_from_mem(input integer frame_id);
    integer x, y;
    integer idx;
    begin
        // 1) 프레임 시작 전 VSYNC=1로 충분히 유지 (카운터 리셋용)
        cam_vsync <= 1;
        cam_hsync <= 0;
        cam_data  <= 8'd0;
        repeat(100) @(posedge pclk);  // 100clk 정도 여유
    
        // 2) VSYNC=0 내려서 "프레임 시작"
        cam_vsync <= 0;
        repeat(200) @(posedge pclk);  // front porch
    
        idx = 0;
    
        // 3) 272 라인 전송
        for (y = 0; y < 272; y = y + 1) begin
            // 라인 유효 구간: HSYNC=1
            cam_hsync <= 1;
    
            for (x = 0; x < 480; x = x + 1) begin
                
                if (frame_id == 0)
                    pix = img1_mem[idx];
                else
                    pix = img2_mem[idx];
    
                // 상위 바이트
                cam_data <= pix[15:8];
                @(posedge pclk);
                // 하위 바이트
                cam_data <= pix[7:0];
                @(posedge pclk);
    
                idx = idx + 1;
            end
    
            // 4) 라인 끝: HSYNC 내려서 v_count++ 발생
            cam_hsync <= 0;
            repeat(20) @(posedge pclk);  // 라인 블랭크
        end
    
    
        // 프레임 사이 블랭크 추가 (선택)
        repeat(200) @(posedge pclk);
    end
    endtask

    
    task automatic toggle_vsync_only;
        begin
            // VSYNC High 구간 시작
            @(posedge pclk);
            cam_vsync <= 1'b1;
            cam_hsync <= 1'b0;   // 실제 라인 전송 없음
            cam_data  <= 8'd0;   // 데이터도 0으로 유지
        
            // 총 100클럭 동안 VSYNC High (위 @(posedge) 포함해서 100번)
            repeat(99) @(posedge pclk);
        
            // VSYNC Low로 내림
            cam_vsync <= 1'b0;
        
            // VSYNC Low 후 200클럭 idle (vertical blank처럼)
            repeat(200) @(posedge pclk);
        end
    endtask

    
    function automatic [23:0] rgb565_to_rgb888(input [15:0] d);
            reg [7:0] r8, g8, b8;
        begin
            // R: 5bit → 상위 3비트 복사해서 8bit
            r8 = {d[15:11], d[15:13]};
            // G: 6bit → 상위 2비트 복사해서 8bit
            g8 = {d[10:5],  d[10:9]};
            // B: 5bit → 상위 3비트 복사해서 8bit
            b8 = {d[4:0],   d[4:2]};
            rgb565_to_rgb888 = {r8, g8, b8};
        end
    endfunction 
    
    task automatic compare_frame_with_image(input integer which);
            integer i;
            reg [15:0] pix16;
            reg [23:0] expected_rgb888;
        begin
            rd_en = 1'b1;
        
            // 전체 픽셀 순회
            for (i = 0; i < FRAME_PIXELS; i = i + 1) begin
                // 1) 이번에 읽을 주소 세팅
                rd_addr = i[ADDR_W-1:0];
        
                // 2) 해당 주소가 BRAM에 래치되는 포즈엣지 대기
                repeat(2) @(posedge clk_100M);
        
                // 3) 한 틱 정도 늦게 rd_data 샘플 (BRAM이 dout 갱신할 시간)
                #1;
        
                // 4) 기대값 계산
                if (which == 0)
                    pix16 = img1_mem[i];
                else
                    pix16 = img2_mem[i];
        
                expected_rgb888 = rgb565_to_rgb888(pix16);
        
                // 5) 실제 값과 비교
                if (rd_data !== expected_rgb888) begin
                    $display("[%0t] ERROR: image%0d mismatch at pixel %0d: got=%h, expected=%h",
                             $time, which+1, i, rd_data, expected_rgb888);
                
                end
            end
        
            rd_en = 1'b0;
            $display("[%0t] INFO: image%0d check PASSED (all %0d pixels matched).",
                     $time, which+1, FRAME_PIXELS);
        end
        endtask

endmodule
