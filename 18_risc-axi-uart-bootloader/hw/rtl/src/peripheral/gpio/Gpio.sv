`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: Gpio
Role: Simple GPIO register block without bus protocol coupling
Summary:
  - Stores output data and direction bits
  - Samples external GPIO input pins
  - Leaves bus register decoding to an outer wrapper
StateDescription:
  - rGpioOut and rGpioDir update on write enables
[MODULE_INFO_END]
*/
module Gpio #(
  parameter integer P_WIDTH = 16
) (
  input  logic                 iClk,
  input  logic                 iRstn,
  input  logic                 iOutWriteEn,
  input  logic                 iDirWriteEn,
  input  logic [P_WIDTH-1:0]   iWriteData,
  input  logic [P_WIDTH-1:0]   iWriteMask,
  input  logic [P_WIDTH-1:0]   iGpioIn,
  output logic [P_WIDTH-1:0]   oGpioIn,
  output logic [P_WIDTH-1:0]   oGpioOut,
  output logic [P_WIDTH-1:0]   oGpioDir
);

  logic [P_WIDTH-1:0] rGpioOut;
  logic [P_WIDTH-1:0] rGpioDir;

  assign oGpioIn  = iGpioIn;
  assign oGpioOut = rGpioOut;
  assign oGpioDir = rGpioDir;

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rGpioOut <= '0;
      rGpioDir <= '0;
    end
    else begin
      if (iOutWriteEn) begin
        rGpioOut <= (rGpioOut & ~iWriteMask) | (iWriteData & iWriteMask);
      end

      if (iDirWriteEn) begin
        rGpioDir <= (rGpioDir & ~iWriteMask) | (iWriteData & iWriteMask);
      end
    end
  end

endmodule
