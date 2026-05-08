`timescale 1ns/1ps

module sb_minimal_top (
  input  logic       iClk,
  input  logic       iRst,
  input  logic       iStart,
  input  logic       iModeI2c,
  input  logic       iRead,
  input  logic [1:0] iSpiMode,
  input  logic [1:0] iRegSel,
  input  logic [7:0] iTxData,

  output logic [7:0] oRxData,
  output logic       oBusy,
  output logic       oDone,
  output logic       oAckError,
  output logic [15:0] oDigits
);

  localparam int COMM_TICK_DIV = 25;

  logic       wCommTick;
  logic [7:0] wSpiRxData;
  logic       wSpiBusy;
  logic       wSpiDone;
  logic       wSpiSclk;
  logic [3:0] wSpiCsN;
  logic       wSpiMosi;
  logic       wSpiMiso;
  logic       wSpiWrEn;
  logic [3:0] wSpiWrAddr;
  logic [7:0] wSpiWrData;
  logic [7:0] wI2cRxData;
  logic       wI2cBusy;
  logic       wI2cDone;
  logic       wI2cAckError;
  logic       wI2cMasterSclOe;
  logic       wI2cMasterSdaOe;
  logic       wI2cSlaveSdaOe;
  logic       wI2cWrEn;
  logic [3:0] wI2cWrAddr;
  logic [7:0] wI2cWrData;
  logic       wI2cSclBus;
  logic       wI2cSdaBus;
  logic       wRegWrEn;
  logic [3:0] wRegWrAddr;
  logic [7:0] wRegWrData;

  clk_div #(
    .DIV_RATIO(COMM_TICK_DIV)
  ) uCommTickGen (
    .iClk (iClk),
    .iRst (iRst),
    .oTick(wCommTick)
  );

  spi_reg_master uSpiRegMaster (
    .iClk    (iClk),
    .iTick   (wCommTick),
    .iRst    (iRst),
    .iStart  (iStart && !iModeI2c),
    .iCpol   (iSpiMode[1]),
    .iCpha   (iSpiMode[0]),
    .iRegSel (iRegSel),
    .iTxData (iTxData),
    .iMiso   (wSpiMiso),
    .oRxData (wSpiRxData),
    .oBusy   (wSpiBusy),
    .oDone   (wSpiDone),
    .oSclk   (wSpiSclk),
    .oCsN    (wSpiCsN),
    .oMosi   (wSpiMosi)
  );

  spi_reg_slave uSpiRegSlave (
    .iClk     (iClk),
    .iRst     (iRst),
    .iCpol    (iSpiMode[1]),
    .iCpha    (iSpiMode[0]),
    .iSclk    (wSpiSclk),
    .iCsN     (wSpiCsN),
    .iMosi    (wSpiMosi),
    .iRegDigits(oDigits),
    .oWrEn    (wSpiWrEn),
    .oWrAddr  (wSpiWrAddr),
    .oWrData  (wSpiWrData),
    .oMiso    (wSpiMiso)
  );

  i2c_reg_master uI2cRegMaster (
    .iClk      (iClk),
    .iTick     (wCommTick),
    .iRst      (iRst),
    .iStart    (iStart && iModeI2c),
    .iRead     (iRead),
    .iRegAddr  ({2'b00, iRegSel}),
    .iWrData   (iTxData),
    .iSda      (wI2cSdaBus),
    .oRxData   (wI2cRxData),
    .oBusy     (wI2cBusy),
    .oDone     (wI2cDone),
    .oAckError (wI2cAckError),
    .oSclOe    (wI2cMasterSclOe),
    .oSdaOe    (wI2cMasterSdaOe)
  );

  i2c_reg_slave uI2cRegSlave (
    .iClk     (iClk),
    .iRst     (iRst),
    .iRegDigits(oDigits),
    .iScl     (wI2cSclBus),
    .iSda     (wI2cSdaBus),
    .oWrEn    (wI2cWrEn),
    .oWrAddr  (wI2cWrAddr),
    .oWrData  (wI2cWrData),
    .oSdaOe   (wI2cSlaveSdaOe)
  );

  assign wI2cSclBus = wI2cMasterSclOe ? 1'b0 : 1'b1;
  assign wI2cSdaBus = (wI2cMasterSdaOe || wI2cSlaveSdaOe) ? 1'b0 : 1'b1;

  assign wRegWrEn   = wI2cWrEn || wSpiWrEn;
  assign wRegWrAddr = wI2cWrEn ? wI2cWrAddr : wSpiWrAddr;
  assign wRegWrData = wI2cWrEn ? wI2cWrData : wSpiWrData;

  digit_register_bank uDigitBank (
    .iClk   (iClk),
    .iRst   (iRst),
    .iWrEn  (wRegWrEn),
    .iWrAddr(wRegWrAddr),
    .iWrData(wRegWrData),
    .oDigits(oDigits)
  );

  always_comb begin
    oRxData   = iModeI2c ? wI2cRxData : wSpiRxData;
    oBusy     = iModeI2c ? wI2cBusy : wSpiBusy;
    oDone     = iModeI2c ? wI2cDone : wSpiDone;
    oAckError = iModeI2c ? wI2cAckError : 1'b0;
  end

endmodule
