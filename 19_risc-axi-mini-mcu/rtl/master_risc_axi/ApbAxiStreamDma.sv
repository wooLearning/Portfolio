`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbAxiStreamDma
Role: APB-controlled AXI-Stream byte DMA
Summary:
  - Exposes APB control/status registers for stream transfers
  - Stores stream input bytes into an internal image buffer
  - Replays the internal image buffer as an AXI-Stream source
  - Tracks programmed byte count and raises done/error interrupts
StateDescription:
  - S_IDLE waits for START
  - S_RUN receives into or transmits from the internal buffer while counting bytes
[MODULE_INFO_END]
*/
module ApbAxiStreamDma #(
  parameter integer P_BUFFER_BYTES = 16384
) (
  input  logic        iPclk,
  input  logic        iPresetn,
  input  logic        iPSEL,
  input  logic        iPENABLE,
  input  logic        iPWRITE,
  input  logic [11:0] iPADDR,
  input  logic [31:0] iPWDATA,
  input  logic [3:0]  iPSTRB,
  output logic [31:0] oPRDATA,
  output logic        oPREADY,
  output logic        oPSLVERR,
  output logic        oDoneIrq,
  output logic        oErrorIrq,

  input  logic [7:0]  iS_TDATA,
  input  logic        iS_TVALID,
  output logic        oS_TREADY,
  input  logic        iS_TLAST,
  output logic [7:0]  oM_TDATA,
  output logic        oM_TVALID,
  input  logic        iM_TREADY,
  output logic        oM_TLAST
);

  localparam logic [7:0] LP_ADDR_CTRL      = 8'h00;
  localparam logic [7:0] LP_ADDR_STATUS    = 8'h04;
  localparam logic [7:0] LP_ADDR_LEN_BYTES = 8'h08;
  localparam logic [7:0] LP_ADDR_COUNT     = 8'h0C;
  localparam logic [7:0] LP_ADDR_CLEAR     = 8'h10;
  localparam logic [7:0] LP_ADDR_BUF_ADDR  = 8'h14;
  localparam logic [7:0] LP_ADDR_BUF_DATA  = 8'h18;
  localparam integer LP_ADDR_WIDTH = (P_BUFFER_BYTES <= 2) ? 1 : $clog2(P_BUFFER_BYTES);
  localparam logic [31:0] LP_BUFFER_BYTES_U32 = P_BUFFER_BYTES;

  typedef enum logic {
    S_IDLE,
    S_RUN
  } state_e;

  state_e      rState;
  logic        rIrqEnable;
  logic        rDirection;
  logic        rDoneSticky;
  logic        rErrorSticky;
  logic [31:0] rLenBytes;
  logic [31:0] rCountBytes;
  logic [31:0] rBufAddr;
  logic [7:0]  rBuffer [0:P_BUFFER_BYTES-1];
  logic [7:0]  rTxData;
  logic        rTxValid;
  logic [7:0]  rBufReadData;
  logic        wWrite;
  logic        wStartPulse;
  logic        wClearDone;
  logic        wClearError;
  logic        wBusy;
  logic        wReceiveMode;
  logic        wTransmitMode;
  logic        wStartInRange;
  logic [31:0] wEndAddr;
  logic [31:0] wCurAddr;
  logic [31:0] wTxReadAddr;
  logic [LP_ADDR_WIDTH-1:0] wCurIndex;
  logic [LP_ADDR_WIDTH-1:0] wTxReadIndex;
  logic [LP_ADDR_WIDTH-1:0] wDebugIndex;
  logic [LP_ADDR_WIDTH-1:0] wBufReadIndex;
  logic [LP_ADDR_WIDTH-1:0] wBufWriteIndex;
  logic [7:0]  wBufWriteData;
  logic        wBufWriteEn;
  logic        wDebugWrite;
  logic        wSHandshake;
  logic        wMHandshake;
  logic        wLastBeat;

  assign wWrite = iPSEL && iPENABLE && iPWRITE;
  assign wStartPulse = wWrite && (iPADDR[7:0] == LP_ADDR_CTRL) &&
                       iPSTRB[0] && iPWDATA[0] && !wBusy;
  assign wClearDone = wWrite && (iPADDR[7:0] == LP_ADDR_CLEAR) &&
                      iPSTRB[0] && iPWDATA[1];
  assign wClearError = wWrite && (iPADDR[7:0] == LP_ADDR_CLEAR) &&
                       iPSTRB[0] && iPWDATA[2];
  assign wBusy = (rState == S_RUN);
  assign wReceiveMode = (rState == S_RUN) && !rDirection;
  assign wTransmitMode = (rState == S_RUN) && rDirection;
  assign wEndAddr = rBufAddr + rLenBytes;
  assign wStartInRange = (rLenBytes != 32'd0) &&
                         (rBufAddr < LP_BUFFER_BYTES_U32) &&
                         (rLenBytes <= LP_BUFFER_BYTES_U32) &&
                         (wEndAddr <= LP_BUFFER_BYTES_U32) &&
                         (wEndAddr >= rBufAddr);
  assign wCurAddr = rBufAddr + rCountBytes;
  assign wTxReadAddr = wCurAddr + ((rTxValid && iM_TREADY && !wLastBeat) ? 32'd1 : 32'd0);
  assign wCurIndex = wCurAddr[LP_ADDR_WIDTH-1:0];
  assign wTxReadIndex = wTxReadAddr[LP_ADDR_WIDTH-1:0];
  assign wDebugIndex = rBufAddr[LP_ADDR_WIDTH-1:0];
  assign wDebugWrite = wWrite && (iPADDR[7:0] == LP_ADDR_BUF_DATA) &&
                       !wBusy && (rBufAddr < LP_BUFFER_BYTES_U32) && iPSTRB[0];
  assign wBufWriteEn = (wReceiveMode && wSHandshake) || wDebugWrite;
  assign wBufWriteIndex = (wReceiveMode && wSHandshake) ? wCurIndex : wDebugIndex;
  assign wBufWriteData = (wReceiveMode && wSHandshake) ? iS_TDATA : iPWDATA[7:0];
  assign wBufReadIndex = wTransmitMode ? wTxReadIndex : wDebugIndex;
  assign oPREADY = 1'b1;
  assign oPSLVERR = 1'b0;
  assign oDoneIrq = rIrqEnable && rDoneSticky;
  assign oErrorIrq = rIrqEnable && rErrorSticky;

  assign wLastBeat = (rLenBytes != 32'd0) && (rCountBytes == (rLenBytes - 32'd1));
  assign oS_TREADY = wReceiveMode;
  assign oM_TDATA  = rTxData;
  assign oM_TVALID = wTransmitMode && rTxValid;
  assign oM_TLAST  = wLastBeat && oM_TVALID;
  assign wSHandshake = iS_TVALID && oS_TREADY;
  assign wMHandshake = oM_TVALID && iM_TREADY;

  always_comb begin
    oPRDATA = 32'd0;

    unique case (iPADDR[7:0])
      LP_ADDR_CTRL:      oPRDATA = {29'd0, rDirection, rIrqEnable, 1'b0};
      LP_ADDR_STATUS:    oPRDATA = {27'd0, wStartInRange, rErrorSticky,
                                    rDoneSticky, wBusy};
      LP_ADDR_LEN_BYTES: oPRDATA = rLenBytes;
      LP_ADDR_COUNT:     oPRDATA = rCountBytes;
      LP_ADDR_BUF_ADDR:  oPRDATA = rBufAddr;
      LP_ADDR_BUF_DATA:  oPRDATA = {24'd0, rBufReadData};
      default:           oPRDATA = 32'd0;
    endcase
  end

  always_ff @(posedge iPclk) begin
    if (wBufWriteEn) begin
      rBuffer[wBufWriteIndex] <= wBufWriteData;
    end

    if (wTransmitMode && (!rTxValid || (rTxValid && iM_TREADY && !wLastBeat))) begin
      rTxData <= rBuffer[wTxReadIndex];
    end
    else if (!wTransmitMode) begin
      rBufReadData <= rBuffer[wBufReadIndex];
    end
  end

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rState       <= S_IDLE;
      rIrqEnable   <= 1'b0;
      rDirection   <= 1'b0;
      rDoneSticky  <= 1'b0;
      rErrorSticky <= 1'b0;
      rLenBytes    <= 32'd0;
      rCountBytes  <= 32'd0;
      rBufAddr     <= 32'd0;
      rTxValid     <= 1'b0;
    end
    else begin
      if (wClearDone) begin
        rDoneSticky <= 1'b0;
      end

      if (wClearError) begin
        rErrorSticky <= 1'b0;
      end

      if (wWrite) begin
        unique case (iPADDR[7:0])
          LP_ADDR_CTRL: begin
            if (iPSTRB[0]) begin
              rIrqEnable <= iPWDATA[1];
              rDirection <= iPWDATA[2];
            end
          end

          LP_ADDR_LEN_BYTES: begin
            if (!wBusy) begin
              rLenBytes <= iPWDATA;
            end
          end

          LP_ADDR_BUF_ADDR: begin
            if (!wBusy) begin
              rBufAddr <= iPWDATA;
            end
          end

          default: begin
          end
        endcase
      end

      unique case (rState)
        S_IDLE: begin
          if (wStartPulse) begin
            rDoneSticky <= 1'b0;
            rErrorSticky <= 1'b0;
            rCountBytes <= 32'd0;
            rTxValid <= 1'b0;

            if (wStartInRange) begin
              rState <= S_RUN;
            end
            else begin
              rErrorSticky <= 1'b1;
            end
          end
        end

        S_RUN: begin
          if (wTransmitMode && (!rTxValid || (rTxValid && iM_TREADY && !wLastBeat))) begin
            rTxValid <= 1'b1;
          end

          if (wReceiveMode && wSHandshake) begin
            if (iS_TLAST && !wLastBeat) begin
              rErrorSticky <= 1'b1;
              rState <= S_IDLE;
            end
            else begin
              if (wLastBeat) begin
                rDoneSticky <= 1'b1;
                rState <= S_IDLE;
              end

              rCountBytes <= rCountBytes + 32'd1;
            end
          end
          else if (wTransmitMode && wMHandshake) begin
            if (wLastBeat) begin
              rDoneSticky <= 1'b1;
              rState <= S_IDLE;
              rTxValid <= 1'b0;
            end

            rCountBytes <= rCountBytes + 32'd1;
          end
        end

        default: begin
          rState <= S_IDLE;
        end
      endcase
    end
  end

endmodule
