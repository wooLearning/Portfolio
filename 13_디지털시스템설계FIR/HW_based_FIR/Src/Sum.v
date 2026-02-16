/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : Sum.v
  - Description      : FIR filter SUM
  - Owner            : Sangwook.Woo
  - Revision history : 1) 2024.11.21 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Sum (
	input	signed [15:0]	iMac_1,
	input	signed [15:0]	iMac_2,
	input	signed [15:0]	iMac_3,
	input	signed [15:0]	iMac_4,

	input			iClk12M,
	input			iRsn,
	input			iEnDelay,
	input			iEnSample600k,
	output reg[15:0] oFirOut
);

reg signed [15:0]	rFirOut;
wire signed [15:0]	rMacSum_1;
wire signed [15:0]	rMacSum_2;


assign rMacSum_1 = iMac_1 + iMac_2;
assign rMacSum_2 = iMac_3 + iMac_4;

always @(posedge iClk12M) begin
	if(!iRsn)begin
		rFirOut <= 16'b0;
	end
	else if (iEnDelay)begin
		rFirOut <= rMacSum_1 + rMacSum_2;
	end
	if (iEnSample600k) begin
		oFirOut <= rFirOut;
    end
end

endmodule




















