`timescale 1ns/10ps

module tb_top;

    localparam ADDR_W = 17;
    localparam DATA_W = 24;
    localparam DEPTH  = 130560; // 비교할 총 픽셀 수 (480 * 272)
    localparam WIDTH  = 480;    // --- NEW --- 1줄의 픽셀(가로) 수

    reg iClk_100;
    reg iClk_12_5;
    reg iRsn;
    
    reg iStart;

    wire oLcdHSync;
    wire oLcdVSync;

    wire [4:0] oLcdR;
    wire [5:0] oLcdG;
    wire [4:0] oLcdB;
 
    wire [15:0] rgbcom = {oLcdR , oLcdG, oLcdB};

    top top(
        .iClk(iClk_100),
        .iClkTFT(iClk_12_5),
        .iRstButton(iRsn),
        .oLcdHSync(oLcdHSync),
        .oLcdVSync(oLcdVSync),
        .oLcdR(oLcdR),
        .oLcdG(oLcdG),
        .oLcdB(oLcdB),
        .iReg0(0),
        .iReg1(0),
        .iReg2(0),
        .iReg3(0),
        .wStart(iStart)	
    );
   
    // 100 MHz clock
    initial begin
        iClk_100 = 1'b0;
        forever #5 iClk_100 = ~iClk_100; // 10ns period
    end
    initial begin
        iClk_12_5 = 1'b0;
        forever #40 iClk_12_5 = ~iClk_12_5; // 10ns period
    end

    // --- 테스트벤치 로직 ---

    // 기대값 저장을 위한 메모리
    reg [15:0] expected_memory [0:DEPTH-1];
   
   
    // 1. 기대값 파일 로드
    initial begin
        $readmemh("C:/Users/user/Desktop/AdvancedProject/hw16_realfinal/TBDataset/final/image2_565.txt", expected_memory);
    end

    reg flag;
    // 2. 리셋 및 변수 초기화
    initial begin
        iRsn = 1'b1;
        flag = 1;
        // reset
        iRsn = 1'b0;
        repeat(10) @(posedge iClk_100);
        iRsn = 1'b1; // 리셋 해제
        iStart = 1'b0;
        repeat(10) @(posedge iClk_100);
        iStart = 1'b1;

    end
    integer i;
    reg [15:0] expected_rgb565;
    always @(posedge top.u_cnn_top.u_RGB888ToRGB565.done_valid_reg)begin
        for(i = 0; i<DEPTH;i=i+1) begin
            expected_rgb565 = expected_memory[i];
            if(top.u_cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i] != expected_rgb565 ) begin
                flag = 0;
                $display("ERROR!!!: %d expected: %h , outbuf: %h \n",i,expected_rgb565,top.u_cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
                $finish;
               // if(i <10)begin
                //     $display("%h  //// %h",expected_rgb565,u_cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
                // end
                // if(i<130560 && i>130540) begin
                //     $display("%h  //// %h",expected_rgb565,u_cnn_top.u_OufBuf_DPSram_RGB565.rOufBuf[i]);
                // end
            end
        end
        if(flag == 1) begin
            $display("All Completed\n");
            $stop;
        end
        else begin
            $display("Failed\n");
            //$stop;
        end
        
    end

endmodule