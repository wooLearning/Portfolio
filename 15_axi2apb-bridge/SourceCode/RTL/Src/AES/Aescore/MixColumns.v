module MixColumns(
  input[127:0] iText,
  output[127:0] oMixColumnsOut
);

function [7:0] mb2; //multiply by 2
  input [7:0] x;
    begin 
      if(x[7] == 1) mb2 = ((x << 1) ^ 8'h1b);//0001_1011
      else mb2 = x << 1; 
    end 	
endfunction

function [7:0] mb3; //multiply by 3
  input [7:0] x;
  begin
    mb3 = mb2(x) ^ x;
  end 
endfunction

genvar i;


for(i=0;i<4;i=i+1) begin //colums4
  assign oMixColumnsOut[(i*32+24) +: 8] = mb2(iText[(i*32+24) +: 8]) 
                                        ^ mb3(iText[(i*32 + 16)+:8]) 
                                        ^ iText[(i*32 + 8)+:8] 
                                        ^ iText[(i*32) +: 8];

  assign oMixColumnsOut[(i*32 + 16) +: 8] = iText[(i*32+24) +:8] 
                                        ^ mb2(iText[(i*32+16) +: 8]) 
                                        ^ mb3(iText[(i*32 + 8) +: 8])
                                        ^ iText[(i*32) +: 8];

  assign oMixColumnsOut[(i*32 + 8) +: 8] = iText[(i*32+24) +: 8] 
                                       ^ iText[(i*32 + 16) +: 8] 
                                       ^ mb2(iText[(i*32 + 8) +: 8]) 
                                       ^ mb3(iText[(i*32) +: 8]);

  assign oMixColumnsOut[(i*32) +: 8] = mb3(iText[(i*32+24) +: 8]) 
                                 ^ iText[(i*32 +16) +: 8] 
                                 ^ iText[(i*32 + 8) +: 8] 
                                 ^ mb2(iText[(i*32) +: 8]);
end

/*
genvar i;

generate 
for(i=0;i< 4;i=i+1) begin : m_col

	assign oMixColumnsOut[(i*32 + 24)+:8]= mb2(iText[(i*32 + 24)+:8]) ^ mb3(iText[(i*32 + 16)+:8]) ^ iText[(i*32 + 8)+:8] ^ iText[i*32+:8];
	assign oMixColumnsOut[(i*32 + 16)+:8]= iText[(i*32 + 24)+:8] ^ mb2(iText[(i*32 + 16)+:8]) ^ mb3(iText[(i*32 + 8)+:8]) ^ iText[i*32+:8];
	assign oMixColumnsOut[(i*32 + 8)+:8]= iText[(i*32 + 24)+:8] ^ iText[(i*32 + 16)+:8] ^ mb2(iText[(i*32 + 8)+:8]) ^ mb3(iText[i*32+:8]);
   assign oMixColumnsOut[i*32+:8]= mb3(iText[(i*32 + 24)+:8]) ^ iText[(i*32 + 16)+:8] ^ iText[(i*32 + 8)+:8] ^ mb2(iText[i*32+:8]);

end
endgenerate
*/

endmodule


