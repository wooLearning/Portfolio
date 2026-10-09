`timescale 1ns/1ps
`default_nettype none

// APB3 frontend for a CAN/CAN FD core adapter, NOT a CAN protocol engine.
// All ports share iPclk. Standard 11-bit data frames only; no remote frames.
module apb_can_bridge #(
  parameter integer TX_DEPTH = 4,
  parameter integer RX_DEPTH = 8
) (
  input  wire logic                iPclk,
  input  wire logic                iPresetN,
  input  wire logic                iPsel,
  input  wire logic                iPenable,
  input  wire logic                iPwrite,
  input  wire logic [11:0]         iPaddr,
  input  wire logic [31:0]         iPwdata,
  output      logic [31:0]         oPrdata,
  output      logic                oPready,
  output      logic                oPslverr,
  output      logic                oIrq,

  // Keep valid and the complete frame stable until ready is sampled high.
  output      logic                oCanTxValid,
  input  wire logic                iCanTxReady,
  output      logic [10:0]         oCanTxId,
  output      logic [3:0]          oCanTxDlc,
  output      logic                oCanTxFd,
  output      logic                oCanTxBrs,
  output      logic [511:0]        oCanTxData,
  // Completion belongs to the sole outstanding request; error qualifies done.
  input  wire logic                iCanTxDone,
  input  wire logic                iCanTxError,

  // One valid pulse per complete, validated incoming frame. No backpressure.
  input  wire logic                iCanRxValid,
  input  wire logic [10:0]         iCanRxId,
  input  wire logic [3:0]          iCanRxDlc,
  input  wire logic                iCanRxFd,
  input  wire logic                iCanRxBrs,
  input  wire logic [511:0]        iCanRxData
);
  localparam integer FRAME_W = 529; // {id[10:0], brs, fd, dlc[3:0], data[511:0]}
  localparam integer TX_COUNT_W = $clog2(TX_DEPTH + 1);
  localparam integer RX_COUNT_W = $clog2(RX_DEPTH + 1);
  localparam logic [11:0] ADDR_VERSION       = 12'h000;
  localparam logic [11:0] ADDR_STATUS        = 12'h004;
  localparam logic [11:0] ADDR_IRQ_ENABLE    = 12'h008;
  localparam logic [11:0] ADDR_IRQ_STATUS    = 12'h00c;
  localparam logic [11:0] ADDR_TX_ID         = 12'h010;
  localparam logic [11:0] ADDR_TX_CTRL       = 12'h014;
  localparam logic [11:0] ADDR_TX_PUSH       = 12'h018;
  localparam logic [11:0] ADDR_RX_POP        = 12'h01c;
  localparam logic [11:0] ADDR_RX_ID         = 12'h020;
  localparam logic [11:0] ADDR_RX_CTRL       = 12'h024;
  localparam logic [11:0] ADDR_TX_DATA_FIRST = 12'h040;
  localparam logic [11:0] ADDR_TX_DATA_LAST  = 12'h07c;
  localparam logic [11:0] ADDR_RX_DATA_FIRST = 12'h080;
  localparam logic [11:0] ADDR_RX_DATA_LAST  = 12'h0bc;

  // Occupancy fields in STATUS are 8 bits wide.
  // synthesis translate_off
  initial begin
    if (TX_DEPTH < 1 || TX_DEPTH > 255 || RX_DEPTH < 1 || RX_DEPTH > 255)
      $fatal(1, "TX_DEPTH and RX_DEPTH must be in 1..255");
  end
  // synthesis translate_on

  // Sequential storage (r*) and combinational datapath/control signals (w*).
  logic [10:0] rTxId;
  logic [5:0] rTxCtrl;
  logic [511:0] rTxData;
  logic [15:0] rTxWordWritten;
  logic [3:0] rIrqEnable;
  logic [2:0] rIrqSticky; // [0] TX done, [1] TX error, [2] RX overflow
  logic wTxBusy;
  logic wApbError;
  logic [511:0] wTxPayload;
  logic [15:0] wTxRequiredWords;
  logic wApbAccess;
  logic wApbWrite;
  logic wTxDataSel;
  logic wRxDataSel;
  logic [3:0] wDataWordIndex;
  logic [FRAME_W-1:0] wTxFrame, wRxFrame;
  logic wTxFull, wTxEmpty, wTxPushReady;
  logic wRxFull, wRxEmpty, wRxPushReady;
  logic [TX_COUNT_W-1:0] wTxCount;
  logic [RX_COUNT_W-1:0] wRxCount;
  logic wTxPush;
  logic wRxPop;
  logic wTxAccept;
  logic wTxComplete;
  logic wRxOverflow;
  logic [3:0] wIrqStatus;
  logic [2:0] wIrqClear;
  logic [2:0] wIrqEvents;
  logic [6:0] wTxLengthBytes;
  logic wTxFormatOk;
  logic wTxWordsOk;
  integer byte_idx, word_idx;

  function automatic logic [6:0] dlc_bytes(input logic [3:0] dlc);
    begin
      case (dlc)
        4'd9: dlc_bytes = 7'd12;
        4'd10: dlc_bytes = 7'd16;
        4'd11: dlc_bytes = 7'd20;
        4'd12: dlc_bytes = 7'd24;
        4'd13: dlc_bytes = 7'd32;
        4'd14: dlc_bytes = 7'd48;
        4'd15: dlc_bytes = 7'd64;
        default: dlc_bytes = {3'b000, dlc};
      endcase
    end
  endfunction

  // APB access, frame format, FIFO handshake and interrupt equations.
  assign wApbAccess = iPsel && iPenable;
  assign wApbWrite = wApbAccess && iPwrite && !wApbError;
  assign wTxDataSel = (iPaddr >= ADDR_TX_DATA_FIRST) && (iPaddr <= ADDR_TX_DATA_LAST);
  assign wRxDataSel = (iPaddr >= ADDR_RX_DATA_FIRST) && (iPaddr <= ADDR_RX_DATA_LAST);
  assign wDataWordIndex = iPaddr[5:2];
  assign wTxPush = wApbWrite && (iPaddr == ADDR_TX_PUSH);
  assign wRxPop = wApbWrite && (iPaddr == ADDR_RX_POP);
  assign wRxOverflow = iCanRxValid && !wRxPushReady;
  assign wIrqStatus = {rIrqSticky, !wRxEmpty};
  assign wIrqClear = (wApbWrite && (iPaddr == ADDR_IRQ_STATUS))
    ? iPwdata[3:1] : 3'b000;
  assign wIrqEvents = {wRxOverflow,
    wTxComplete && iCanTxError, wTxComplete && !iCanTxError};
  assign wTxLengthBytes = dlc_bytes(rTxCtrl[3:0]);
  assign wTxFormatOk = rTxCtrl[4] || (!rTxCtrl[5] && rTxCtrl[3:0] <= 4'd8);
  assign wTxWordsOk = ((rTxWordWritten & wTxRequiredWords) == wTxRequiredWords);
  assign oPready = 1'b1; // No APB wait states, including rejected commands.
  assign oPslverr = wApbAccess && wApbError;
  assign oIrq = |(wIrqStatus & rIrqEnable);
  assign {oCanTxId, oCanTxBrs, oCanTxFd, oCanTxDlc, oCanTxData} = wTxFrame;

  // Zero bytes outside the declared length; require fresh writes for each frame.
  always_comb begin
    wTxRequiredWords = '0;
    wTxPayload = '0;
    for (word_idx = 0; word_idx < 16; word_idx = word_idx + 1)
      if (word_idx * 4 < wTxLengthBytes) wTxRequiredWords[word_idx] = 1'b1;
    for (byte_idx = 0; byte_idx < 64; byte_idx = byte_idx + 1)
      if (byte_idx < wTxLengthBytes)
        wTxPayload[byte_idx*8 +: 8] = rTxData[byte_idx*8 +: 8];
  end

  // Decode both legal access directions and command preconditions.
  // Rejected writes have no side effects; commands cannot be read back.
  always_comb begin
    oPrdata = '0;
    wApbError = (iPaddr[1:0] != 0);
    if (wTxDataSel) begin
      oPrdata = rTxData[wDataWordIndex*32 +: 32];
    end
    else if (wRxDataSel) begin
      oPrdata = wRxFrame[wDataWordIndex*32 +: 32];
      if (iPwrite || wRxEmpty) wApbError = 1'b1;
    end
    else begin
      case (iPaddr)
        ADDR_VERSION: begin
          oPrdata = 32'h0001_0000;
          if (iPwrite) wApbError = 1'b1;
        end
        ADDR_STATUS: begin
          oPrdata[4:0] = {wTxBusy, wRxEmpty, wRxFull, wTxEmpty, wTxFull};
          oPrdata[15:8] = 8'(wTxCount);
          oPrdata[23:16] = 8'(wRxCount);
          if (iPwrite) wApbError = 1'b1;
        end
        ADDR_IRQ_ENABLE: begin
          oPrdata = {28'b0, rIrqEnable};
          if (iPwrite && |iPwdata[31:4]) wApbError = 1'b1;
        end
        ADDR_IRQ_STATUS: begin
          oPrdata = {28'b0, wIrqStatus};
          if (iPwrite && |iPwdata[31:4]) wApbError = 1'b1;
        end
        ADDR_TX_ID: begin
          oPrdata = {21'b0, rTxId};
          if (iPwrite && |iPwdata[31:11]) wApbError = 1'b1;
        end
        ADDR_TX_CTRL: begin
          oPrdata = {26'b0, rTxCtrl};
          if (iPwrite && |iPwdata[31:6]) wApbError = 1'b1;
        end
        ADDR_TX_PUSH: begin
          if (!iPwrite || iPwdata != 32'd1 || !wTxPushReady ||
            !wTxFormatOk || !wTxWordsOk) wApbError = 1'b1;
        end
        ADDR_RX_POP: begin
          if (!iPwrite || iPwdata != 32'd1 || wRxEmpty) wApbError = 1'b1;
        end
        ADDR_RX_ID: begin
          oPrdata = {21'b0, wRxFrame[528:518]};
          if (iPwrite || wRxEmpty) wApbError = 1'b1;
        end
        ADDR_RX_CTRL: begin
          oPrdata = {26'b0, wRxFrame[517:512]};
          if (iPwrite || wRxEmpty) wApbError = 1'b1;
        end
        default: wApbError = 1'b1;
      endcase
    end
  end

  frame_fifo #(
    .DATA_W(FRAME_W),
    .DEPTH(TX_DEPTH)
  ) u_tx_fifo (
    .iClk(iPclk),
    .iRstN(iPresetN),
    .iPush(wTxPush),
    .iData({rTxId, rTxCtrl, wTxPayload}),
    .iPop(wTxAccept),
    .oData(wTxFrame),
    .oFull(wTxFull),
    .oEmpty(wTxEmpty),
    .oPushReady(wTxPushReady),
    .oCount(wTxCount)
  );
  frame_fifo #(
    .DATA_W(FRAME_W),
    .DEPTH(RX_DEPTH)
  ) u_rx_fifo (
    .iClk(iPclk),
    .iRstN(iPresetN),
    .iPush(iCanRxValid),
    .iData({iCanRxId, iCanRxBrs, iCanRxFd, iCanRxDlc, iCanRxData}),
    .iPop(wRxPop),
    .oData(wRxFrame),
    .oFull(wRxFull),
    .oEmpty(wRxEmpty),
    .oPushReady(wRxPushReady),
    .oCount(wRxCount)
  );

  can_tx_ctrl u_tx_ctrl (
    .iClk(iPclk),
    .iRstN(iPresetN),
    .iFifoEmpty(wTxEmpty),
    .iCoreReady(iCanTxReady),
    .iCoreDone(iCanTxDone),
    .oTxValid(oCanTxValid),
    .oTxPop(wTxAccept),
    .oTxComplete(wTxComplete),
    .oTxBusy(wTxBusy)
  );

  // APB staging registers and sticky event state.
  always_ff @(posedge iPclk or negedge iPresetN) begin
    if (!iPresetN) begin
      rTxId <= '0;
      rTxCtrl <= '0;
      rTxData <= '0;
      rTxWordWritten <= '0;
      rIrqEnable <= '0;
      rIrqSticky <= '0;
    end
    else begin
      // New hardware events win over software clearing on the same edge.
      rIrqSticky <= (rIrqSticky & ~wIrqClear) | wIrqEvents;
      if (wApbWrite) begin
        if (wTxDataSel) begin
          rTxData[wDataWordIndex*32 +: 32] <= iPwdata;
          rTxWordWritten[wDataWordIndex] <= 1'b1;
        end
        case (iPaddr)
          ADDR_TX_ID: rTxId <= iPwdata[10:0];
          ADDR_TX_CTRL: rTxCtrl <= iPwdata[5:0];
          ADDR_IRQ_ENABLE: rIrqEnable <= iPwdata[3:0];
          ADDR_TX_PUSH: rTxWordWritten <= '0;
          default: begin end
        endcase
      end
    end
  end
endmodule

`default_nettype wire
