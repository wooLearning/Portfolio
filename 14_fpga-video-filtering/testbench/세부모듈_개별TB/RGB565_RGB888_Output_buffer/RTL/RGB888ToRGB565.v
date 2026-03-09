`timescale 1ns/1ps

module RGB888ToRGB565 (
    input  wire        iClk,
    input  wire        iRst_n,

    // 입력단 (RGB888)
    input  wire [23:0] i_data_rgb888, // R[23:16], G[15:8], B[7:0]
    input  wire        i_valid,       // 입력 ENABLE
    input              i_Clk_en,

    // 출력단
    output wire        o_done_valid      // 메모리(REG FILE)가 다 찼음을 알림
);
    // =================================================================
    // 파라미터 정의
    // =================================================================
    localparam MEM_DEPTH    = 130560;
    // log2(130560) = 16.99... -> 17 비트 필요
    localparam ADDR_WIDTH   = 17; 
    localparam DATA_WIDTH   = 16; // RGB565

    // FSM 상태
    localparam  STATE_IDLE   = 1'b0;
    localparam  STATE_DONE   = 1'b1;

    // =================================================================
    // 내부 레지스터 및 와이어
    // =================================================================
    
    // 130560 x 16-bit 메모리 (BRAM/SRAM으로 합성됨)
    reg [DATA_WIDTH-1:0] reg_file [0:MEM_DEPTH-1];

    // FSM
    reg state;
    
    // 주소 카운터
    reg [ADDR_WIDTH-1:0] addr_cnt;

    // 완료 신호 (레지스터)
    reg done_valid_reg;

    // RGB888 입력 추출
    wire [7:0] r8 = i_data_rgb888[23:16];
    wire [7:0] g8 = i_data_rgb888[15: 8];
    wire [7:0] b8 = i_data_rgb888[ 7: 0];

    // =================================================================
    // Task 1: RGB888 -> RGB565 변환 (조합 로직)
    // =================================================================
    // R: 8비트(0-255) -> 5비트(0-31)
    wire [4:0] r5 = r8[7:3]; 
    // G: 8비트(0-255) -> 6비트(0-63)
    wire [5:0] g6 = g8[7:2];
    // B: 8비트(0-255) -> 5비트(0-31)
    wire [4:0] b5 = b8[7:3];
    // 16비트 RGB565로 결합
    wire [DATA_WIDTH-1:0] converted_rgb565 = {r5, g6, b5};

    // =================================================================
    // ⚙️ Task 2 & 3: 메모리 저장 및 FSM (순차 로직)
    // =================================================================

    // 입력 수신 준비 신호
    // IDLE 상태일 때만 (즉, DONE이 아닐 때만) 입력을 받습니다.
    assign in_ready = (state == STATE_IDLE);

    // 실제 쓰기 동작은 입력이 유효(valid)하고 우리가 준비(ready)되었을 때 발생
    wire do_write = i_valid;

    // FSM 및 주소 카운터 로직
    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            // 리셋: IDLE 상태에서 0번 주소부터 시작
            state          <= STATE_IDLE;
            addr_cnt       <= 'd0;
            done_valid_reg <= 1'b0;
        end else begin
            if (i_Clk_en == 1'b1) begin
                case (state)
                    STATE_IDLE: begin
                        // IDLE 상태 (쓰기 대기 및 수행)
                        if (do_write) begin
                            // 쓰기 수행
                            if (addr_cnt == MEM_DEPTH - 1) begin
                                // 마지막 주소에 썼다면 -> DONE 상태로 천이
                                state          <= STATE_DONE;
                                done_valid_reg <= 1'b1; // 완료 신호 활성화
                                addr_cnt       <= 0;  // (다음 리셋을 위해)
                            end else begin
                                // 마지막이 아니면 -> 주소 1 증가
                                addr_cnt <= addr_cnt + 1;
                            end
                        end
                    end // case STATE_IDLE
    
                    STATE_DONE: begin
                        // DONE 상태 (메모리 참)
                        // 리셋이 걸릴 때까지 이 상태를 유지
                        state          <= STATE_IDLE;
                        done_valid_reg <= 1'b0;
                    end // case STATE_DONE
                endcase
             end
        end
    end

    // 메모리 쓰기 로직 (Synchronous Write)
    // 'converted_rgb565' 값을 씁니다.
    always @(posedge iClk) begin
        if (i_Clk_en == 1'b1) begin
            if (do_write) begin
                reg_file[addr_cnt] <= converted_rgb565;
            end
        end
    end

    // 최종 완료 신호 출력
    assign o_done_valid = done_valid_reg;

endmodule