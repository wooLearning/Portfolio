`timescale 1ns/1ps

module basys3_hex4_mux (
  input  logic        iClk,
  input  logic        iRst,
  input  logic [15:0] iHexDigits,
  output logic [6:0]  oSeg,
  output logic        oDp,
  output logic [3:0]  oAn
);

  logic [16:0] rRefreshCnt;
  logic [1:0]  wDigitSel;
  logic [3:0]  wCurDigit;

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rRefreshCnt <= '0;
    end
    else begin
      rRefreshCnt <= rRefreshCnt + 1'b1;
    end
  end

  assign wDigitSel = rRefreshCnt[16:15];

  always_comb begin
    oAn      = 4'b1111;
    oDp      = 1'b1;

    case (wDigitSel)
      2'd0: begin
        oAn = 4'b1110;
      end

      2'd1: begin
        oAn = 4'b1101;
      end

      2'd2: begin
        oAn = 4'b1011;
      end

      default: begin
        oAn = 4'b0111;
      end
    endcase
  end

  assign wCurDigit = iHexDigits[(wDigitSel * 4) +: 4];

  always_comb begin
    oSeg = 7'b1111111;

    case (wCurDigit)
      4'h0: oSeg = 7'b1000000;
      4'h1: oSeg = 7'b1111001;
      4'h2: oSeg = 7'b0100100;
      4'h3: oSeg = 7'b0110000;
      4'h4: oSeg = 7'b0011001;
      4'h5: oSeg = 7'b0010010;
      4'h6: oSeg = 7'b0000010;
      4'h7: oSeg = 7'b1111000;
      4'h8: oSeg = 7'b0000000;
      4'h9: oSeg = 7'b0010000;
      4'hA: oSeg = 7'b0001000;
      4'hB: oSeg = 7'b0000011;
      4'hC: oSeg = 7'b1000110;
      4'hD: oSeg = 7'b0100001;
      4'hE: oSeg = 7'b0000110;
      default: oSeg = 7'b0001110;
    endcase
  end

endmodule
