/******************************************************************
  - Project          : 2024 winter internship
  - File name        : Lab2_ApbIfBlk.v
  - Description      : 2ea read reg & 1ea write reg w/ APB Interface
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.26 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Cp_ApbIfBlk( //non verification apb completed
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

  

  //output for  write interface InBuf spsram
  output oWrEn_InBuf,
  output [8:0] oWrAddr_InBuf,
  output [31:0] oWrDt_InBuf,

  //output input  for DtCp
  output oStCp,
  output [11:0] oCpByteSize,
  input iCpDone,

  // input output for OutBuf spsram
  output oRdEn_OutBuf,
  output [8:0] oRdAddr_OutBuf,
  input [31:0] iRdDt_OutBuf,
  
  //for interrupt
  output oInt,
  output[127:0] oAesKey
  );

  // wire & reg declaration
  wire             wRdEn_InBuf;          // wApbOutCData read enable
  wire             wWrEn_OutBuf; 
  wire             wWrEn_oStCp;
  wire             wRdEn;


  reg [31:0] rPrdata; // read prdata

  reg [11:0] rCpByteSize; //packet size checking
  
  //for interrupt write
  wire wWrIntEn;//interrupt enable
  wire wWrIntPenEn;//pending clear
  wire wPendingWriteEn;//rIntPending value catch 
  wire wWrIntMaskEn;//mask enable
  //interrup register
  reg rIntEnable;
  reg rIntPending;
  reg rIntMask;

  wire wAesKeyWrEn;
  wire wAesKeyRdEn;
  //key variable declare
  reg[127:0] rAesKey;

  /**********************************/
  // Register write enable for inBuf 
  /***********************************/
  assign wWrEn_InBuf = ( (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
		       & (iPwrite  == 1'b1)
		       & (iPaddr[15:12]   == 4'h4) ) ? 1'b1 : 1'b0;

  /*********************************/
  // Register read enable for OutBuf
  /*********************************/
  assign wRdEn_OutBuf = ( (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
		       & (iPwrite  == 1'b0)
		       & (iPaddr[15:12]   == 4'h6) ) ? 1'b1 : 1'b0;

  //oStCp write enable 16'h0000 register
  assign woStCp = (iPsel    == 1'b1)
                   & (iPenable == 1'b0)
                   & (iPwrite  == 1'b1)
                   & (iPaddr   == 16'h0000) ? 1'b1 : 1'b0;

  //////////////////////////////////
  //write enable assign for interrupt
  //////////////////////////////////
  assign wWrIntEn  =     ( (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
		       & (iPwrite  == 1'b1)
		       & (iPaddr  == 16'hA000) ) ? 1'b1 : 1'b0;

  assign wWrIntPenEn =  ( (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
		       & (iPwrite  == 1'b1)
		       & (iPaddr  == 16'hA004) ) ? 1'b1 : 1'b0;
 
  assign wWrIntMaskEn =     ( (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
		       & (iPwrite  == 1'b1)
		       & (iPaddr  == 16'hA008) ) ? 1'b1 : 1'b0;
  //pending register update
  assign wPendingWriteEn = (rIntEnable && iCpDone);


  //Read enable
  assign wRdEn  = ( (iPsel    == 1'b1)
                    & (iPenable == 1'b0)
		                & (iPwrite  == 1'b0) ) ? 1'b1 : 1'b0;

  //CpByte write 16'h0004 write enable
  assign wCpByteWrEn = (iPsel    == 1'b1)
                  & (iPenable == 1'b0)
                  & (iPwrite  == 1'b1)
                  & (iPaddr   == 16'h0004)  ? 1'b1 : 1'b0;


  //CpByte register read enable
  assign wCpByteRdEn = ( (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
                       & (iPwrite  == 1'b0)
                       & (iPaddr   == 16'h0004) ) ? 1'b1 : 1'b0;
          
  //key read write enable        
  assign wAesKeyWrEn =  ( (iPsel    == 1'b1)
                        & (iPenable == 1'b0)
                        & (iPwrite  == 1'b1)
                        & (iPaddr[15:12] == 4'h2) ) ? 1'b1 : 1'b0;
  assign wAesKeyRdEn =  ( (iPsel    == 1'b1)
                        & (iPenable == 1'b0)
                        & (iPwrite  == 1'b0)
                        & (iPaddr[15:12] == 4'h2) ) ? 1'b1 : 1'b0;

  // APB write function
  always @(posedge iClk) begin

    // Synchronous & low reset
    if (!iRsn) begin
      rCpByteSize <= 11'b0;
      rIntEnable <= 1'b0;
      rIntPending <= 1'b0;
      rIntMask <= 1'b0;
    end
    //pktEnable
    else if (wCpByteWrEn == 1'b1) begin
      rCpByteSize  <= iPwdata[11:0];
    end
    else if (wWrIntEn == 1'b1) begin
      rIntEnable <= iPwdata[0];
    end
    else if (wWrIntPenEn == 1'b1) begin
      rIntPending <= ~iPwdata[0];//write 1'b1 pending clear
    end
    else if(wWrIntMaskEn == 1'b1) begin
      rIntMask <= iPwdata[0];
    end
    else if (wAesKeyWrEn == 1'b1) begin
      case (iPaddr[7:0])
        8'h00: rAesKey[31:0] <= iPwdata;
        8'h04: rAesKey[63:32] <= iPwdata;
        8'h08: rAesKey[95:64] <= iPwdata;
        8'h0C: rAesKey[127:96] <= iPwdata; 
        default: rAesKey[31:0] <= iPwdata;
      endcase
    end
    if(wPendingWriteEn) begin
      rIntPending <= 1'b1;
    end
  end

  //For Read Always block
  always @(posedge iClk) begin

    // Synchronous & low reset
    if (!iRsn) begin
     rPrdata <= 32'h0;
    end
    else if(wAesKeyRdEn == 1'b1) begin
      case (iPaddr[7:0])
        8'h00: rPrdata <= rAesKey[31:0];
        8'h04: rPrdata <= rAesKey[63:32];
        8'h08: rPrdata <= rAesKey[95:64];
        8'h0C: rPrdata <= rAesKey[127:96]; 
        default: rPrdata <= rAesKey[31:0];
      endcase
    end
    else if(wRdEn == 1'b1) begin
      case (iPaddr[15:0]) 
        16'h0004 : begin
          rPrdata[31:0] <= {20'b0,rCpByteSize[11:0]};
        end
        16'hA000: begin
          rPrdata[31:0] <= {31'h0, rIntEnable};
        end
        16'hA004 : begin
          rPrdata[31:0] <= {31'h0, rIntPending};
        end
        16'hA008 : begin 
          rPrdata[31:0] <= {31'h0, rIntMask};
        end
        default : begin
          rPrdata[31:0] <= rPrdata[31:0];
        end
      endcase  
    end 
  end

  //apb->inbuf
  assign oWrEn_InBuf = wWrEn_InBuf;
  assign oWrAddr_InBuf = iPaddr[10:2];
  assign oWrDt_InBuf = iPwdata[31:0];

  //apb -> outbuf
  assign oRdEn_OutBuf = wRdEn_OutBuf;
  assign oRdAddr_OutBuf = iPaddr[10:2];

  //Apb -> DtCp
  assign oStCp = woStCp;
  assign oCpByteSize = rCpByteSize[11:0];
  
  //apb -> SW
  assign oPrdata = (iPaddr[15:12] == 4'h6) ? iRdDt_OutBuf[31:0] : rPrdata[31:0];
  assign oInt = (rIntMask && rIntPending); // and operator
  assign oAesKey = rAesKey;

endmodule
