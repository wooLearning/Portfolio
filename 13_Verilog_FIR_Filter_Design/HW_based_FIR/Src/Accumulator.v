/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : Accumulator.v
  - Description      : Accumulator
  - Owner            : Dongjun.Joo
  - Revision history : 1) 2024.11.21 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Accumulator (
    input iClk12M,
    input   [15:0]    iMul_0,
    input   [15:0]    iMul_1,
    input   [15:0]    iMul_2,
    input   [15:0]    iMul_3,
    input   [15:0]    iMul_4,
    input   [15:0]    iMul_5,
    input   [15:0]    iMul_6,
    input   [15:0]    iMul_7,
    input   [15:0]    iMul_8,
    input   [15:0]    iMul_9,
    input iEnMul,
    input   iEnAdd,
    input   iEnAcc,
    output reg  [15:0] oAccOut
);

  
    wire [15:0] wAccOut;
    wire [15:0] wAccDt;  
    wire wInsel;
    wire [15:0] wMul;
    reg   [3:0]   iSelection=0;
    assign wInsel = (iSelection==1'b0)? 1'b0 :1'b1;
    assign wAccDt = (wInsel==1'b0) ? 16'h0 : oAccOut;

    /*************************************************************/
    // Adder
    /*************************************************************/

    assign wAccOut = (iEnAdd == 1'b1) ? (wMul + wAccDt) : 16'b0;

  // Mux Select
  /*************************************************************/
    assign wMul = (iSelection == 4'd0) ? iMul_0 :
	               (iSelection == 4'd1) ? iMul_1 :
						(iSelection == 4'd2) ? iMul_2 :
						(iSelection == 4'd3) ? iMul_3 :
						(iSelection == 4'd4) ? iMul_4 :
						(iSelection == 4'd5) ? iMul_5 :
						(iSelection == 4'd6) ? iMul_6 :
						(iSelection == 4'd7) ? iMul_7 :
						(iSelection == 4'd8) ? iMul_8 :
						(iSelection == 4'd9) ? iMul_9 : 16'd0;
  /*************************************************************/
  // Final output
  /*************************************************************/
    always @(posedge iClk12M) begin	 
	  if(iEnAdd)begin
		 oAccOut <= wAccOut;
		 iSelection <= iSelection + 1'b1;
	  end
	  
	  else if( (iEnMul == 1'b1) && (iEnAdd == 1'b0) )
	  begin
	    oAccOut <= oAccOut;
	    iSelection <= 4'd0;
	  end
	  
	  else if(iSelection==4'd10) begin
		 iSelection <= 4'd10;
	  end
	  
	  else
		 oAccOut <= oAccOut;
		
    end

endmodule
