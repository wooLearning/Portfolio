module SubBytes(
  input [127:0] iText,
  output [127:0] oSubBytesOut
);

genvar i;

for(i=0;i<128;i=i+8) begin 
  Sbox Sbox0(iText[i+7:i],oSubBytesOut[i+7:i]);
end

endmodule
