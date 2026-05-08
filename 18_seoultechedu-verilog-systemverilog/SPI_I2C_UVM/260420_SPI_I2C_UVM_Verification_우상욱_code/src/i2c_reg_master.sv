`timescale 1ns/1ps

module i2c_reg_master (
  input  logic       iClk,
  input  logic       iTick,
  input  logic       iRst,
  input  logic       iStart,
  input  logic       iRead,
  input  logic [3:0] iRegAddr,
  input  logic [7:0] iWrData,
  input  logic       iSda,
  output logic [7:0] oRxData,
  output logic       oBusy,
  output logic       oDone,
  output logic       oAckError,
  output logic       oSclOe,
  output logic       oSdaOe
);

  logic [6:0] wTargetSlaveAddr;

  assign wTargetSlaveAddr = {5'd0, iRegAddr[1:0]};

  i2c_master uI2cMaster (
    .iClk      (iClk),
    .iTick     (iTick),
    .iRst      (iRst),
    .iStart    (iStart),
    .iRead     (iRead),
    .iSlaveAddr(wTargetSlaveAddr),
    .iTxData   (iWrData),
    .iSda      (iSda),
    .oRxData   (oRxData),
    .oBusy     (oBusy),
    .oDone     (oDone),
    .oAckError (oAckError),
    .oSclOe    (oSclOe),
    .oSdaOe    (oSdaOe)
  );

endmodule
