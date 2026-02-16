`timescale 1ns/10ps

module AesCore( 
  
  input iClk,
  input iRsn,

  input iStAes,
  input[127:0] iAesKey,
  input[127:0] iPlainText,

  output oAesDone,
  output[127:0] oCpText 

);

wire wInitRoundFlag;
wire wFstRoundFlag;
wire wMidRoundFlag;
wire wLstRoundFlag;
 
AesCrtl AesCrtl0(
  .iClk(iClk),
  .iRsn(iRsn),

  .iStAes(iStAes),

  .oInitRoundFlag(wInitRoundFlag),
  .oFstRoundFlag(wFstRoundFlag),
  .oMidRoundFlag(wMidRoundFlag),
  .oLstRoundFlag(wLstRoundFlag),

  .oAesDone(oAesDone)
);

RoundFunc RoundFunc0(

  .iClk(iClk),
  .iRsn(iRsn),

  .iInitRoundFlag(wInitRoundFlag),
  .iFstRoundFlag(wFstRoundFlag),
  .iMidRoundFlag(wMidRoundFlag),
  .iLstRoundFlag(wLstRoundFlag),

  .iAesKey(iAesKey),
  .iPlainText(iPlainText),

  .oCpText(oCpText) 
);

endmodule
