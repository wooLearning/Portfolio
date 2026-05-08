`timescale 1ns/1ps

module digit_register_bank (
  input  logic        iClk,
  input  logic        iRst,
  input  logic        iWrEn,
  input  logic [3:0]  iWrAddr,
  input  logic [7:0]  iWrData,
  output logic [15:0] oDigits
);

  logic [3:0] rDigit0;
  logic [3:0] rDigit1;
  logic [3:0] rDigit2;
  logic [3:0] rDigit3;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rDigit0 <= 4'h0;
      rDigit1 <= 4'h0;
      rDigit2 <= 4'h0;
      rDigit3 <= 4'h0;
    end
    else if (iWrEn) begin
      case (iWrAddr)
        4'h0: rDigit0 <= iWrData[3:0];
        4'h1: rDigit1 <= iWrData[3:0];
        4'h2: rDigit2 <= iWrData[3:0];
        4'h3: rDigit3 <= iWrData[3:0];
        default: begin
        end
      endcase
    end
  end

  assign oDigits = {rDigit3, rDigit2, rDigit1, rDigit0};

endmodule
