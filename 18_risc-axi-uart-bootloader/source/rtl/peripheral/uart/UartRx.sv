`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: UartRx
Role: 8N1 UART receiver without bus protocol coupling
Summary:
  - Samples one 8-bit character using a 16x baud tick
  - Synchronizes the async RX input before sampling
  - Emits a one-cycle valid pulse after a good stop bit
StateDescription:
  - S_IDLE: wait for start bit
  - S_START: confirm start bit at the middle of the bit time
  - S_DATA: sample 8 data bits LSB first
  - S_STOP: validate stop bit
[MODULE_INFO_END]
*/
module UartRx (
  input  logic       iClk,
  input  logic       iRstn,
  input  logic       iTick16x,
  input  logic       iRx,
  output logic [7:0] oData,
  output logic       oValid,
  output logic       oFrameError
);

  typedef enum logic [1:0] {
    S_IDLE,
    S_START,
    S_DATA,
    S_STOP
  } state_e;

  state_e     rState;
  state_e     wNextState;
  logic [7:0] rData;
  logic [2:0] rBitCnt;
  logic [3:0] rTickCnt;
  logic       rValid;
  logic       rFrameError;
  logic       rRxSync1;
  logic       rRxSync2;
  logic       wRxSynced;

  assign oData       = rData;
  assign oValid      = rValid;
  assign oFrameError = rFrameError;
  assign wRxSynced   = rRxSync2;

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rRxSync1 <= 1'b1;
      rRxSync2 <= 1'b1;
    end
    else begin
      rRxSync1 <= iRx;
      rRxSync2 <= rRxSync1;
    end
  end

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
        if (!wRxSynced) begin
          wNextState = S_START;
        end
      end

      S_START: begin
        if (iTick16x && (rTickCnt == 4'd7)) begin
          wNextState = wRxSynced ? S_IDLE : S_DATA;
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
      rData       <= 8'd0;
      rBitCnt     <= 3'd0;
      rTickCnt    <= 4'd0;
      rValid      <= 1'b0;
      rFrameError <= 1'b0;
    end
    else begin
      rValid      <= 1'b0;
      rFrameError <= 1'b0;

      unique case (rState)
        S_IDLE: begin
          rTickCnt <= 4'd0;
          rBitCnt  <= 3'd0;
        end

        S_START: begin
          if (iTick16x) begin
            rTickCnt <= (rTickCnt == 4'd7) ? 4'd0 : (rTickCnt + 4'd1);
          end
        end

        S_DATA: begin
          if (iTick16x) begin
            if (rTickCnt == 4'd15) begin
              rTickCnt <= 4'd0;
              rData    <= {wRxSynced, rData[7:1]};

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
          if (iTick16x) begin
            if (rTickCnt == 4'd15) begin
              rTickCnt <= 4'd0;

              if (wRxSynced) begin
                rValid <= 1'b1;
              end
              else begin
                rFrameError <= 1'b1;
              end
            end
            else begin
              rTickCnt <= rTickCnt + 4'd1;
            end
          end
        end

        default: begin
          rTickCnt <= 4'd0;
          rBitCnt  <= 3'd0;
        end
      endcase
    end
  end

endmodule
