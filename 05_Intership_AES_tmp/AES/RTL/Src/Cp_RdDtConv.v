`timescale 1ns/10ps

module Cp_RdDtConv( //non verification code completed 
  
  input      iRdEn_OutBuf,
  input[8:0] iRdAddr_OutBuf,
  input[127:0] iRdDt_CpOutBuf,

  output oRdEn_CpOutBuf,
  output[6:0] oRdAddr_CpOutBuf,
  output[31:0] oRdDt_OutBuf

);

assign oRdEn_CpOutBuf = iRdEn_OutBuf;
assign oRdAddr_CpOutBuf = iRdAddr_OutBuf[8:2];

assign oRdDt_OutBuf =  (iRdAddr_OutBuf[1:0] == 2'b00) ? iRdDt_CpOutBuf[0+:32] :
                       (iRdAddr_OutBuf[1:0] == 2'b01) ? iRdDt_CpOutBuf[32+:32] :
                       (iRdAddr_OutBuf[1:0] == 2'b10) ? iRdDt_CpOutBuf[64+:32] :
                       iRdDt_CpOutBuf[96+:32]; // (iRdAddr_OutBuf[1:0] == 2'b11)


endmodule
