`timescale 1ns/1ps

module uart_rx #(
  parameter int DATA_BITS  = 8,
  parameter int OVERSAMPLE = 16,
  parameter int TICK_TIMEOUT_CYCLES = 0
) (
  input  logic                 iClk,
  input  logic                 iRst,
  input  logic                 iTick16x,
  input  logic                 iRx,
  output logic [DATA_BITS-1:0] oRxData,
  output logic                 oRxValid,
  output logic                 oRxBusy,
  output logic                 oFrameError
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
  localparam int MID_TICK   = (OVERSAMPLE / 2) - 1;

  state_e                      rCurState;
  state_e                      rNxtState;
  logic [DATA_BITS-1:0]        rShift;
  logic [TICK_CNT_W-1:0]       rTickCnt;
  logic [BIT_CNT_W-1:0]        rBitCnt;
  logic [TIMEOUT_CNT_W-1:0]    rTimeoutCnt;
  logic                        rRxMeta;
  logic                        rRxSync;
  logic                        wMidTick;
  logic                        wTickDone;
  logic                        wTickTimeout;

  assign wMidTick  = iTick16x && (rTickCnt == MID_TICK);
  assign wTickDone = iTick16x && (rTickCnt == OVERSAMPLE - 1);
  assign wTickTimeout = (TICK_TIMEOUT_CYCLES > 0) &&
                        (rCurState != IDLE) &&
                        !iTick16x &&
                        (rTimeoutCnt == TIMEOUT_LIMIT);

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rRxMeta <= 1'b1;
      rRxSync <= 1'b1;
    end
    else begin
      rRxMeta <= iRx;
      rRxSync <= rRxMeta;
    end
  end

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
        if (!rRxSync) begin
          rNxtState = START;
        end
      end

      START: begin
        if (wTickTimeout) begin
          rNxtState = IDLE;
        end
        else if (wMidTick) begin
          if (!rRxSync) begin
            rNxtState = DATA;
          end
          else begin
            rNxtState = IDLE;
          end
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
      rShift      <= '0;
      rTickCnt    <= '0;
      rBitCnt     <= '0;
      oRxData     <= '0;
      oRxValid    <= 1'b0;
      oFrameError <= 1'b0;
    end
    else begin
      oRxValid    <= 1'b0;
      oFrameError <= 1'b0;

      case (rCurState)
        IDLE: begin
          rTickCnt <= '0;
          rBitCnt  <= '0;

          if (!rRxSync) begin
            rShift <= '0;
          end
        end

        START: begin
          if (wTickTimeout) begin
            rTickCnt    <= '0;
            rBitCnt     <= '0;
            oFrameError <= 1'b1;
          end
          else if (wMidTick) begin
            rTickCnt <= '0;
          end
          else if (iTick16x) begin
            rTickCnt <= rTickCnt + 1'b1;
          end
        end

        DATA: begin
          if (wTickTimeout) begin
            rTickCnt    <= '0;
            rBitCnt     <= '0;
            oFrameError <= 1'b1;
          end
          else if (wTickDone) begin
            rTickCnt <= '0;
            rShift   <= {rRxSync, rShift[DATA_BITS-1:1]};

            if (rBitCnt != DATA_BITS - 1) begin
              rBitCnt <= rBitCnt + 1'b1;
            end
          end
          else if (iTick16x) begin
            rTickCnt <= rTickCnt + 1'b1;
          end
        end

        STOP: begin
          if (wTickTimeout) begin
            rTickCnt    <= '0;
            rBitCnt     <= '0;
            oFrameError <= 1'b1;
          end
          else if (wTickDone) begin
            rTickCnt <= '0;

            if (rRxSync) begin
              oRxData  <= rShift;
              oRxValid <= 1'b1;
            end
            else begin
              oFrameError <= 1'b1;
            end
          end
          else if (iTick16x) begin
            rTickCnt <= rTickCnt + 1'b1;
          end
        end

        default: begin
          rShift   <= '0;
          rTickCnt <= '0;
          rBitCnt  <= '0;
        end
      endcase
    end
  end

  assign oRxBusy = (rCurState != IDLE);

endmodule
