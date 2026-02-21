`timescale 1ns/1ps

module tb_RGB888ToRGB565;

    // =================================================================
    // 파라미터 및 상수 정의
    // =================================================================
    
    // 100MHz 클럭 -> 10ns 주기
    localparam integer CLK_PERIOD   = 10; 
    
    // 16분주 클럭 인에이블
    localparam integer CLK_EN_DIV   = 16;
    
    // DUT의 메모리 깊이 (테스트벤치에서 검증용으로 사용)
    localparam integer MEM_DEPTH_TB = 130560;

    // =================================================================
    // 테스트벤치 신호 선언
    // =================================================================
    
    // 클럭 및 리셋
    reg tb_clk;
    reg tb_rst_n;

    // DUT 입력
    reg [23:0] tb_data_in;  // i_data_rgb888
    reg        tb_valid_in; // i_valid
    reg        tb_clk_en;   // i_Clk_en

    // DUT 출력
    wire       tb_done_valid; // o_done_valid

    // 내부 클럭 인에이블 카운터
    reg [$clog2(CLK_EN_DIV)-1:0] clk_en_cnt;

    // =================================================================
    // DUT (Device Under Test) 인스턴스
    // =================================================================
    RGB888ToRGB565 dut (
        .iClk          (tb_clk),
        .iRst_n        (tb_rst_n),
        .i_data_rgb888 (tb_data_in),
        .i_valid       (tb_valid_in),
        .i_Clk_en      (tb_clk_en),
        .o_done_valid  (tb_done_valid)
    );

    // =================================================================
    // 클럭 생성 (100MHz)
    // =================================================================
    initial begin
        tb_clk = 1'b0;
        forever # (CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    // =================================================================
    // 16분주 클럭 인에이블 (i_Clk_en) 생성
    // =================================================================
    always @(posedge tb_clk or negedge tb_rst_n) begin
        if (!tb_rst_n) begin
            clk_en_cnt <= 'd0;
            tb_clk_en  <= 1'b0;
        end else begin
            if (clk_en_cnt == CLK_EN_DIV - 1) begin
                clk_en_cnt <= 'd0;
            end else begin
                clk_en_cnt <= clk_en_cnt + 1;
            end
            
            tb_clk_en <= (clk_en_cnt == 'd0);
        end
    end

    integer i; 
    integer j;
    integer k;
    reg [15:0] internal_mem_value;
    reg [15:0] expected_rgb565_value;
    reg [23:0] input_rgb888_value;

    // =================================================================
    // 메인 테스트 시퀀스
    // =================================================================
    initial begin
        $display("========================================");
        $display("[Testbench] 시뮬레이션을 시작합니다. (Clk: 100MHz, Clk_En: 1/16)");
        $display("========================================");
        k=0;

        // 1. 초기화 및 리셋
        tb_data_in  <= 24'h000000;
        tb_valid_in <= 1'b0;
        tb_rst_n    <= 1'b0; 

        repeat (5) @(posedge tb_clk); 
        
        tb_rst_n <= 1'b1; 
        $display("[%0t] 시스템 리셋 해제.", $time);
        
        @(posedge tb_clk);

        // 2. 130,560개 픽셀 데이터 전송
        $display("[%0t] %0d 개의 픽셀 전송을 시작합니다...", $time, MEM_DEPTH_TB);
        
        for (i = 0; i < MEM_DEPTH_TB; i = i + 1) begin
            
            @(posedge tb_clk_en); 
            
            tb_valid_in <= 1'b1;
            tb_data_in  <= i + 100; 
            
            if (i % 10000 == 0) begin
                $display("[%0t] ... 픽셀 %0d 전송 (Data: %h)", $time, i, i+1);
            end

            @(posedge tb_clk);
            
            @(posedge tb_clk);
            tb_valid_in <= 1'b0; 
        end

        // 3. 마지막 픽셀 전송 후 결과 확인
        $display("[%0t] ... 모든 픽셀(%0d개) 전송 완료. o_done_valid 신호를 확인합니다.", $time, MEM_DEPTH_TB);
        
        @(posedge tb_clk);

        if (tb_done_valid == 1'b1) begin
            $display("PASS: [%0t] o_done_valid 신호가 1이 되었습니다.", $time);
        end else begin
            $display("FAIL: [%0t] o_done_valid 신호가 1이 아닙니다! (현재 값: %b)", $time, tb_done_valid);
        end

        // =================================================================
        // 4. [추가된 부분] DUT 내부 메모리 검증
        // =================================================================
        // '계층적 참조(Hierarchical Reference)'를 사용하여 DUT 내부 신호에 접근합니다.
        // [주의] 이 코드는 시뮬레이션 전용이며 합성(synthesis)되지 않습니다.
        // [수정] DUT 내부 메모리 이름으로 'reg_file'을 사용합니다.
        
        // 메모리 접근이 안정화될 때까지 잠시 대기
        repeat(5) @(posedge tb_clk); 
        
        $display("========================================");
        $display("[%0t] DUT 내부 '레지스터 파일' 검증 시작 (처음 10개 샘플)", $time);
        $display("========================================");
        


        for (j = 0; j < 130560; j = j + 1) begin
            // 테스트벤치가 DUT에 넣었던 값 (i + 1)
            input_rgb888_value = j + 100;
            
            // 테스트벤치가 예상하는 RGB565 변환 값
            // RGB888 (R: [23:16], G: [15:8], B: [7:0])
            // RGB565 (R: [15:11], G: [10:5], B: [4:0])
            // R5 = R8[7:3] (상위 5비트)
            // G6 = G8[7:2] (상위 6비트)
            // B5 = B8[7:3] (상위 5비트)
            
            // 입력 데이터는 'i+1'이었고 R,G,B에 모두 같은 값이 들어갔다고 가정
            // (tb_data_in <= i + 1; -> R=i+1, G=i+1, B=i+1)
            expected_rgb565_value = { input_rgb888_value[23:19], input_rgb888_value[15:10], input_rgb888_value[7:3] };


            // [핵심] 계층적 참조를 통해 DUT 내부 메모리 값 읽기
            // 'dut'는 인스턴스 이름, 'reg_file'은 DUT 내부의 메모리 이름 (수정됨)
            // 시뮬레이터가 이 경로를 찾을 수 있어야 합니다.
            // ** 만약 'reg_file'이 다른 모듈 안에 있다면, 전체 경로를 명시해야 합니다. **
            // ** (예: dut.bram_instance.reg_file[j]) **
            internal_mem_value = dut.reg_file[j]; 

            // 검증
            $display("[%0t] 검증: MEM[%0d], 입력값: %h, 예상값(RGB565): %h, DUT내부값: %h",
                     $time, j, input_rgb888_value, expected_rgb565_value, internal_mem_value);
            
            if (internal_mem_value == expected_rgb565_value) begin
                 $display("PASS: MEM[%0d] 값이 일치합니다.", j);
            
            end else begin
                 $display("FAIL: MEM[%0d] 값이 다릅니다!", j);
                 k=1;
            end
        end
        if(k==1) begin
            $display("FAIL");
        end
        else begin
            $display("ALL PASS: MEM값이 모두 일치합니다.");
        end


        // 6. 시뮬레이션 종료
        $display("========================================");
        $display("[%0t] 테스트벤치 시뮬레이션을 종료합니다.", $time);
        $display("========================================");
        $stop;

    end

endmodule