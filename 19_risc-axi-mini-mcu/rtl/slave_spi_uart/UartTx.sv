`timescale 1ns / 1ps

module UartTx (
  input  logic       iClk,
  input  logic       iRstn,
  input  logic       iTick16x,
  input  logic [7:0] iData,
  input  logic       iValid,
  output logic       oTx,
  output logic       oBusy,
  output logic       oDone
);

  typedef enum logic [1:0] {
    S_IDLE,
    S_START,
    S_DATA,
    S_STOP
  } state_e;

  state_e     rState;
  state_e     wNextState;
  logic [7:0] rShiftReg;
  logic [2:0] rBitCnt;
  logic [3:0] rTickCnt;
  logic       rTx;

  assign oTx   = rTx;
  assign oBusy = (rState != S_IDLE);
  assign oDone = (rState == S_STOP) && iTick16x && (rTickCnt == 4'd15);

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rState <= S_IDLE;
    end
    else begin
      rState <= wNextState;
    end
  end

  always_comb begin
    wNextState = rState;

    unique case (rState)
      S_IDLE: begin
        if (iValid) begin
          wNextState = S_START;
        end
      end

      S_START: begin
        if (iTick16x && (rTickCnt == 4'd15)) begin
          wNextState = S_DATA;
        end
      end

      S_DATA: begin
        if (iTick16x && (rTickCnt == 4'd15) && (rBitCnt == 3'd7)) begin
          wNextState = S_STOP;
        end
      end

      S_STOP: begin
        if (iTick16x && (rTickCnt == 4'd15)) begin
          wNextState = S_IDLE;
        end
      end

      default: begin
        wNextState = S_IDLE;
      end
    endcase
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rShiftReg <= 8'd0;
      rBitCnt   <= 3'd0;
      rTickCnt  <= 4'd0;
      rTx       <= 1'b1;
    end
    else begin
      unique case (rState)
        S_IDLE: begin
          rTx      <= 1'b1;
          rTickCnt <= 4'd0;
          rBitCnt  <= 3'd0;

          if (iValid) begin
            rShiftReg <= iData;
          end
        end

        S_START: begin
          rTx <= 1'b0;

          if (iTick16x) begin
            rTickCnt <= (rTickCnt == 4'd15) ? 4'd0 : (rTickCnt + 4'd1);
          end
        end

        S_DATA: begin
          rTx <= rShiftReg[0];

          if (iTick16x) begin
            if (rTickCnt == 4'd15) begin
              rTickCnt  <= 4'd0;
              rShiftReg <= {1'b0, rShiftReg[7:1]};

              if (rBitCnt != 3'd7) begin
                rBitCnt <= rBitCnt + 3'd1;
              end
            end
            else begin
              rTickCnt <= rTickCnt + 4'd1;
            end
          end
        end

        S_STOP: begin
          rTx <= 1'b1;

          if (iTick16x) begin
            rTickCnt <= (rTickCnt == 4'd15) ? 4'd0 : (rTickCnt + 4'd1);
          end
        end

        default: begin
          rTx      <= 1'b1;
          rTickCnt <= 4'd0;
          rBitCnt  <= 3'd0;
        end
      endcase
    end
  end

endmodule
