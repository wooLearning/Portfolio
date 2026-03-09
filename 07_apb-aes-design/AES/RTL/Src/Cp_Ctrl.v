`timescale 1ns/10ps

module Cp_Ctrl( // non verification module
  //clock and reset define
  input iClk,//rising edfe
  input iRsn,//sync low reset
  
  //abp -> input define
  input iStCp, // idle -> StDtCp
  input [11:0] iCpByteSize,//Cypher byte size
  input [127:0] iAesKey,  

  //read data from inbuf
  input [127:0] iRdDt_CpInBuf,

  //AesCore -> 
  input iAesDone, // cyphered done
  input [127:0] iCpText,
  
  //module -> apb output define
  output oCpDone, //cyphered done signal

  //module -> cp_inBuf 
  output [6:0] oRdAddr_CpInBuf, //read address from inbuf 
  output oRdEn_CpInBuf,//read enable for inbuf

  //Cp_Ctrl -> AesCore
  output oStAes,
  output [127:0] oAesKey,
  output [127:0] oPlainText,

  //module -> outBuf
  output oWrEn_CpOutBuf,
  output [6:0] oWrAddr_CpOutBuf,
  output [127:0] oWrDt_CpOutBuf,
  output [3:0] oWdSel_CpOutBuf
  
);

  parameter p_Idle         = 3'b000,
            p_StCp         = 3'b001,
            p_RdCpInBuf    = 3'b010,
            p_StAes        = 3'b011,
            p_WtAes        = 3'b100,
            p_AesDone      = 3'b101,
            p_WrCpOutBuf   = 3'b110,
            p_CpDone       = 3'b111;//Cp = cyphered
 
 
  reg [2:0] rCurState;
  reg [2:0] rNxtState;
  reg [6:0] rRdDt_InBuf_Addr;
  //reg [127:0] rRdDt_CpInBuf;
  reg [127:0] riCpText;


  wire wLastDtFlag;//end word
  wire [127:0] woPlainText;
  wire [127:0] woAesKey;

  wire[127:0] woCpText;


  /*FSM*///Part 2 next state decision
  always @(posedge iClk) begin
    if(!iRsn)
      rCurState <= p_Idle;
    else
      rCurState <= rNxtState[2:0];
  end

  always @(*) begin
    case(rCurState)
      p_Idle: begin
        if(iStCp == 1'b1) rNxtState <= p_StCp;
        else rNxtState <= p_Idle;
      end
      p_StCp: begin
        rNxtState <= p_RdCpInBuf;
      end
      p_RdCpInBuf: begin
        rNxtState <= p_StAes;
      end 
      p_StAes: begin
        rNxtState <= p_WtAes;  
      end
      p_WtAes: begin
        if(iAesDone == 1'b1) rNxtState <= p_AesDone;
        else rNxtState <= p_WtAes;
      end
      p_AesDone: begin
        rNxtState <= p_WrCpOutBuf;
      end
      p_WrCpOutBuf: begin
        if(wLastDtFlag == 1'b1) rNxtState <= p_CpDone;
        else rNxtState <= p_RdCpInBuf;
      end
      p_CpDone: begin
        rNxtState <= p_Idle;
      end
      default :
        rNxtState <= p_Idle;
    endcase            
  end

  //part2 combinational logic
  

  //endian converion little -> big
  assign woPlainText = {iRdDt_CpInBuf[0+:8], iRdDt_CpInBuf[8+:8], iRdDt_CpInBuf[16+:8] , iRdDt_CpInBuf[24+:8] , iRdDt_CpInBuf[32+:8]   
                      , iRdDt_CpInBuf[40+:8] , iRdDt_CpInBuf[48+:8] , iRdDt_CpInBuf[56+:8] , iRdDt_CpInBuf[64+:8], iRdDt_CpInBuf[72+:8]
                      , iRdDt_CpInBuf[80+:8] , iRdDt_CpInBuf[88+:8] , iRdDt_CpInBuf[96+:8] , iRdDt_CpInBuf[104+:8] , iRdDt_CpInBuf[112+:8] 
                      , iRdDt_CpInBuf[120+:8] }; 

  assign woCpText = {   riCpText[0+:8],   riCpText[8+:8],   riCpText[16+:8], riCpText[24+:8],  riCpText[32+:8]   
                      , riCpText[40+:8],  riCpText[48+:8],  riCpText[56+:8], riCpText[64+:8],  riCpText[72+:8]
                      , riCpText[80+:8],  riCpText[88+:8],  riCpText[96+:8], riCpText[104+:8], riCpText[112+:8] 
                      , riCpText[120+:8] }; 



  assign woAesKey = {iAesKey[0+:8], iAesKey[8+:8], iAesKey[16+:8], iAesKey[24+:8], iAesKey[32+:8], iAesKey[40+:8], iAesKey[48+:8], iAesKey[56+:8]
                   , iAesKey[64+:8], iAesKey[72+:8], iAesKey[80+:8], iAesKey[88+:8], iAesKey[96+:8], iAesKey[104+:8] , iAesKey[112+:8] 
                   , iAesKey[120+:8]};

  assign wLastDtFlag = (iCpByteSize == (rRdDt_InBuf_Addr * 16) ) ? 1'b1 : 1'b0;

  always @(posedge iClk) begin
    if(!iRsn) begin
      rRdDt_InBuf_Addr <= 0;
      riCpText <= 127'h0;
    end
   //else if(rCurState == p_RdCpInBuf) begin
     //rRdDt_CpInBuf <= iRdDt_CpInBuf;//plain text letch for Aes
   // end
    else if(iAesDone == 1'b1) begin
      riCpText <= iCpText; // value latch
      rRdDt_InBuf_Addr <= rRdDt_InBuf_Addr + 1'b1;
    end
  end

  //Part3 output & enable control

  //for AesCore
  assign oAesKey = woAesKey;// endian conversion
  assign oPlainText = woPlainText;//128bits 
  assign oStAes = (rCurState == p_StAes) ? 1'b1 : 1'b0;

  //for Apb interface interrupt
  assign oCpDone = (rCurState == p_CpDone) ? 1'b1 : 1'b0;
  
  //for InBuf 
  assign oRdEn_CpInBuf = (rCurState == p_RdCpInBuf) ? 1'b1 : 1'b0; // read from inbuf (inbuf enable)
  assign oRdAddr_CpInBuf = rRdDt_InBuf_Addr;

  //for wirte outBuf
  assign oWrEn_CpOutBuf = (rCurState == p_WrCpOutBuf) ? 1'b1 : 1'b0;// write to outbuf (outbuf write enbale)
  assign oWrAddr_CpOutBuf = rRdDt_InBuf_Addr-1;
  assign oWrDt_CpOutBuf = woCpText; 
  assign oWdSel_CpOutBuf = 4'b1111; // for module instantiation

endmodule
