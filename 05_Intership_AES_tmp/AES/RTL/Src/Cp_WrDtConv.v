`timescale 1ns/10ps

module Cp_WrDtConv( //non verificate code complited

  input         iWrEn_InBuf,
  input[8:0]    iWrAddr_InBuf,
  input[31:0]   iWrDt_InBuf,
  
  output        oWrEn_CpInBuf,
  output[3:0]   oWdSel_CpInBuf,
  output[6:0]   oWrAddr_CpInBuf,
  output[127:0] oWrDt_CpInBuf

);

assign oWrEn_CpInBuf = iWrEn_InBuf;
assign oWdSel_CpInBuf = (iWrAddr_InBuf[1:0] == 2'b00) ? (4'b0001):
                        (iWrAddr_InBuf[1:0] == 2'b01) ? (4'b0010):
                        (iWrAddr_InBuf[1:0] == 2'b10) ? (4'b0100):
                        (4'b1000);//(iWrAddr_InBuf[1:0] == 2'b11) 
assign oWrAddr_CpInBuf = iWrAddr_InBuf[8:2];
assign oWrDt_CpInBuf = {4{iWrDt_InBuf}};



endmodule
