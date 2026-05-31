`timescale 1ns/1ps

module i2c_master (
  input  logic                  iClk,
  input  logic                  iTick,
  input  logic                  iRst,
  input  logic                  iStart,
  input  logic                  iRead,
  input  logic [6:0]            iSlaveAddr,
  input  logic [7:0]            iTxData,
  input  logic                  iSda,

  output logic [7:0]            oRxData,
  output logic                  oBusy,
  output logic                  oDone,
  output logic                  oAckError,
  output logic                  oSclOe,
  output logic                  oSdaOe
);

  typedef enum logic [3:0] {
    IDLE,
    START,
    ADDR,
    ADDR_ACK,
    WRITE_DATA,
    WRITE_ACK,
    READ_DATA,
    READ_NACK,
    STOP,
    DONE
  } state_e;

  localparam logic [2:0] LAST_ADDR_BIT = 3'd7;
  localparam logic [2:0] LAST_DATA_BIT = 3'd7;

  // FSM state: current/next low-level I2C bus phase.
  state_e                      rCurState;
  state_e                      rNxtState;
  // 4-step sub-phase inside each I2C bit time.
  logic [1:0]                  rPhase;
  // Remaining bit counter for address/data transfers.
  logic [2:0]                  rBitCnt;
  // Shift register for the 7-bit address + R/W bit.
  logic [7:0]                  rAddrShift;
  // Shift register for transmitted data and sampled readback data.
  logic [7:0]                  rTxShift;
  logic [7:0]                  rRxShift;
  // Latched direction of the current byte transaction.
  logic                        rReadOp;
  // Result of the latest ACK/NACK sample.
  logic                        rAckOk;
  logic                        rSdaMeta;
  logic                        rSdaSync;
  // Tick/phase helper signals used to advance timed states.
  logic                        wStepTick;
  logic                        wPhaseDone;
  logic                        wTimedState;

  assign wStepTick  = iTick;
  assign wPhaseDone = wStepTick && (rPhase == 2'd3);
  assign wTimedState = (rCurState != IDLE) && (rCurState != DONE);

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rCurState <= IDLE;
      rSdaMeta  <= 1'b1;
      rSdaSync  <= 1'b1;
    end
    else begin
      rCurState <= rNxtState;
      rSdaMeta  <= iSda;
      rSdaSync  <= rSdaMeta;
    end
  end

  always_comb begin
    rNxtState = rCurState;

    case (rCurState)
      IDLE: begin
        if (iStart) begin
          rNxtState = START;
        end
      end

      START: begin
        if (wPhaseDone) begin
          rNxtState = ADDR;
        end
      end

      ADDR: begin
        if (wPhaseDone && (rBitCnt == '0)) begin
          rNxtState = ADDR_ACK;
        end
      end

      ADDR_ACK: begin
        if (wPhaseDone) begin
          if (!rAckOk) begin
            rNxtState = STOP;
          end
          else if (rReadOp) begin
            rNxtState = READ_DATA;
          end
          else begin
            rNxtState = WRITE_DATA;
          end
        end
      end

      WRITE_DATA: begin
        if (wPhaseDone && (rBitCnt == '0)) begin
          rNxtState = WRITE_ACK;
        end
      end

      WRITE_ACK: begin
        if (wPhaseDone) begin
          rNxtState = STOP;
        end
      end

      READ_DATA: begin
        if (wPhaseDone && (rBitCnt == '0)) begin
          rNxtState = READ_NACK;
        end
      end

      READ_NACK: begin
        if (wPhaseDone) begin
          rNxtState = STOP;
        end
      end

      STOP: begin
        if (wPhaseDone) begin
          rNxtState = DONE;
        end
      end

      DONE: begin
        rNxtState = IDLE;
      end

      default: begin
        rNxtState = IDLE;
      end
    endcase
  end

  always_comb begin
    oBusy     = 1'b1;
    oDone     = 1'b0;
    oSclOe    = 1'b0;
    oSdaOe    = 1'b0;

    case (rCurState)
      IDLE: begin
        oBusy = 1'b0;
      end

      START: begin
        case (rPhase)
          2'd0: begin
            oSclOe = 1'b0;
            oSdaOe = 1'b0;
          end

          2'd1: begin
            oSclOe = 1'b0;
            oSdaOe = 1'b1;
          end

          default: begin
            oSclOe = 1'b1;
            oSdaOe = 1'b1;
          end
        endcase
      end

      ADDR: begin
        oSclOe = (rPhase == 2'd0) || (rPhase == 2'd3);
        oSdaOe = ~rAddrShift[7];
      end

      ADDR_ACK: begin
        oSclOe = (rPhase == 2'd0) || (rPhase == 2'd3);
      end

      WRITE_DATA: begin
        oSclOe = (rPhase == 2'd0) || (rPhase == 2'd3);
        oSdaOe = ~rTxShift[7];
      end

      WRITE_ACK: begin
        oSclOe = (rPhase == 2'd0) || (rPhase == 2'd3);
      end

      READ_DATA: begin
        oSclOe = (rPhase == 2'd0) || (rPhase == 2'd3);
      end

      READ_NACK: begin
        oSclOe = (rPhase == 2'd0) || (rPhase == 2'd3);
      end

      STOP: begin
        case (rPhase)
          2'd0: begin
            oSclOe = 1'b1;
            oSdaOe = 1'b1;
          end

          2'd1: begin
            oSclOe = 1'b0;
            oSdaOe = 1'b1;
          end

          default: begin
            oSclOe = 1'b0;
            oSdaOe = 1'b0;
          end
        endcase
      end

      DONE: begin
        oBusy = 1'b0;
        oDone = 1'b1;
      end

      default: begin
        oBusy = 1'b1;
      end
    endcase
  end

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rPhase     <= '0;
      rBitCnt    <= '0;
      rAddrShift <= '0;
      rTxShift   <= '0;
      rRxShift   <= '0;
      rReadOp    <= 1'b0;
      rAckOk     <= 1'b1;
      oRxData    <= '0;
      oAckError  <= 1'b0;
    end
    else begin
      if (wTimedState) begin
        if (wStepTick) begin
          if (wPhaseDone) begin
            rPhase <= 2'd0;
          end
          else begin
            rPhase <= rPhase + 1'b1;
          end
        end
      end
      else begin
        rPhase <= '0;
      end

      case (rCurState)
        IDLE: begin
          if (iStart) begin
            rBitCnt    <= LAST_ADDR_BIT;
            rAddrShift <= {iSlaveAddr, iRead};
            rTxShift   <= iTxData;
            rRxShift   <= '0;
            rReadOp    <= iRead;
            rAckOk     <= 1'b1;
            oAckError  <= 1'b0;
          end
        end

        ADDR: begin
          if (wPhaseDone) begin
            if (rBitCnt != '0) begin
              rBitCnt    <= rBitCnt - 1'b1;
              rAddrShift <= {rAddrShift[6:0], 1'b1};
            end
            else begin
              rBitCnt <= LAST_DATA_BIT;
            end
          end
        end

        ADDR_ACK: begin
          if (wStepTick && (rPhase == 2'd2)) begin
            rAckOk <= ~rSdaSync;
          end

          if (wPhaseDone && !rAckOk) begin
            oAckError <= 1'b1;
          end
        end

        WRITE_DATA: begin
          if (wPhaseDone) begin
            if (rBitCnt != '0) begin
              rBitCnt  <= rBitCnt - 1'b1;
              rTxShift <= {rTxShift[6:0], 1'b1};
            end
          end
        end

        WRITE_ACK: begin
          if (wStepTick && (rPhase == 2'd2)) begin
            rAckOk <= ~rSdaSync;
          end

          if (wPhaseDone && !rAckOk) begin
            oAckError <= 1'b1;
          end
        end

        READ_DATA: begin
          if (wStepTick && (rPhase == 2'd2)) begin
            rRxShift <= {rRxShift[6:0], rSdaSync};

            if (rBitCnt == '0) begin
              oRxData <= {rRxShift[6:0], rSdaSync};
            end
          end

          if (wPhaseDone && (rBitCnt != '0)) begin
            rBitCnt <= rBitCnt - 1'b1;
          end
        end

        default: begin
        end
      endcase
    end
  end

endmodule
