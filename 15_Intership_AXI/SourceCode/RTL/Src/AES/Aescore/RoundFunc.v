`timescale 1ns/10ps

module RoundFunc( //non verificate code complited
  
  input iClk,
  input iRsn,

  input iInitRoundFlag, 
  input iFstRoundFlag,
  input iMidRoundFlag,
  input iLstRoundFlag,

  input[127:0] iAesKey,
  input[127:0] iPlainText,

  output[127:0] oCpText 

);

reg[127:0] rCpText;
wire[127:0] wCpText;

wire [127:0] wAesKey;

wire wEn;

wire [127:0] wInitMux;
wire[127:0] wLstMux;

wire[127:0] wiSubBytes;
wire[127:0] wiShiftRows;
wire[127:0] wiMixColumns;
wire[127:0] woMixColumns;

KeyExpansion keyExpansion0( 
  .iClk(iClk),
  .iRsn(iClk),

  .iInitRoundFlag(iInitRoundFlag), 

  .iEn(wEn),

  .iAesKey(iAesKey),

  .oAesKey(wAesKey)

);


//intput,output
SubBytes SubBytes0(wiSubBytes,wiShiftRows);
ShiftRows ShiftRows0(wiShiftRows,wiMixColumns);
MixColumns Mixcolumns0(wiMixColumns,woMixColumns);

assign wLstMux = (iLstRoundFlag == 1'b1) ? wiMixColumns : woMixColumns;//last round don't mixcloum
assign wInitMux = (iInitRoundFlag == 1'b1) ?  iPlainText : wLstMux;
assign wCpText = wInitMux ^ wAesKey;
assign wiSubBytes = rCpText;
assign oCpText = rCpText;
assign wEn = (iInitRoundFlag | iFstRoundFlag | iMidRoundFlag |iLstRoundFlag);

always @(posedge iClk) begin
  if(!iRsn) begin
    rCpText <= 128'h0;
  end
  else if(wEn) begin
    rCpText <= wCpText;
  end

end

endmodule
