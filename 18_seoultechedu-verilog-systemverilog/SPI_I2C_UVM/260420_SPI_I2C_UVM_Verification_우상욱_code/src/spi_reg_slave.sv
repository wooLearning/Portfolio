`timescale 1ns/1ps

module spi_reg_slave (
  input  logic        iClk,
  input  logic        iRst,
  input  logic        iCpol,
  input  logic        iCpha,
  input  logic        iSclk,
  input  logic [3:0]  iCsN,
  input  logic        iMosi,
  input  logic [15:0] iRegDigits,
  output logic        oWrEn,
  output logic [3:0]  oWrAddr,
  output logic [7:0]  oWrData,
  output logic        oMiso
);

  logic [31:0] wSpiRxData;
  logic [3:0]  wSpiRxValid;
  logic [3:0]  wSpiMiso;

  function automatic logic [7:0] read_reg_value(
    input logic [15:0] iDigits,
    input logic [3:0]  iAddr
  );
    case (iAddr)
      4'h0: read_reg_value = {4'h0, iDigits[3:0]};
      4'h1: read_reg_value = {4'h0, iDigits[7:4]};
      4'h2: read_reg_value = {4'h0, iDigits[11:8]};
      4'h3: read_reg_value = {4'h0, iDigits[15:12]};
      default: read_reg_value = 8'h00;
    endcase
  endfunction

  generate
    for (genvar idx = 0; idx < 4; idx++) begin : gSpiReg
      localparam logic [3:0] REG_ADDR = idx[3:0];

      spi_slave uSpiSlave (
        .iClk   (iClk),
        .iRst   (iRst),
        .iCpol  (iCpol),
        .iCpha  (iCpha),
        .iSclk  (iSclk),
        .iCsN   (iCsN[idx]),
        .iMosi  (iMosi),
        .iTxData(read_reg_value(iRegDigits, REG_ADDR)),
        .oRxData(wSpiRxData[idx*8 +: 8]),
        .oRxValid(wSpiRxValid[idx]),
        .oMiso  (wSpiMiso[idx])
      );
    end
  endgenerate

  always_comb begin
    oWrEn   = 1'b0;
    oWrAddr = 4'h0;
    oWrData = 8'h00;
    oMiso   = 1'b0;

    for (int idx = 0; idx < 4; idx++) begin
      if (!iCsN[idx]) begin
        oMiso = wSpiMiso[idx];
      end

      if (wSpiRxValid[idx]) begin
        oWrEn   = 1'b1;
        oWrAddr = idx[3:0];
        oWrData = wSpiRxData[idx*8 +: 8];
      end
    end
  end

endmodule
