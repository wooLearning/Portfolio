`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ButtonGpioSync
Role: Two-flop synchronizer for raw FPGA push buttons before GPIO sampling
Summary:
  - Brings asynchronous board button inputs into the SoC clock domain
  - Leaves debounce policy to the instruction ROM polling loop
StateDescription:
  - Two register stages track each button input after reset release
[MODULE_INFO_END]
*/
module ButtonGpioSync #(
  parameter integer P_WIDTH = 4
) (
  input  logic               iClk,
  input  logic               iRstn,
  input  logic [P_WIDTH-1:0] iBtnRaw,
  output logic [P_WIDTH-1:0] oBtnSync
);

  logic [P_WIDTH-1:0] rBtnMeta;

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rBtnMeta <= '0;
      oBtnSync <= '0;
    end
    else begin
      rBtnMeta <= iBtnRaw;
      oBtnSync <= rBtnMeta;
    end
  end

endmodule
