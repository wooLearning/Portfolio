`timescale 1ns/1ps

module uart_tx #(
  parameter int DATA_BITS  = 8,
  parameter int OVERSAMPLE = 16,
  parameter int TICK_TIMEOUT_CYCLES = 0
) (
  input  logic                 iClk,
  input  logic                 iRst,
  input  logic                 iTick16x,
  input  logic [DATA_BITS-1:0] iTxData,
  input  logic                 iTxValid,
  output logic                 oTxReady,
  output logic                 oTx,
  output logic                 oTxBusy,
  output logic                 oTxDone
);

  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } state_e;

  localparam int TICK_CNT_W = (OVERSAMPLE > 1) ? $clog2(OVERSAMPLE) : 1;
  localparam int BIT_CNT_W  = (DATA_BITS > 1) ? $clog2(DATA_BITS) : 1;
  localparam int TIMEOUT_CNT_W = (TICK_TIMEOUT_CYCLES > 1) ?
                                 $clog2(TICK_TIMEOUT_CYCLES) : 1;
  localparam int TIMEOUT_LIMIT = (TICK_TIMEOUT_CYCLES > 0) ?
                                 (TICK_TIMEOUT_CYCLES - 1) : 0;

  state_e                      rCurState;
  state_e                      rNxtState;
  logic [DATA_BITS-1:0]        rShift;
  logic [TICK_CNT_W-1:0]       rTickCnt;
  logic [BIT_CNT_W-1:0]        rBitCnt;
  logic [TIMEOUT_CNT_W-1:0]    rTimeoutCnt;
  logic                        rTx;
  logic                        wStartReq;
  logic                        wTickDone;
  logic                        wTickTimeout;

  assign wStartReq = iTxValid && oTxReady;
  assign wTickDone = iTick16x && (rTickCnt == OVERSAMPLE - 1);
  assign wTickTimeout = (TICK_TIMEOUT_CYCLES > 0) &&
                        (rCurState != IDLE) &&
                        !iTick16x &&
                        (rTimeoutCnt == TIMEOUT_LIMIT);

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rCurState <= IDLE;
    end
    else begin
      rCurState <= rNxtState;
    end
  end

  always_comb begin
    rNxtState = rCurState;

    case (rCurState)
      IDLE: begin
        if (wStartReq) begin
          rNxtState = START;
        end
      end

      START: begin
        if (wTickTimeout) begin
          rNxtState = IDLE;
        end
        else if (wTickDone) begin
          rNxtState = DATA;
        end
      end

      DATA: begin
        if (wTickTimeout) begin
          rNxtState = IDLE;
        end
        else if (wTickDone && (rBitCnt == DATA_BITS - 1)) begin
          rNxtState = STOP;
        end
      end

      STOP: begin
        if (wTickTimeout) begin
          rNxtState = IDLE;
        end
        else if (wTickDone) begin
          rNxtState = IDLE;
        end
      end

      default: begin
        rNxtState = IDLE;
      end
    endcase
  end

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rTimeoutCnt <= '0;
    end
    else if ((rCurState == IDLE) || iTick16x || wTickTimeout) begin
      rTimeoutCnt <= '0;
    end
    else if (TICK_TIMEOUT_CYCLES > 0) begin
      rTimeoutCnt <= rTimeoutCnt + 1'b1;
    end
  end

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rShift   <= '0;
      rTickCnt <= '0;
      rBitCnt  <= '0;
      rTx      <= 1'b1;
      oTxDone  <= 1'b0;
    end
    else begin
      oTxDone <= 1'b0;

      case (rCurState)
        IDLE: begin
          rTickCnt <= '0;
          rBitCnt  <= '0;
          rTx      <= 1'b1;

          if (wStartReq) begin
            rShift <= iTxData;
            rTx    <= 1'b0;
          end
        end

        START: begin
          rTx <= 1'b0;

          if (wTickTimeout) begin
            rTickCnt <= '0;
            rBitCnt  <= '0;
            rTx      <= 1'b1;
          end
          else if (wTickDone) begin
            rTickCnt <= '0;
            rTx      <= rShift[0];
          end
          else if (iTick16x) begin
            rTickCnt <= rTickCnt + 1'b1;
          end
        end

        DATA: begin
          rTx <= rShift[0];

          if (wTickTimeout) begin
            rTickCnt <= '0;
            rBitCnt  <= '0;
            rShift   <= '0;
            rTx      <= 1'b1;
          end
          else if (wTickDone) begin
            rTickCnt <= '0;
            rShift   <= {{1{1'b0}}, rShift[DATA_BITS-1:1]};

            if (rBitCnt == DATA_BITS - 1) begin
              rTx <= 1'b1;
            end
            else begin
              rBitCnt <= rBitCnt + 1'b1;
            end
          end
          else if (iTick16x) begin
            rTickCnt <= rTickCnt + 1'b1;
          end
        end

        STOP: begin
          rTx <= 1'b1;

          if (wTickTimeout) begin
            rTickCnt <= '0;
            rBitCnt  <= '0;
          end
          else if (wTickDone) begin
            rTickCnt <= '0;
            oTxDone  <= 1'b1;
          end
          else if (iTick16x) begin
            rTickCnt <= rTickCnt + 1'b1;
          end
        end

        default: begin
          rShift   <= '0;
          rTickCnt <= '0;
          rBitCnt  <= '0;
          rTx      <= 1'b1;
        end
      endcase
    end
  end

  assign oTxReady = (rCurState == IDLE);
  assign oTxBusy  = (rCurState != IDLE);
  assign oTx      = rTx;

endmodule
