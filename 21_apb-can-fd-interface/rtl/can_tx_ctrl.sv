`timescale 1ns/1ps
`default_nettype none

// One outstanding frame request. Protocol-level retry belongs to the CAN IP.
module can_tx_ctrl (
  input  wire logic                iClk,
  input  wire logic                iRstN,
  input  wire logic                iFifoEmpty,
  input  wire logic                iCoreReady,
  input  wire logic                iCoreDone,
  output      logic                oTxValid,
  output      logic                oTxPop,
  output      logic                oTxComplete,
  output      logic                oTxBusy
);
  typedef enum logic [1:0] {
    TX_IDLE      = 2'd0,
    TX_SEND      = 2'd1,
    TX_WAIT_DONE = 2'd2
  } tx_state_t;

  tx_state_t rCurState;
  tx_state_t wNxtState;

  /* Block1: state register */
  always_ff @(posedge iClk or negedge iRstN) begin
    if (!iRstN) begin
      rCurState <= TX_IDLE;
    end
    else begin
      rCurState <= wNxtState;
    end
  end

  /* Block2: next state decision */
  always_comb begin
    wNxtState = rCurState;
    case (rCurState)
      TX_IDLE: begin
        if (!iFifoEmpty) wNxtState = TX_SEND;
      end
      TX_SEND: begin
        if (iCoreReady) begin
          if (iCoreDone) wNxtState = TX_IDLE;
          else          wNxtState = TX_WAIT_DONE;
        end
      end
      TX_WAIT_DONE: begin
        if (iCoreDone) wNxtState = TX_IDLE;
      end
      default: wNxtState = TX_IDLE;
    endcase
  end

  /* Block3: output and control register */
  // These outputs are combinational; APB payload registers live in the parent.
  // Pop and completion are sampled by the parent only on a rising clock edge.
  always_comb begin
    oTxValid    = 1'b0;
    oTxPop      = 1'b0;
    oTxComplete = 1'b0;
    oTxBusy     = 1'b0;
    case (rCurState)
      TX_IDLE: begin end
      TX_SEND: begin
        oTxValid    = 1'b1;
        oTxBusy     = 1'b1;
        oTxPop      = iCoreReady;
        oTxComplete = iCoreReady && iCoreDone;
      end
      TX_WAIT_DONE: begin
        oTxBusy     = 1'b1;
        oTxComplete = iCoreDone;
      end
      default: begin end
    endcase
  end
endmodule

`default_nettype wire
