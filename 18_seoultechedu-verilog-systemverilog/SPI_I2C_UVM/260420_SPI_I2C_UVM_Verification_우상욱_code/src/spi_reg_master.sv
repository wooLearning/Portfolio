`timescale 1ns/1ps

module spi_reg_master (
  input  logic       iClk,
  input  logic       iTick,
  input  logic       iRst,
  input  logic       iStart,
  input  logic       iCpol,
  input  logic       iCpha,
  input  logic [1:0] iRegSel,
  input  logic [7:0] iTxData,
  input  logic       iMiso,
  output logic [7:0] oRxData,
  output logic       oBusy,
  output logic       oDone,
  output logic       oSclk,
  output logic [3:0] oCsN,
  output logic       oMosi
);

  logic [1:0] rRegSel;
  logic [1:0] wActiveSel;
  logic       wSpiCsN;

  spi_master uSpiMaster (
    .iClk   (iClk),
    .iTick  (iTick),
    .iRst   (iRst),
    .iStart (iStart),
    .iCpol  (iCpol),
    .iCpha  (iCpha),
    .iTxData(iTxData),
    .iMiso  (iMiso),
    .oRxData(oRxData),
    .oBusy  (oBusy),
    .oDone  (oDone),
    .oSclk  (oSclk),
    .oCsN   (wSpiCsN),
    .oMosi  (oMosi)
  );

  always_ff @(posedge iClk or posedge iRst) begin
    if (iRst) begin
      rRegSel <= 2'b00;
    end
    else if (iStart && !oBusy) begin
      rRegSel <= iRegSel;
    end
  end

  always_comb begin
    oCsN = 4'b1111;
    wActiveSel = oBusy ? rRegSel : iRegSel;

    case (wActiveSel)
      2'd0: oCsN[0] = wSpiCsN;
      2'd1: oCsN[1] = wSpiCsN;
      2'd2: oCsN[2] = wSpiCsN;
      default: oCsN[3] = wSpiCsN;
    endcase
  end

endmodule
