`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbSubsystem
Role: APB peripheral subsystem behind the AXI-Lite-to-APB bridge
Summary:
  - Decodes timer, GPIO, SPI, I2C, UART, and PLIC register windows
  - Keeps low-speed peripherals APB-based while the SoC fabric is AXI
  - Exposes UART/SPI stream endpoints for the AXI-Lite-controlled DMA in SocTop
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
  output logic        oExternalIrq,
  input  logic        iDmaDoneIrq,
  input  logic        iDmaErrorIrq,
  output logic [7:0]  oDmaS_TDATA,
  output logic        oDmaS_TVALID,
  input  logic        iDmaS_TREADY,
  input  logic [7:0]  iDmaM_TDATA,
  input  logic        iDmaM_TVALID,
  output logic        oDmaM_TREADY
);

  logic wTimerSel;
  logic wGpioASel;
  logic wGpioBSel;
  logic wGpioCSel;
  logic wSpiSel;
  logic wI2cSel;
  logic wUartSel;
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
  logic [7:0]  wUartRxStreamData;
  logic        wUartRxStreamValid;
  logic        wUartRxStreamReady;
  logic [7:0]  wDmaRxStreamData;
  logic        wDmaRxStreamValid;
  logic        wDmaRxStreamReady;
  logic        wDmaRxStreamFifoFull;
  logic        wDmaRxStreamFifoEmpty;
  logic [7:0]  wDmaTxStreamData;
  logic        wDmaTxStreamValid;
  logic        wDmaTxStreamReady;
  logic [31:0] wIrqPRDATA;
  logic        wIrqPREADY;
  logic        wIrqPSLVERR;
  logic [7:0]  wIrqSources;

  assign wTimerSel   = iPSEL && address_map_pkg::apb_local_in_range(iPADDR, address_map_pkg::TIMER_BASE, address_map_pkg::TIMER_SIZE);
  assign wGpioASel   = iPSEL && address_map_pkg::apb_local_in_range(iPADDR, address_map_pkg::GPIO_BASE, address_map_pkg::GPIO_SIZE);
  assign wGpioBSel   = iPSEL && address_map_pkg::apb_local_in_range(iPADDR, address_map_pkg::GPIO_B_BASE, address_map_pkg::GPIO_B_SIZE);
  assign wSpiSel     = iPSEL && address_map_pkg::apb_local_in_range(iPADDR, address_map_pkg::SPI_BASE, address_map_pkg::SPI_SIZE);
  assign wI2cSel     = iPSEL && address_map_pkg::apb_local_in_range(iPADDR, address_map_pkg::I2C_BASE, address_map_pkg::I2C_SIZE);
  assign wUartSel    = iPSEL && address_map_pkg::apb_local_in_range(iPADDR, address_map_pkg::UART_BASE, address_map_pkg::UART_SIZE);
  assign wGpioCSel   = iPSEL && address_map_pkg::apb_local_in_range(iPADDR, address_map_pkg::GPIO_C_BASE, address_map_pkg::GPIO_C_SIZE);
  assign wIrqCtrlSel = iPSEL && address_map_pkg::apb_local_in_range(iPADDR, address_map_pkg::PLIC_BASE, address_map_pkg::PLIC_SIZE);
  assign wIrqSources = iPeripheralIrq |
                       {1'b0, iDmaErrorIrq, iDmaDoneIrq, 1'b0,
                        wSpiRxIrq, wSpiTxIrq, wUartRxIrq, wUartTxIrq};
  assign oDmaS_TDATA       = wDmaRxStreamData;
  assign oDmaS_TVALID      = wDmaRxStreamValid;
  assign wDmaRxStreamReady = iDmaS_TREADY;
  assign wDmaTxStreamData  = iDmaM_TDATA;
  assign wDmaTxStreamValid = iDmaM_TVALID;
  assign oDmaM_TREADY      = wDmaTxStreamReady;

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

  StreamFifo #(
    .P_DATA_WIDTH (8),
    .P_DEPTH      (64)
  ) uUartRxDmaFifo (
    .iClk    (iPclk),
    .iRstn   (iPresetn),
    .iSData  (wUartRxStreamData),
    .iSValid (wUartRxStreamValid),
    .oSReady (wUartRxStreamReady),
    .oMData  (wDmaRxStreamData),
    .oMValid (wDmaRxStreamValid),
    .iMReady (wDmaRxStreamReady),
    .oFull   (wDmaRxStreamFifoFull),
    .oEmpty  (wDmaRxStreamFifoEmpty)
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
