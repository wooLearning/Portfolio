`timescale 1ns/1ps

module i2c_reg_slave (
  input  logic        iClk,
  input  logic        iRst,
  input  logic [15:0] iRegDigits,
  input  logic        iScl,
  input  logic        iSda,
  output logic        oWrEn,
  output logic [3:0]  oWrAddr,
  output logic [7:0]  oWrData,
  output logic        oSdaOe
);

  logic [31:0] wByteRxData;
  logic [3:0]  wByteRxValid;
  logic [3:0]  wSlaveSdaOe;

  function automatic logic [7:0] read_reg_value(
    input logic [15:0] iDigits,
    input logic [3:0]  iAddr
  );
    case (iAddr)
      4'h0: read_reg_value = {4'h0, iDigits[3:0]};
      4'h1: read_reg_value = {4'h0, iDigits[7:4]};
      4'h2: read_reg_value = {4'h0, iDigits[11:8]};
      4'h3: read_reg_value = {4'h0, iDigits[15:12]};
      default: read_reg_value = 8'h00;
    endcase
  endfunction

  generate
    for (genvar idx = 0; idx < 4; idx++) begin : gI2cReg
      i2c_slave uI2cSlave (
        .iClk    (iClk),
        .iRst    (iRst),
        .iOwnAddr(idx[6:0]),
        .iTxData (read_reg_value(iRegDigits, idx[3:0])),
        .iScl    (iScl),
        .iSda    (iSda),
        .oRxData (wByteRxData[idx*8 +: 8]),
        .oRxValid(wByteRxValid[idx]),
        .oTxnDone(),
        .oTxnRead(),
        .oSdaOe  (wSlaveSdaOe[idx])
      );
    end
  endgenerate

  always_comb begin
    oWrEn   = 1'b0;
    oWrAddr = 4'h0;
    oWrData = 8'h00;
    oSdaOe  = 1'b0;

    for (int idx = 0; idx < 4; idx++) begin
      oSdaOe |= wSlaveSdaOe[idx];

      if (wByteRxValid[idx]) begin
        oWrEn   = 1'b1;
        oWrAddr = idx[3:0];
        oWrData = wByteRxData[idx*8 +: 8];
      end
    end
  end

endmodule
