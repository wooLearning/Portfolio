/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : delayChain.v
  - Description      : 3 bit D-filp flop delay chain
  - Owner            : Sangwook.Woo
  - Revision history : 1) 2024.11.21 : Initial release
*******************************************************************/
module delayChain #(parameter DEPTH=79)(
	input        iClk12M,            // 12MHz clock
    input        iRsn,
	input        iEnSample600k,
    input        iEnDelay,
    input  signed [2:0] iFirIn,  // 3-bit signed input (-3, -1, 1, 3)
	output signed [2:0] wDelay0, wDelay1, wDelay2, wDelay3, wDelay4, wDelay5, wDelay6, wDelay7, wDelay8, wDelay9,
				 wDelay10, wDelay11, wDelay12, wDelay13, wDelay14, wDelay15, wDelay16, wDelay17, wDelay18, wDelay19,
				 wDelay20, wDelay21, wDelay22, wDelay23, wDelay24, wDelay25, wDelay26, wDelay27, wDelay28, wDelay29,
				 wDelay30, wDelay31, wDelay32, wDelay33, wDelay34, wDelay35, wDelay36, wDelay37, wDelay38, wDelay39
);

reg [2:0] rShifter[0:DEPTH-1];//flip flop shift
integer i;
always @(posedge iClk12M) begin
     if(!iRsn) begin//synchronous reset
    for (i = 0; i < DEPTH; i = i + 1) begin
            rShifter[i] <= 3'b000;
        end
    end
    if(iEnDelay) begin
        if(iEnSample600k) begin//enable
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                rShifter[i] <= rShifter[i-1];
            end
            rShifter[0] <= iFirIn;
        end
    end
end

assign wDelay0 =  rShifter[ 0] + rShifter[78];
assign wDelay1 =  rShifter[ 1] + rShifter[77];
assign wDelay2 =  rShifter[ 2] + rShifter[76];
assign wDelay3 =  rShifter[ 3] + rShifter[75];
assign wDelay4 =  rShifter[ 4] + rShifter[74];
assign wDelay5 =  rShifter[ 5] + rShifter[73];
assign wDelay6 =  rShifter[ 6] + rShifter[72]; 
assign wDelay7 =  rShifter[ 7] + rShifter[71]; 
assign wDelay8 =  rShifter[ 8] + rShifter[70];  
assign wDelay9 =  rShifter[ 9] + rShifter[69];  
assign wDelay10 = rShifter[10] + rShifter[68];  
assign wDelay11 = rShifter[11] + rShifter[67];  
assign wDelay12 = rShifter[12] + rShifter[66]; 
assign wDelay13 = rShifter[13] + rShifter[65]; 
assign wDelay14 = rShifter[14] + rShifter[64]; 
assign wDelay15 = rShifter[15] + rShifter[63];
assign wDelay16 = rShifter[16] + rShifter[62];
assign wDelay17 = rShifter[17] + rShifter[61];
assign wDelay18 = rShifter[18] + rShifter[60];
assign wDelay19 = rShifter[19] + rShifter[59];
assign wDelay20 = rShifter[20] + rShifter[58];
assign wDelay21 = rShifter[21] + rShifter[57];
assign wDelay22 = rShifter[22] + rShifter[56];
assign wDelay23 = rShifter[23] + rShifter[55];
assign wDelay24 = rShifter[24] + rShifter[54];
assign wDelay25 = rShifter[25] + rShifter[53]; 
assign wDelay26 = rShifter[26] + rShifter[52]; 
assign wDelay27 = rShifter[27] + rShifter[51]; 
assign wDelay28 = rShifter[28] + rShifter[50]; 
assign wDelay29 = rShifter[29] + rShifter[49]; 
assign wDelay30 = rShifter[30] + rShifter[48];
assign wDelay31 = rShifter[31] + rShifter[47];
assign wDelay32 = rShifter[32] + rShifter[46];
assign wDelay33 = rShifter[33] + rShifter[45];
assign wDelay34 = rShifter[34] + rShifter[44];
assign wDelay35 = rShifter[35] + rShifter[43];
assign wDelay36 = rShifter[36] + rShifter[42];
assign wDelay37 = rShifter[37] + rShifter[41];
assign wDelay38 = rShifter[38] + rShifter[40];
assign wDelay39 = rShifter[39];



endmodule

