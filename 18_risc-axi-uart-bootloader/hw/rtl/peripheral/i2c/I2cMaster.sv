`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: I2cMaster
Role: Single-byte I2C master without bus protocol coupling
Summary:
  - Issues one address + one data byte write or one data byte read
  - Uses open-drain drive-low controls for SCL and SDA
  - Exposes busy, done, and ACK error status
StateDescription:
  - S_IDLE: waits for iStart
  - S_START: emits start condition
  - S_ADDR: shifts 7-bit address plus R/W bit
  - S_ADDR_ACK: samples address ACK
  - S_WRITE_DATA/S_WRITE_ACK: writes one byte and samples ACK
  - S_READ_DATA/S_READ_NACK: reads one byte and NACKs it
  - S_STOP: emits stop condition
  - S_DONE: emits one-cycle done pulse
[MODULE_INFO_END]
*/
module I2cMaster (
  input  logic       iClk,
  input  logic       iRstn,
  input  logic       iTick,
  input  logic       iStart,
  input  logic       iRead,
  input  logic [6:0] iSlaveAddr,
  input  logic [7:0] iTxData,
  input  logic       iSda,
  output logic [7:0] oRxData,
  output logic       oBusy,
  output logic       oDone,
  output logic       oAckError,
  output logic       oSclDriveLow,
  output logic       oSdaDriveLow
);

  typedef enum logic [3:0] {
    S_IDLE,
    S_START,
    S_ADDR,
    S_ADDR_ACK,
    S_WRITE_DATA,
    S_WRITE_ACK,
    S_READ_DATA,
    S_READ_NACK,
    S_STOP,
    S_DONE
  } state_e;

  localparam logic [2:0] LP_LAST_ADDR_BIT = 3'd7;
  localparam logic [2:0] LP_LAST_DATA_BIT = 3'd7;
  localparam logic [1:0] LP_PHASE_SETUP = 2'd0;
  localparam logic [1:0] LP_PHASE_RISE  = 2'd1;
  localparam logic [1:0] LP_PHASE_HIGH  = 2'd2;
  localparam logic [1:0] LP_PHASE_FALL  = 2'd3;

  state_e     rState;
  state_e     wNextState;
  logic [1:0] rPhase;
  logic [2:0] rBitCnt;
  logic [7:0] rAddrShift;
  logic [7:0] rTxShift;
  logic [7:0] rRxShift;
  logic       rReadOp;
  logic       rAckOk;
  logic       wPhaseDone;
  logic       wTimedState;

  function automatic logic [7:0] shift_in_bit(
    input logic [7:0] iData,
    input logic       iBit
  );
    shift_in_bit = {iData[6:0], iBit};
  endfunction

  assign wPhaseDone = iTick && (rPhase == LP_PHASE_FALL);
  assign wTimedState = (rState != S_IDLE) && (rState != S_DONE);

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
        if (iStart) begin
          wNextState = S_START;
        end
      end

      S_START: begin
        if (wPhaseDone) begin
          wNextState = S_ADDR;
        end
      end

      S_ADDR: begin
        if (wPhaseDone && (rBitCnt == '0)) begin
          wNextState = S_ADDR_ACK;
        end
      end

      S_ADDR_ACK: begin
        if (wPhaseDone) begin
          if (!rAckOk) begin
            wNextState = S_STOP;
          end
          else if (rReadOp) begin
            wNextState = S_READ_DATA;
          end
          else begin
            wNextState = S_WRITE_DATA;
          end
        end
      end

      S_WRITE_DATA: begin
        if (wPhaseDone && (rBitCnt == '0)) begin
          wNextState = S_WRITE_ACK;
        end
      end

      S_WRITE_ACK: begin
        if (wPhaseDone) begin
          wNextState = S_STOP;
        end
      end

      S_READ_DATA: begin
        if (wPhaseDone && (rBitCnt == '0)) begin
          wNextState = S_READ_NACK;
        end
      end

      S_READ_NACK: begin
        if (wPhaseDone) begin
          wNextState = S_STOP;
        end
      end

      S_STOP: begin
        if (wPhaseDone) begin
          wNextState = S_DONE;
        end
      end

      S_DONE: begin
        wNextState = S_IDLE;
      end

      default: begin
        wNextState = S_IDLE;
      end
    endcase
  end

  always_comb begin
    oBusy  = 1'b1;
    oDone  = 1'b0;
    oSclDriveLow = 1'b0;
    oSdaDriveLow = 1'b0;

    unique case (rState)
      S_IDLE: begin
        oBusy = 1'b0;
      end

      S_START: begin
        unique case (rPhase)
          LP_PHASE_SETUP: begin
            oSclDriveLow = 1'b0;
            oSdaDriveLow = 1'b0;
          end
          LP_PHASE_RISE: begin
            oSclDriveLow = 1'b0;
            oSdaDriveLow = 1'b1;
          end
          default: begin
            oSclDriveLow = 1'b1;
            oSdaDriveLow = 1'b1;
          end
        endcase
      end

      S_ADDR: begin
        oSclDriveLow = (rPhase == LP_PHASE_SETUP) || (rPhase == LP_PHASE_FALL);
        oSdaDriveLow = ~rAddrShift[7];
      end

      S_ADDR_ACK,
      S_WRITE_ACK,
      S_READ_DATA: begin
        oSclDriveLow = (rPhase == LP_PHASE_SETUP) || (rPhase == LP_PHASE_FALL);
      end

      S_WRITE_DATA: begin
        oSclDriveLow = (rPhase == LP_PHASE_SETUP) || (rPhase == LP_PHASE_FALL);
        oSdaDriveLow = ~rTxShift[7];
      end

      S_READ_NACK: begin
        oSclDriveLow = (rPhase == LP_PHASE_SETUP) || (rPhase == LP_PHASE_FALL);
      end

      S_STOP: begin
        unique case (rPhase)
          LP_PHASE_SETUP: begin
            oSclDriveLow = 1'b1;
            oSdaDriveLow = 1'b1;
          end
          LP_PHASE_RISE: begin
            oSclDriveLow = 1'b0;
            oSdaDriveLow = 1'b1;
          end
          default: begin
            oSclDriveLow = 1'b0;
            oSdaDriveLow = 1'b0;
          end
        endcase
      end

      S_DONE: begin
        oBusy = 1'b0;
        oDone = 1'b1;
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rPhase    <= '0;
      rBitCnt   <= '0;
      rAddrShift <= '0;
      rTxShift  <= '0;
      rRxShift  <= '0;
      rReadOp   <= 1'b0;
      rAckOk    <= 1'b1;
      oRxData   <= '0;
      oAckError <= 1'b0;
    end
    else begin
      if (wTimedState) begin
        if (iTick) begin
          if (wPhaseDone) begin
            rPhase <= LP_PHASE_SETUP;
          end
          else begin
            rPhase <= rPhase + 1'b1;
          end
        end
      end
      else begin
        rPhase <= '0;
      end

      unique case (rState)
        S_IDLE: begin
          if (iStart) begin
            rBitCnt    <= LP_LAST_ADDR_BIT;
            rAddrShift <= {iSlaveAddr, iRead};
            rTxShift   <= iTxData;
            rRxShift   <= '0;
            rReadOp    <= iRead;
            rAckOk     <= 1'b1;
            oAckError  <= 1'b0;
          end
        end

        S_ADDR: begin
          if (wPhaseDone) begin
            if (rBitCnt != '0) begin
              rBitCnt    <= rBitCnt - 1'b1;
              rAddrShift <= {rAddrShift[6:0], 1'b1};
            end
            else begin
              rBitCnt <= LP_LAST_DATA_BIT;
            end
          end
        end

        S_ADDR_ACK: begin
          if (iTick && (rPhase == LP_PHASE_HIGH)) begin
            rAckOk <= ~iSda;
          end

          if (wPhaseDone && !rAckOk) begin
            oAckError <= 1'b1;
          end
        end

        S_WRITE_DATA: begin
          if (wPhaseDone && (rBitCnt != '0)) begin
            rBitCnt  <= rBitCnt - 1'b1;
            rTxShift <= {rTxShift[6:0], 1'b1};
          end
        end

        S_WRITE_ACK: begin
          if (iTick && (rPhase == LP_PHASE_HIGH)) begin
            rAckOk <= ~iSda;
          end

          if (wPhaseDone && !rAckOk) begin
            oAckError <= 1'b1;
          end
        end

        S_READ_DATA: begin
          if (iTick && (rPhase == LP_PHASE_HIGH)) begin
            rRxShift <= shift_in_bit(rRxShift, iSda);

            if (rBitCnt == '0) begin
              oRxData <= shift_in_bit(rRxShift, iSda);
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
