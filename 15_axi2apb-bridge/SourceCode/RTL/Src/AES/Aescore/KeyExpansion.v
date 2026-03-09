`timescale 1ns/10ps

module KeyExpansion( //non verificate code complited
  
  input iClk,
  input iRsn,

  input iInitRoundFlag, 

  input[127:0] iAesKey,

  input iEn,

  output[127:0] oAesKey

);

reg [127:0] rAesKey_store[0:9];

reg[127:0] rAesKey;

wire [31:0] Rcon [0:9];
wire [31:0] RconTemp;

reg [3:0] cnt;
wire[127:0] wMuxOut;

wire [31:0] wSubWord;

//reg[127:0] rAesKey_new;

wire[127:0] wAesKey;

assign wMuxOut = (iInitRoundFlag == 1'b1) ? iAesKey : rAesKey;
assign oAesKey = wMuxOut;

//subword generate
Sbox Sbox0(wMuxOut[0+:8],wSubWord[8+:8]);
Sbox Sbox1(wMuxOut[8+:8],wSubWord[16+:8]);
Sbox Sbox2(wMuxOut[16+:8],wSubWord[24+:8]);
Sbox Sbox3(wMuxOut[24+:8],wSubWord[0+:8]);
  
assign RconTemp = Rcon[cnt];
assign wAesKey[96+:32]  = wSubWord ^ Rcon[cnt]  ^ wMuxOut[96+:32];//xor
assign wAesKey[64+:32] = wAesKey[96+:32] ^ wMuxOut[64+:32];
assign wAesKey[32+:32] = wAesKey[64+:32] ^ wMuxOut[32+:32];
assign wAesKey[0+:32] = wAesKey[32+:32] ^ wMuxOut[0+:32];

always @(posedge iClk) begin
  if(!iRsn) begin
    rAesKey <= 128'h0;
  end
  else if(iEn == 1'b1) begin
    rAesKey <= wAesKey;
  end
  else begin
    rAesKey <= 128'h0;
  end
end

always @(posedge iClk) begin
  if(!iRsn) begin
    cnt <= 0;
  end
  else if(iEn == 1'b1) begin
    rAesKey_store[cnt] <= rAesKey;
    cnt <= cnt + 1;
  end
  else begin
    cnt <=0;
  end
end


assign Rcon[0] = 32'h01000000;
assign Rcon[1] = 32'h02000000;
assign Rcon[2] = 32'h04000000;
assign Rcon[3] = 32'h08000000;
assign Rcon[4] = 32'h10000000;
assign Rcon[5] = 32'h20000000;
assign Rcon[6] = 32'h40000000;
assign Rcon[7] = 32'h80000000;
assign Rcon[8] = 32'h1B000000;
assign Rcon[9] = 32'h36000000;

endmodule
