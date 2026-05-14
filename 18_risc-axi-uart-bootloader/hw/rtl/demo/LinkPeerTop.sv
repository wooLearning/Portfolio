`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: LinkPeerTop
Role: Basys3 peer endpoint for the risc_stm32 SPI/UART/GPIO link demo
Summary:
  - Uses the same board-level port names as SocFpgaTop so the existing XDC can be reused
  - Samples SW[7:0] as the local response byte and shows the remote byte on LED[7:0]
  - Acts as an SPI mode-0 slave on the JC pins and a UART packet responder on GPIOB[0:1]
StateDescription:
  - SPI shift registers exchange one byte while CS0 is low
  - UART FSM replies to command packets with the current switch byte
[MODULE_INFO_END]
*/
module LinkPeerTop (
  input  logic        iClk100M,
  input  logic        iReset,
  input  logic [15:0] iSw,
  input  logic [3:0]  iBtn,
  output logic [15:0] oLed,
  inout  wire  [15:0] ioGpioB,
  input  logic        iSpiMiso,
  input  logic        oSpiSclk,
  output logic        oSpiMosi,
  input  logic [3:0]  oSpiCsN,
  inout  wire         ioI2cScl,
  inout  wire         ioI2cSda,
  input  logic        iUartRx,
  output logic        oUartTx
);

  typedef enum logic [1:0] {
    U_IDLE,
    U_WAIT_PAYLOAD,
    U_SEND_HEADER,
    U_SEND_PAYLOAD
  } uart_state_e;

  localparam logic [7:0] LP_UART_CMD_HEADER  = 8'h55;
  localparam logic [7:0] LP_UART_RESP_HEADER = 8'hAA;

  logic        wRstn;
  logic [7:0]  wRemoteData;
  logic [3:0]  wStatus;
  logic [7:0]  rSpiRemoteData;
  logic [3:0]  rSpiStatus;
  logic [7:0]  rUartRemoteData;
  logic [3:0]  rUartStatus;

  logic [2:0]  rSpiSclkSync;
  logic [2:0]  rSpiCsNSync;
  logic [1:0]  rSpiMosiSync;
  logic [2:0]  rSpiBitCnt;
  logic [7:0]  rSpiRxShift;
  logic [7:0]  rSpiTxShift;
  logic        wSpiActive;
  logic        wSpiRise;
  logic        wSpiFall;
  logic        wSpiCsFall;

  logic [15:0] rBaudDiv;
  logic [15:0] rBaudCnt;
  logic        rTick16x;
  logic [7:0]  wUartRxData;
  logic        wUartRxValid;
  logic        wUartFrameError;
  logic [7:0]  rUartTxData;
  logic        rUartTxValid;
  logic        wUartTxBusy;
  logic        wUartTxDone;
  uart_state_e rUartState;
  logic [7:0]  rUartHeader;

  assign wRstn = ~iReset;
  assign ioI2cScl = 1'bz;
  assign ioI2cSda = 1'bz;
  assign ioGpioB[15:1] = 'z;
  assign wSpiActive = !rSpiCsNSync[2];
  assign wSpiRise = wSpiActive && (rSpiSclkSync[2:1] == 2'b01);
  assign wSpiFall = wSpiActive && (rSpiSclkSync[2:1] == 2'b10);
  assign wSpiCsFall = (rSpiCsNSync[2:1] == 2'b10);
  assign oSpiMosi = wSpiActive ? rSpiTxShift[7] : 1'b0;
  assign wRemoteData = iSw[8] ? rUartRemoteData : rSpiRemoteData;
  assign wStatus = iSw[8] ? rUartStatus : rSpiStatus;

  OBUFT uPeerUartTxBuf (
    .I (oUartTx),
    .T (1'b0),
    .O (ioGpioB[0])
  );

  always_comb begin
    oLed = {7'd0, iSw[8], wRemoteData};
  end

  always_ff @(posedge iClk100M or negedge wRstn) begin
    if (!wRstn) begin
      rSpiSclkSync <= 3'b000;
      rSpiCsNSync  <= 3'b111;
      rSpiMosiSync <= 2'b00;
    end
    else begin
      rSpiSclkSync <= {rSpiSclkSync[1:0], oSpiSclk};
      rSpiCsNSync  <= {rSpiCsNSync[1:0], oSpiCsN[0]};
      rSpiMosiSync <= {rSpiMosiSync[0], iSpiMiso};
    end
  end

  always_ff @(posedge iClk100M or negedge wRstn) begin
    if (!wRstn) begin
      rSpiBitCnt  <= 3'd0;
      rSpiRxShift <= 8'd0;
      rSpiTxShift <= 8'd0;
      rSpiRemoteData <= 8'd0;
      rSpiStatus     <= 4'h1;
    end
    else begin
      if (wSpiCsFall) begin
        rSpiBitCnt  <= 3'd0;
        rSpiRxShift <= 8'd0;
        rSpiTxShift <= iSw[7:0];
        rSpiStatus   <= 4'h2;
      end
      else if (wSpiRise) begin
        rSpiRxShift <= {rSpiRxShift[6:0], rSpiMosiSync[1]};

        if (rSpiBitCnt == 3'd7) begin
          rSpiRemoteData <= {rSpiRxShift[6:0], rSpiMosiSync[1]};
          rSpiStatus <= 4'hF;
        end

        rSpiBitCnt <= rSpiBitCnt + 1'b1;
      end
      else if (wSpiFall) begin
        rSpiTxShift <= {rSpiTxShift[6:0], 1'b0};
      end

      if (iBtn[0]) begin
        rSpiRemoteData <= 8'd0;
        rSpiStatus <= 4'h1;
      end
    end
  end

  always_ff @(posedge iClk100M or negedge wRstn) begin
    if (!wRstn) begin
      rBaudDiv <= 16'd53;
      rBaudCnt <= 16'd0;
      rTick16x <= 1'b0;
    end
    else begin
      rTick16x <= 1'b0;

      if (rBaudCnt >= rBaudDiv) begin
        rBaudCnt <= 16'd0;
        rTick16x <= 1'b1;
      end
      else begin
        rBaudCnt <= rBaudCnt + 1'b1;
      end
    end
  end

  UartRx uUartRx (
    .iClk        (iClk100M),
    .iRstn       (wRstn),
    .iTick16x    (rTick16x),
    .iRx         (ioGpioB[1]),
    .oData       (wUartRxData),
    .oValid      (wUartRxValid),
    .oFrameError (wUartFrameError)
  );

  UartTx uUartTx (
    .iClk     (iClk100M),
    .iRstn    (wRstn),
    .iTick16x (rTick16x),
    .iData    (rUartTxData),
    .iValid   (rUartTxValid),
    .oTx      (oUartTx),
    .oBusy    (wUartTxBusy),
    .oDone    (wUartTxDone)
  );

  always_ff @(posedge iClk100M or negedge wRstn) begin
    if (!wRstn) begin
      rUartState   <= U_IDLE;
      rUartHeader  <= 8'd0;
      rUartTxData  <= 8'd0;
      rUartTxValid <= 1'b0;
      rUartRemoteData <= 8'd0;
      rUartStatus <= 4'h1;
    end
    else begin
      rUartTxValid <= 1'b0;

      if (wUartFrameError) begin
        rUartStatus <= 4'hE;
      end

      if (iBtn[0]) begin
        rUartRemoteData <= 8'd0;
        rUartStatus <= 4'h1;
      end

      unique case (rUartState)
        U_IDLE: begin
          if (wUartRxValid &&
              ((wUartRxData == LP_UART_CMD_HEADER) ||
               (wUartRxData == LP_UART_RESP_HEADER))) begin
            rUartHeader <= wUartRxData;
            rUartState <= U_WAIT_PAYLOAD;
          end
        end

        U_WAIT_PAYLOAD: begin
          if (wUartRxValid) begin
            rUartRemoteData <= wUartRxData;
            rUartStatus <= 4'hF;

            if (rUartHeader == LP_UART_CMD_HEADER) begin
              rUartState <= U_SEND_HEADER;
            end
            else begin
              rUartState <= U_IDLE;
            end
          end
        end

        U_SEND_HEADER: begin
          if (!wUartTxBusy) begin
            rUartTxData  <= LP_UART_RESP_HEADER;
            rUartTxValid <= 1'b1;
            rUartState   <= U_SEND_PAYLOAD;
          end
        end

        U_SEND_PAYLOAD: begin
          if (!wUartTxBusy && !rUartTxValid) begin
            rUartTxData  <= iSw[7:0];
            rUartTxValid <= 1'b1;
            rUartState   <= U_IDLE;
          end
        end

        default: begin
          rUartState <= U_IDLE;
        end
      endcase
    end
  end
endmodule
