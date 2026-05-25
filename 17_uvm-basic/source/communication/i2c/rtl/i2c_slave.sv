`timescale 1ns/1ps

module i2c_slave (
  input  logic                  iClk,
  input  logic                  iRst,
  input  logic [6:0]            iOwnAddr,
  input  logic [7:0]            iTxData,
  input  logic                  iScl,
  input  logic                  iSda,

  output logic [7:0]            oRxData,
  output logic                  oRxValid,
  output logic                  oTxnDone,
  output logic                  oTxnRead,
  output logic                  oSdaOe
);

  typedef enum logic [2:0] {
    IDLE,
    ADDR,
    ADDR_ACK,
    WRITE_DATA,
    WRITE_ACK,
    READ_DATA,
    READ_MASTER_ACK,
    COMPLETE
  } state_e;

  // FSM state: current/next slave-side bus phase.
  state_e                      rCurState;
  state_e                      rNxtState;
  // Registered previous bus levels for START/STOP/edge detection.
  logic                        rSclMeta;
  logic                        rSclSync;
  logic                        rSdaMeta;
  logic                        rSdaSync;
  logic                        rSclPrev;
  logic                        rSdaPrev;
  // Bit counter and shift registers for address/data movement.
  logic [2:0]                  rBitCnt;
  logic [7:0]                  rAddrShift;
  logic [7:0]                  rRxShift;
  logic [7:0]                  rTxShift;
  // Latched address match and current R/W direction.
  logic                        rAddrHit;
  logic                        rReadOp;
  // ACK-handshake helpers and end-of-read-byte marker.
  logic                        rAckHighSeen;
  logic                        rAckDriveActive;
  logic                        rReadByteDone;
  // Derived bus events seen by the slave engine.
  logic                        wStartDet;
  logic                        wStopDet;
  logic                        wSclRise;
  logic                        wSclFall;

  assign wStartDet =  rSdaPrev && !rSdaSync && rSclSync;
  assign wStopDet  = !rSdaPrev &&  rSdaSync && rSclSync;
  assign wSclRise  = !rSclPrev &&  rSclSync;
  assign wSclFall  =  rSclPrev && !rSclSync;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rCurState <= IDLE;
      rSclMeta  <= 1'b1;
      rSclSync  <= 1'b1;
      rSdaMeta  <= 1'b1;
      rSdaSync  <= 1'b1;
    end
    else begin
      rCurState <= rNxtState;
      rSclMeta  <= iScl;
      rSclSync  <= rSclMeta;
      rSdaMeta  <= iSda;
      rSdaSync  <= rSdaMeta;
    end
  end

  always_comb begin
    rNxtState = rCurState;

    case (rCurState)
      IDLE: begin
        if (wStartDet) begin
          rNxtState = ADDR;
        end
      end

      ADDR: begin
        if (wStopDet) begin
          rNxtState = IDLE;
        end
        else if (wSclRise && (rBitCnt == 3'd7)) begin
          rNxtState = ADDR_ACK;
        end
      end

      ADDR_ACK: begin
        if (wStopDet) begin
          rNxtState = IDLE;
        end
        else if (wSclFall && rAckHighSeen) begin
          if (!rAddrHit) begin
            rNxtState = IDLE;
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
        if (wStopDet) begin
          rNxtState = IDLE;
        end
        else if (wSclRise && (rBitCnt == 3'd7)) begin
          rNxtState = WRITE_ACK;
        end
      end

      WRITE_ACK: begin
        if (wStopDet) begin
          rNxtState = IDLE;
        end
        else if (wSclFall && rAckHighSeen) begin
          rNxtState = COMPLETE;
        end
      end

      READ_DATA: begin
        if (wStopDet) begin
          rNxtState = IDLE;
        end
        else if (wSclFall && rReadByteDone) begin
          rNxtState = READ_MASTER_ACK;
        end
      end

      READ_MASTER_ACK: begin
        if (wStopDet) begin
          rNxtState = IDLE;
        end
        else if (wSclFall && rAckHighSeen) begin
          rNxtState = COMPLETE;
        end
      end

      COMPLETE: begin
        rNxtState = IDLE;
      end

      default: begin
        rNxtState = IDLE;
      end
    endcase
  end

  always_comb begin
    oRxValid = 1'b0;
    oTxnDone = 1'b0;
    oTxnRead = 1'b0;
    oSdaOe   = 1'b0;

    case (rCurState)
      ADDR_ACK: begin
        if (rAddrHit) begin
          oSdaOe = rAckDriveActive;
        end
      end

      WRITE_ACK: begin
        oSdaOe = rAckDriveActive;
      end

      READ_DATA: begin
        oSdaOe = ~rTxShift[7];
      end

      COMPLETE: begin
        if (rAddrHit) begin
          oTxnDone = 1'b1;
          oTxnRead = rReadOp;

          if (!rReadOp) begin
            oRxValid = 1'b1;
          end
        end
      end

      default: begin
        oSdaOe = 1'b0;
      end
    endcase
  end

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rSclPrev        <= 1'b1;
      rSdaPrev        <= 1'b1;
      rBitCnt         <= '0;
      rAddrShift      <= '0;
      rRxShift        <= '0;
      rTxShift        <= '0;
      rAddrHit        <= 1'b0;
      rReadOp         <= 1'b0;
      rAckHighSeen    <= 1'b0;
      rAckDriveActive <= 1'b0;
      rReadByteDone   <= 1'b0;
      oRxData         <= '0;
    end
    else begin
      if (rCurState != rNxtState) begin
        rBitCnt         <= '0;
        rAckHighSeen    <= 1'b0;
        rAckDriveActive <= 1'b0;
        rReadByteDone   <= 1'b0;
      end

      case (rCurState)
        IDLE: begin
          if (wStartDet) begin
            rAddrShift <= '0;
            rRxShift   <= '0;
            rAddrHit   <= 1'b0;
            rReadOp    <= 1'b0;
          end
        end

        ADDR: begin
          if (wStartDet) begin
            rBitCnt    <= '0;
            rAddrShift <= '0;
          end
          else if (wSclRise) begin
            logic [7:0] wAddrFrame;

            wAddrFrame = {rAddrShift[6:0], rSdaSync};
            rAddrShift <= wAddrFrame;

            if (rBitCnt == 3'd7) begin
              rAddrHit <= (wAddrFrame[7:1] == iOwnAddr);
              rReadOp  <= wAddrFrame[0];

              if ((wAddrFrame[7:1] == iOwnAddr) && wAddrFrame[0]) begin
                rTxShift <= iTxData;
              end
            end
            else begin
              rBitCnt <= rBitCnt + 1'b1;
            end
          end
        end

        ADDR_ACK: begin
          if (wSclFall && !rAckHighSeen) begin
            rAckDriveActive <= 1'b1;
          end

          if (wSclRise) begin
            rAckHighSeen <= 1'b1;
          end

          if (wSclFall && rAckHighSeen && rAddrHit && !rReadOp) begin
            rRxShift <= '0;
          end
        end

        WRITE_DATA: begin
          if (wSclRise) begin
            rRxShift <= {rRxShift[6:0], rSdaSync};

            if (rBitCnt == 3'd7) begin
              oRxData <= {rRxShift[6:0], rSdaSync};
            end
            else begin
              rBitCnt <= rBitCnt + 1'b1;
            end
          end
        end

        WRITE_ACK: begin
          if (wSclFall && !rAckHighSeen) begin
            rAckDriveActive <= 1'b1;
          end

          if (wSclRise) begin
            rAckHighSeen <= 1'b1;
          end
        end

        READ_DATA: begin
          if (wSclRise) begin
            if (rBitCnt == 3'd7) begin
              rReadByteDone <= 1'b1;
            end
            else begin
              rBitCnt <= rBitCnt + 1'b1;
            end
          end

          if (wSclFall && !rReadByteDone) begin
            rTxShift <= {rTxShift[6:0], 1'b1};
          end
        end

        READ_MASTER_ACK: begin
          if (wSclRise) begin
            rAckHighSeen <= 1'b1;
          end
        end

        default: begin
        end
      endcase

      rSclPrev <= rSclSync;
      rSdaPrev <= rSdaSync;
    end
  end

endmodule
