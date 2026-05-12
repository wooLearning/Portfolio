`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbSubsystem
Role: APB peripheral subsystem behind the AXI-Lite-to-APB bridge
Summary:
  - Decodes timer, GPIO, SPI, I2C, UART, stream DMA, and PLIC register windows
  - Keeps low-speed peripherals APB-based while the SoC fabric is AXI
  - Replaces the old memory-mapped DMA with APB-controlled AXI-Stream DMA
StateDescription:
  - Peripheral state lives inside each APB slave
[MODULE_INFO_END]
*/
module ApbSubsystem (
  input  logic        iPclk,
  input  logic        iPresetn,
  input  logic        iPSEL,
  input  logic        iPENABLE,
  input  logic        iPWRITE,
  input  logic [31:0] iPADDR,
  input  logic [31:0] iPWDATA,
  input  logic [3:0]  iPSTRB,
  input  logic [7:0]  iPeripheralIrq,
  input  logic [15:0] iGpioAIn,
  input  logic [15:0] iGpioBIn,
  input  logic [15:0] iGpioCIn,
  input  logic        iSpiMiso,
  input  logic        iI2cSda,
  input  logic        iUartRx,
  output logic [15:0] oGpioAOut,
  output logic [15:0] oGpioADir,
  output logic [15:0] oGpioBOut,
  output logic [15:0] oGpioBDir,
  output logic        oSpiSclk,
  output logic        oSpiMosi,
  output logic [3:0]  oSpiCsN,
  output logic        oI2cSclDriveLow,
  output logic        oI2cSdaDriveLow,
  output logic        oUartTx,
  output logic [31:0] oPRDATA,
  output logic        oPREADY,
  output logic        oPSLVERR,
  output logic        oTimerIrq,
  output logic        oExternalIrq
);

  logic wTimerSel;
  logic wGpioASel;
  logic wGpioBSel;
  logic wGpioCSel;
  logic wSpiSel;
  logic wI2cSel;
  logic wUartSel;
  logic wDmaSel;
  logic wIrqCtrlSel;
  logic [31:0] wTimerPRDATA;
  logic        wTimerPREADY;
  logic        wTimerPSLVERR;
  logic [31:0] wGpioAPRDATA;
  logic        wGpioAPREADY;
  logic        wGpioAPSLVERR;
  logic [31:0] wGpioBPRDATA;
  logic        wGpioBPREADY;
  logic        wGpioBPSLVERR;
  logic [15:0] wGpioCOut;
  logic [15:0] wGpioCDir;
  logic [31:0] wGpioCPRDATA;
  logic        wGpioCPREADY;
  logic        wGpioCPSLVERR;
  logic [31:0] wSpiPRDATA;
  logic        wSpiPREADY;
  logic        wSpiPSLVERR;
  logic        wSpiTxIrq;
  logic        wSpiRxIrq;
  logic        wSpiTxDmaReq;
  logic        wSpiRxDmaReq;
  logic [31:0] wI2cPRDATA;
  logic        wI2cPREADY;
  logic        wI2cPSLVERR;
  logic [31:0] wUartPRDATA;
  logic        wUartPREADY;
  logic        wUartPSLVERR;
  logic        wUartTxIrq;
  logic        wUartRxIrq;
  logic        wUartTxDmaReq;
  logic        wUartRxDmaReq;
  logic [31:0] wDmaPRDATA;
  logic        wDmaPREADY;
  logic        wDmaPSLVERR;
  logic        wDmaDoneIrq;
  logic        wDmaErrorIrq;
  logic [7:0]  wUartRxStreamData;
  logic        wUartRxStreamValid;
  logic        wUartRxStreamReady;
  logic [7:0]  wDmaTxStreamData;
  logic        wDmaTxStreamValid;
  logic        wDmaTxStreamReady;
  logic        wDmaTxStreamLast;
  logic [31:0] wIrqPRDATA;
  logic        wIrqPREADY;
  logic        wIrqPSLVERR;
  logic [7:0]  wIrqSources;

  assign wTimerSel   = iPSEL && (iPADDR[19:16] == 4'h0);
  assign wGpioASel   = iPSEL && (iPADDR[19:16] == 4'h1);
  assign wGpioBSel   = iPSEL && (iPADDR[19:16] == 4'h2);
  assign wSpiSel     = iPSEL && (iPADDR[19:16] == 4'h3);
  assign wI2cSel     = iPSEL && (iPADDR[19:16] == 4'h4);
  assign wUartSel    = iPSEL && (iPADDR[19:16] == 4'h5);
  assign wDmaSel     = iPSEL && (iPADDR[19:16] == 4'h6);
  assign wGpioCSel   = iPSEL && (iPADDR[19:16] == 4'h7);
  assign wIrqCtrlSel = iPSEL && (iPADDR[19:16] == 4'hF);
  assign wIrqSources = iPeripheralIrq |
                       {1'b0, wDmaErrorIrq, wDmaDoneIrq, 1'b0,
                        wSpiRxIrq, wSpiTxIrq, wUartRxIrq, wUartTxIrq};

  ApbTimer uApbTimer (
    .iPclk      (iPclk),
    .iPresetn   (iPresetn),
    .iPSEL      (wTimerSel),
    .iPENABLE   (iPENABLE),
    .iPWRITE    (iPWRITE),
    .iPADDR     (iPADDR[11:0]),
    .iPWDATA    (iPWDATA),
    .iPSTRB     (iPSTRB),
    .oPRDATA    (wTimerPRDATA),
    .oPREADY    (wTimerPREADY),
    .oPSLVERR   (wTimerPSLVERR),
    .oTimerIrq  (oTimerIrq)
  );

  ApbGpio #(.P_GPIO_WIDTH(16)) uApbGpioA (
    .iPclk      (iPclk),
    .iPresetn   (iPresetn),
    .iPSEL      (wGpioASel),
    .iPENABLE   (iPENABLE),
    .iPWRITE    (iPWRITE),
    .iPADDR     (iPADDR[11:0]),
    .iPWDATA    (iPWDATA),
    .iPSTRB     (iPSTRB),
    .iGpioIn    (iGpioAIn),
    .oGpioOut   (oGpioAOut),
    .oGpioDir   (oGpioADir),
    .oPRDATA    (wGpioAPRDATA),
    .oPREADY    (wGpioAPREADY),
    .oPSLVERR   (wGpioAPSLVERR)
  );

  ApbGpio #(.P_GPIO_WIDTH(16)) uApbGpioB (
    .iPclk      (iPclk),
    .iPresetn   (iPresetn),
    .iPSEL      (wGpioBSel),
    .iPENABLE   (iPENABLE),
    .iPWRITE    (iPWRITE),
    .iPADDR     (iPADDR[11:0]),
    .iPWDATA    (iPWDATA),
    .iPSTRB     (iPSTRB),
    .iGpioIn    (iGpioBIn),
    .oGpioOut   (oGpioBOut),
    .oGpioDir   (oGpioBDir),
    .oPRDATA    (wGpioBPRDATA),
    .oPREADY    (wGpioBPREADY),
    .oPSLVERR   (wGpioBPSLVERR)
  );

  ApbGpio #(.P_GPIO_WIDTH(16)) uApbGpioC (
    .iPclk      (iPclk),
    .iPresetn   (iPresetn),
    .iPSEL      (wGpioCSel),
    .iPENABLE   (iPENABLE),
    .iPWRITE    (iPWRITE),
    .iPADDR     (iPADDR[11:0]),
    .iPWDATA    (iPWDATA),
    .iPSTRB     (iPSTRB),
    .iGpioIn    (iGpioCIn),
    .oGpioOut   (wGpioCOut),
    .oGpioDir   (wGpioCDir),
    .oPRDATA    (wGpioCPRDATA),
    .oPREADY    (wGpioCPREADY),
    .oPSLVERR   (wGpioCPSLVERR)
  );

  ApbSpi uApbSpi (
    .iPclk      (iPclk),
    .iPresetn   (iPresetn),
    .iPSEL      (wSpiSel),
    .iPENABLE   (iPENABLE),
    .iPWRITE    (iPWRITE),
    .iPADDR     (iPADDR[11:0]),
    .iPWDATA    (iPWDATA),
    .iPSTRB     (iPSTRB),
    .iSpiMiso   (iSpiMiso),
    .oSpiSclk   (oSpiSclk),
    .oSpiMosi   (oSpiMosi),
    .oSpiCsN    (oSpiCsN),
    .oPRDATA    (wSpiPRDATA),
    .oPREADY    (wSpiPREADY),
    .oPSLVERR   (wSpiPSLVERR),
    .oTxIrq     (wSpiTxIrq),
    .oRxIrq     (wSpiRxIrq),
    .oTxDmaReq  (wSpiTxDmaReq),
    .oRxDmaReq  (wSpiRxDmaReq),
    .iTxS_TDATA (wDmaTxStreamData),
    .iTxS_TVALID(wDmaTxStreamValid),
    .oTxS_TREADY(wDmaTxStreamReady)
  );

  ApbI2c uApbI2c (
    .iPclk      (iPclk),
    .iPresetn   (iPresetn),
    .iPSEL      (wI2cSel),
    .iPENABLE   (iPENABLE),
    .iPWRITE    (iPWRITE),
    .iPADDR     (iPADDR[11:0]),
    .iPWDATA    (iPWDATA),
    .iPSTRB     (iPSTRB),
    .iI2cSda    (iI2cSda),
    .oI2cSclDriveLow (oI2cSclDriveLow),
    .oI2cSdaDriveLow (oI2cSdaDriveLow),
    .oPRDATA    (wI2cPRDATA),
    .oPREADY    (wI2cPREADY),
    .oPSLVERR   (wI2cPSLVERR)
  );

  ApbUart uApbUart (
    .iPclk      (iPclk),
    .iPresetn   (iPresetn),
    .iPSEL      (wUartSel),
    .iPENABLE   (iPENABLE),
    .iPWRITE    (iPWRITE),
    .iPADDR     (iPADDR[11:0]),
    .iPWDATA    (iPWDATA),
    .iPSTRB     (iPSTRB),
    .iUartRx    (iUartRx),
    .oUartTx    (oUartTx),
    .oPRDATA    (wUartPRDATA),
    .oPREADY    (wUartPREADY),
    .oPSLVERR   (wUartPSLVERR),
    .oTxIrq     (wUartTxIrq),
    .oRxIrq     (wUartRxIrq),
    .oTxDmaReq  (wUartTxDmaReq),
    .oRxDmaReq  (wUartRxDmaReq),
    .oRxM_TDATA (wUartRxStreamData),
    .oRxM_TVALID(wUartRxStreamValid),
    .iRxM_TREADY(wUartRxStreamReady)
  );

  ApbAxiStreamDma uApbAxiStreamDma (
    .iPclk      (iPclk),
    .iPresetn   (iPresetn),
    .iPSEL      (wDmaSel),
    .iPENABLE   (iPENABLE),
    .iPWRITE    (iPWRITE),
    .iPADDR     (iPADDR[11:0]),
    .iPWDATA    (iPWDATA),
    .iPSTRB     (iPSTRB),
    .oPRDATA    (wDmaPRDATA),
    .oPREADY    (wDmaPREADY),
    .oPSLVERR   (wDmaPSLVERR),
    .oDoneIrq   (wDmaDoneIrq),
    .oErrorIrq  (wDmaErrorIrq),
    .iS_TDATA   (wUartRxStreamData),
    .iS_TVALID  (wUartRxStreamValid),
    .oS_TREADY  (wUartRxStreamReady),
    .iS_TLAST   (1'b0),
    .oM_TDATA   (wDmaTxStreamData),
    .oM_TVALID  (wDmaTxStreamValid),
    .iM_TREADY  (wDmaTxStreamReady),
    .oM_TLAST   (wDmaTxStreamLast)
  );

  ApbPlicLite uApbPlicLite (
    .iPclk       (iPclk),
    .iPresetn    (iPresetn),
    .iIrqSources (wIrqSources),
    .iPSEL       (wIrqCtrlSel),
    .iPENABLE    (iPENABLE),
    .iPWRITE     (iPWRITE),
    .iPADDR      (iPADDR[11:0]),
    .iPWDATA     (iPWDATA),
    .iPSTRB      (iPSTRB),
    .oPRDATA     (wIrqPRDATA),
    .oPREADY     (wIrqPREADY),
    .oPSLVERR    (wIrqPSLVERR),
    .oExternalIrq(oExternalIrq)
  );

  always_comb begin
    oPRDATA  = 32'd0;
    oPREADY  = 1'b1;
    oPSLVERR = iPSEL;

    if (wTimerSel) begin
      oPRDATA  = wTimerPRDATA;
      oPREADY  = wTimerPREADY;
      oPSLVERR = wTimerPSLVERR;
    end
    else if (wGpioASel) begin
      oPRDATA  = wGpioAPRDATA;
      oPREADY  = wGpioAPREADY;
      oPSLVERR = wGpioAPSLVERR;
    end
    else if (wGpioBSel) begin
      oPRDATA  = wGpioBPRDATA;
      oPREADY  = wGpioBPREADY;
      oPSLVERR = wGpioBPSLVERR;
    end
    else if (wSpiSel) begin
      oPRDATA  = wSpiPRDATA;
      oPREADY  = wSpiPREADY;
      oPSLVERR = wSpiPSLVERR;
    end
    else if (wI2cSel) begin
      oPRDATA  = wI2cPRDATA;
      oPREADY  = wI2cPREADY;
      oPSLVERR = wI2cPSLVERR;
    end
    else if (wUartSel) begin
      oPRDATA  = wUartPRDATA;
      oPREADY  = wUartPREADY;
      oPSLVERR = wUartPSLVERR;
    end
    else if (wDmaSel) begin
      oPRDATA  = wDmaPRDATA;
      oPREADY  = wDmaPREADY;
      oPSLVERR = wDmaPSLVERR;
    end
    else if (wGpioCSel) begin
      oPRDATA  = wGpioCPRDATA;
      oPREADY  = wGpioCPREADY;
      oPSLVERR = wGpioCPSLVERR;
    end
    else if (wIrqCtrlSel) begin
      oPRDATA  = wIrqPRDATA;
      oPREADY  = wIrqPREADY;
      oPSLVERR = wIrqPSLVERR;
    end
  end

endmodule
