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
    //reg                  sw;           // camera_to_ram용 스위치 (고정 값)

    //reg                  rd_en;        // 100MHz 도메인 read enable
    //reg  [ADDR_W-1:0]    rd_addr;
    //reg  [ADDR_W-1:0]    lcd_addr;
    //wire [23:0]          rd_data;      // RGB888
    //wire                 start;        // in_buf_ctrl에서 나오는 start

    //output wire
    wire  [ 4:0] oRgbR;
    wire  [ 5:0] oRgbG;
    wire  [ 4:0] oRgbB;
    wire  wTFT_DCLK;
    wire  wTFT_BACKLIGHT;
    wire  wTFT_DE;
    wire  wTFT_HSYNC;
    wire  wTFT_VSYNC;
    wire  wCAMERA_PWDN;
    wire  wCAMERA_MCLK;

    wire [15:0] oRGBCom = {oRgbR, oRgbG, oRgbB};
    // ------------------------------------------------------------
    // DUT 인스턴스
    // ------------------------------------------------------------
    // cam_inbuf_top #(
    //     .DATA_W (DATA_W),
    //     .ADDR_W (ADDR_W)
    // ) dut (
    //     // 카메라 도메인
    //     .i_clk        (pclk),
    //     .i_rst_n      (rst_n),

    //     .i_cam_vsync  (cam_vsync),
    //     .i_cam_hsync  (cam_hsync),
    //     .i_cam_data   (cam_data),
    //     .i_sw         (sw),

    //     // CNN/Window 도메인
    //     .i_clk_100M   (clk_100M),
    //     .i_rd_en      (rd_en),
    //     .i_rd_addr    (rd_addr),
    //     .i_lcd_addr   (lcd_addr),
    //     .o_rd_data    (rd_data),
    //     .o_start      (start)
    // );
    
    top u_top(

        .PL_CLK_100MHZ(clk_100M),//input
        .RstButton(rst_n),//input
        .CAMERA_SCCB_SCL(),//inout
        .CAMERA_SCCB_SDA(),//inout

        .TFT_B_DATA(oRgbB),//output
        .TFT_G_DATA(oRgbG),//output
        .TFT_R_DATA(oRgbR),//output
        .TFT_DCLK(wTFT_DCLK),//output
        .TFT_BACKLIGHT(wTFT_BACKLIGHT),//output
        .TFT_DE(wTFT_DE),//output
        .TFT_HSYNC(wTFT_HSYNC),//output
        .TFT_VSYNC(wTFT_VSYNC),//output

        .CAMERA_PCLK(pclk),//input
        .CAMERA_DATA(cam_data),//input  wire [ 7:0]    

        .CAMERA_RESETn(),//output

        .CAMERA_HSYNC(cam_hsync),//input
        .CAMERA_VSYNC(cam_vsync),//input

        .CAMERA_PWDN(wCAMERA_PWDN),//output
        .CAMERA_MCLK(wCAMERA_MCLK),//output

        // axi lite interface
        .iReg0(32'b0),//default sharpen filter
        .iReg1(32'b0),
        .iReg2(32'b0),
        .iReg3(32'b0)
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

    reg [15:0] img1_out [0:FRAME_PIXELS-1];
    reg [15:0] img2_out [0:FRAME_PIXELS-1];

    reg flag;//0 is pass, 1 is failed 

    reg [1:0] rComNum; //1 : frame1 비교 2 : frame2 비교

    initial begin
        $readmemh("C:/Users/user/Desktop/AdvancedProject/hw16_realfinal/cam_simul/testbench/image1.txt", img1_mem);
        $readmemh("C:/Users/user/Desktop/AdvancedProject/hw16_realfinal/cam_simul/testbench/image2.txt", img2_mem);
        $readmemh("C:/Users/user/Desktop/AdvancedProject/hw16_realfinal/cam_simul/testbench/image1_565.txt", img1_out);
        $readmemh("C:/Users/user/Desktop/AdvancedProject/hw16_realfinal/cam_simul/testbench/image2_565.txt", img2_out);
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
        flag = 0;
        rComNum = 0;
        //sw        = 1'b1;   // 필요 없으면 고정 0

        //rd_en     = 1'b0;
        //rd_addr   = {ADDR_W{1'b0}};
        //lcd_addr   = {ADDR_W{1'b0}};

        // 리셋 유지
        repeat(10) @(posedge pclk);
        rst_n = 1'b1;

        // 리셋 해제 후 대기
        repeat(50) @(posedge pclk);

        //시나리오 1
        //case1();
       //시나리오 2
        case2();
    end

    
    reg task2_en;
    task case1;
    begin
        task2_en = 0;
        $display("Case1 Start");
        //send_one_frame_from_mem(1);
        $display("send frame1"); 
        send_one_frame_from_mem(0); 
        $display("Send Done");
        fork : WAIT_OR_TIMEOUT
            begin : WAIT_BLOCK
                wait (u_top.u_cnn_top.u_LcdCtrl_RGB565.cur_state == 1);
                $display("[OK] LCD_READ entered at %t", $time);
                disable WAIT_OR_TIMEOUT; 
            end

            begin : TIMEOUT_BLOCK
                #100000000;
                $display("[TIMEOUT] CASE1 at %t", $time);
                $stop; // 또는 $finish
                disable WAIT_OR_TIMEOUT;   // (여기까지 오면 stop 때문에 사실상 의미는 덜하지만 습관적으로 둠)
            end
        join
        $display("Send Frame2");
        send_one_frame_from_mem(1); 
        $display("Send Frame2 Done");
        repeat(130560) @(posedge pclk);
        $stop;
    end
    endtask
    
    task case2;
    begin
        task2_en = 1;
        rhsync_delay = 0;
        $display("Case2 Start");
        $display("send frame1");
        send_one_frame_from_mem(0); 
        $display("Send Done");
        fork : WAIT_OR_TIMEOUT
            begin : WAIT_BLOCK
                wait (u_top.u_cnn_top.u_LcdCtrl_RGB565.cur_state == 1);
                wait (u_top.u_cnn_top.u_LcdCtrl_RGB565.cur_state == 0);
                $display("[OK] LCD_READ entered at %t", $time);
                disable WAIT_OR_TIMEOUT; 
            end
            begin : TIMEOUT_BLOCK
                #100000000;
                $display("[TIMEOUT] CASE2 at %t", $time);
                $stop; // 또는 $finish
                disable WAIT_OR_TIMEOUT; 
            end
        join
        rComNum = 1; rCnt = 2;
        $display("send frame2");
        send_one_frame_from_mem(1);
        $display("Send Done");
        fork : WAIT_OR_TIMEOUT1
            begin : WAIT_BLOCK1
                wait (u_top.u_cnn_top.u_LcdCtrl_RGB565.cur_state == 1);
                wait (u_top.u_cnn_top.u_LcdCtrl_RGB565.cur_state == 0);
                $display("[OK] LCD_READ entered at %t", $time);
                disable WAIT_OR_TIMEOUT1; 
            end
            begin : TIMEOUT_BLOCK1
                #100000000;
                $display("[TIMEOUT] CASE2 at %t", $time);
                $stop; // 또는 $finish
                disable WAIT_OR_TIMEOUT1; 
            end
        join 
        toggle_vsync_only();
        rComNum = 2;
        rCnt = 2;
        wait(rCnt == 0);
        if(flag==0) $display("TB Succeed");
        $stop;

    end
    endtask

    //for task2 compare logic 
    reg [1:0] rhsync_delay;
    reg [1:0] rCnt;//
    //cnn result compare
    always @(posedge wTFT_DCLK) begin
        if(task2_en) begin //only task2 logic
            if(!(wTFT_HSYNC && u_top.u_cnn_top.u_LcdCtrl_RGB565.hsync)) begin
                rhsync_delay <= 0;
            end
            else if(rhsync_delay >=3) begin
                rhsync_delay <= rhsync_delay;
            end
            else if(wTFT_HSYNC) begin
                rhsync_delay <= rhsync_delay + 1;
            end
        

            case (rComNum)
                1 : begin
                    if(wTFT_HSYNC && rhsync_delay >=3 && u_top.u_cnn_top.u_LcdCtrl_RGB565.hsync) begin//bram latency 2 + reg 1
                        if(img1_out[u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr-3] != oRGBCom) begin
                            $display("expected %h ,, real : %h ,,addr = %d ",
                            img1_out[u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr-3],oRGBCom,
                            u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr);
                            $display("TB FAILED %t",$time);
                            flag = 1;
                            $stop;
                        end
                    end
                    else begin
                        if(u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr == 130560) begin
                            if(rCnt >= 1) begin // left 2 compare
                                if(img1_out[u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr-rCnt] != oRGBCom) begin 
                                    $display("expected %h ,, real : %h ,,addr = %d ",
                                    img1_out[u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr-rCnt],oRGBCom,
                                    u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr);
                                    $display("TB FAILED %t",$time);
                                    flag = 1;
                                    $stop;
                                end
                                rCnt <= rCnt - 1;
                            end
                        end
                    end
                end
                2 : begin
                    if(wTFT_HSYNC && rhsync_delay >=3 && u_top.u_cnn_top.u_LcdCtrl_RGB565.hsync) begin//bram latency 2 + reg 1
                        if(img2_out[u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr-3] != oRGBCom) begin
                            $display("expected %h ,, real : %h ,,addr = %d ",
                            img2_out[u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr-3],oRGBCom,
                            u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr);
                            $display("TB FAILED %t",$time);
                            flag = 1;
                            $stop;
                        end
                    end
                    else begin // left 2 compare
                        if(u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr == 130560) begin 
                            if(rCnt >= 1) begin
                                if(img2_out[u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr-rCnt] != oRGBCom) begin
                                    $display("expected %h ,, real : %h ,,addr = %d ",
                                    img2_out[u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr-rCnt],oRGBCom,
                                    u_top.u_cnn_top.u_LcdCtrl_RGB565.oRamRdAddr);
                                    $display("TB FAILED %t",$time);
                                    flag = 1;
                                    $stop;
                                end
                                rCnt <= rCnt - 1;
                            end
                        end
                    end
                end 
            endcase
        end
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
    
    task inbuf_test;
    begin
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
        //compare_frame_with_image(0);  // image1.txt와 비교
        
         // 2) VSYNC 한번 토글해서 뱅크 전환 (예: toggle_vsync_only task 사용)
         
        // CDC 안정화
        repeat(500) @(posedge clk_100M);
        toggle_vsync_only();    
    
        // 3) 이제 읽기 뱅크에 image2가 있다고 가정
        //compare_frame_with_image(1);  // image2.txt와 비교

        $display("[TB] Simulation done.");
        #1000;
        $finish;
    end
    endtask


    /*
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
                @(posedge clk_100M);
        
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
                    $stop;
                end
            end
        
            rd_en = 1'b0;
            $display("[%0t] INFO: image%0d check PASSED (all %0d pixels matched).",
                     $time, which+1, FRAME_PIXELS);
        end
        endtask
                    */
endmodule
