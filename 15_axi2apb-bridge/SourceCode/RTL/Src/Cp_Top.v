/*******************************************************************
  - Project          : 2024 winter internship
  - File name        : Lab2_Top.v
  - Description      : Lab2 top file
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.26 : Initial release
                     : 2) 2025.01.10 : all completed
                       3) 2026.01.11 : ready signal add
*******************************************************************/

`timescale 1ns/10ps

module Cp_Top( //not yet

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // APB interface
  input            iPsel,
  input            iPenable,
  input            iPwrite,
  input  [15:0]    iPaddr,

  input  [31:0]    iPwdata,
  output [31:0]    oPrdata,

  output oPREADY,
  output oInt
);

assign oPREADY = iPenable; // zero- wwait

wire woWrEn_InBuf;
wire[8:0] woWrAddr_InBuf;
wire[31:0] woWrDt_InBuf;

wire woStCp;
wire[11:0] woCpByteSize;
wire wiCpDone;

wire woRdEn_OutBuf;
wire[8:0] woRdAddr_OutBuf;
wire[31:0] wiRdDt_OutBuf;

wire woWrEn_CpInBuf;
wire [3:0] woWdSel_CpInBuf;
wire [6:0] woWrAddr_CpInBuf;
wire [127:0] woWrDt_CpInBuf;

wire woRdEn_CpInBuf;//read enable for inbuf
wire [6:0] woRdAddr_CpInBuf; //read address from inbuf 
wire[127:0] wiRdDt_CpInBuf;

wire woStAes;
wire [127:0] woAesKey;
wire [127:0] woAesKey_2;
wire [127:0] woPlainText;

wire woAesDone; // cyphered done
wire [127:0] woCpText;

wire woWrEn_CpOutBuf;
wire [6:0] woWrAddr_CpOutBuf;
wire [127:0] woWrDt_CpOutBuf;
wire [3:0] woWdSel_CpOutBuf;

wire woRdEn_CpOutBuf;
wire[6:0] woRdAddr_CpOutBuf; 

wire[127:0] woRdDt;    

Cp_ApbIfBlk Cp_ApbIfBlk( 
  // Clock & reset
  .iClk(iClk),               // Rising edge
  .iRsn(iRsn),               // Sync. & low reset

  // APB interface
  .iPsel(iPsel),
  .iPenable(iPenable),
  .iPwrite(iPwrite),
  .iPaddr(iPaddr),

  .iPwdata(iPwdata),
  .oPrdata(oPrdata),

  //output for  write interface InBuf spsram
  .oWrEn_InBuf(woWrEn_InBuf),
  .oWrAddr_InBuf(woWrAddr_InBuf),
  .oWrDt_InBuf(woWrDt_InBuf),

  //output input  for DtCp
  .oStCp(woStCp),
  .oCpByteSize(woCpByteSize),
  .iCpDone(wiCpDone),

  // input output for OutBuf spsram
  .oRdEn_OutBuf(woRdEn_OutBuf),
  .oRdAddr_OutBuf(woRdAddr_OutBuf),
  .iRdDt_OutBuf(wiRdDt_OutBuf),
  
  //for interrupt
  .oInt(oInt),
  .oAesKey(woAesKey)
);

Cp_WrDtConv Cp_WrDtConv( //non verificate code complited
  .iWrEn_InBuf(woWrEn_InBuf),
  .iWrAddr_InBuf(woWrAddr_InBuf),
  .iWrDt_InBuf(woWrDt_InBuf),
  
  .oWrEn_CpInBuf(woWrEn_CpInBuf),
  .oWdSel_CpInBuf(woWdSel_CpInBuf),
  .oWrAddr_CpInBuf(woWrAddr_CpInBuf),
  .oWrDt_CpInBuf(woWrDt_CpInBuf)
);

Cp_BufWrap Cp_InBuf(//reference 

  // Clock & reset
  .iClk(iClk),              
  .iRsn(iRsn), 

  // Write port
  .iWrEn(woWrEn_CpInBuf),// Write enable, active high
  .iWdSel(woWdSel_CpInBuf),  // Write word select, active high
  .iWrAddr(woWrAddr_CpInBuf),   // Write address
  .iWrDt(woWrDt_CpInBuf),  // 32bit write data


  // Read port
  .iRdEn(woRdEn_CpInBuf),              // Read enable, active high
  .iRdAddr(woRdAddr_CpInBuf),            // Read address
  .oRdDt(wiRdDt_CpInBuf)               // 32bit read data

);

Cp_Ctrl CpCtrl0( // non verification module
  //clock and reset define
  .iClk(iClk),              
  .iRsn(iRsn), 
  
  //abp -> input define
  .iStCp(woStCp), // idle -> StDtCp
  .iCpByteSize(woCpByteSize),//Cypher byte size
  .iAesKey(woAesKey), 

  //read data from inbuf
  .iRdDt_CpInBuf(wiRdDt_CpInBuf),

  //AesCore -> 
  .iAesDone(woAesDone), // cyphered done
  .iCpText(woCpText),
  
  //module -> apb output define
  .oCpDone(wiCpDone), //cyphered done signal

  //module -> cp_inBuf 
  .oRdEn_CpInBuf(woRdEn_CpInBuf),//read enable for inbuf
  .oRdAddr_CpInBuf(woRdAddr_CpInBuf), //read address from inbuf 

  //Cp_Ctrl -> AesCore
  .oStAes(woStAes),
  .oAesKey(woAesKey_2),
  .oPlainText(woPlainText),

  //module -> outBuf
  .oWrEn_CpOutBuf(woWrEn_CpOutBuf),
  .oWrAddr_CpOutBuf(woWrAddr_CpOutBuf),
  .oWrDt_CpOutBuf(woWrDt_CpOutBuf),
  .oWdSel_CpOutBuf(woWdSel_CpOutBuf)
  
);
AesCore AesCore0( //non verificate code complited
  .iClk(iClk),              
  .iRsn(iRsn),

  .iStAes(woStAes),
  .iAesKey(woAesKey_2),
  .iPlainText(woPlainText),

  .oAesDone(woAesDone),
  .oCpText(woCpText) 
);

Cp_BufWrap Cp_OutBuf(//reference 
  // Clock & reset
  .iClk(iClk),              
  .iRsn(iRsn),
  // Write port
  .iWrEn(woWrEn_CpOutBuf),            // Write enable, active high
  .iWdSel(woWdSel_CpOutBuf),             // Write word select, active high
  .iWrAddr(woWrAddr_CpOutBuf),            // Write address
  .iWrDt(woWrDt_CpOutBuf),             // 32bit write data
  // Read port
  .iRdEn(woRdEn_CpOutBuf),              // Read enable, active high
  .iRdAddr(woRdAddr_CpOutBuf),            // Read address
  .oRdDt(woRdDt)               
);
Cp_RdDtConv Cp_RdDtConv0( //non verification code completed 
  
  .iRdEn_OutBuf(woRdEn_OutBuf),
  .iRdAddr_OutBuf(woRdAddr_OutBuf),

  .iRdDt_CpOutBuf(woRdDt),

  .oRdEn_CpOutBuf(woRdEn_CpOutBuf),
  .oRdAddr_CpOutBuf(woRdAddr_CpOutBuf),  

  .oRdDt_OutBuf(wiRdDt_OutBuf)
  
);

endmodule
