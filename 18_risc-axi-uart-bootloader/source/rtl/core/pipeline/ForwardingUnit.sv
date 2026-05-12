`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ForwardingUnit
Role: RTL module implementing EX-stage bypass selection
Summary:
  - Selects EX operand forwarding from EX/MEM or MEM/WB
  - Prioritizes the younger EX/MEM result over MEM/WB
StateDescription:
  - Combinational only: no internal state
[MODULE_INFO_END]
*/
module ForwardingUnit (
  input  logic [4:0] iExRs1Addr,
  input  logic [4:0] iExRs2Addr,
  input  logic       iExUsesRs1,
  input  logic       iExUsesRs2,
  input  logic [4:0] iMemRdAddr,
  input  logic       iMemForwardEn,
  input  logic [4:0] iWbRdAddr,
  input  logic       iWbForwardEn,
  output logic [1:0] oForwardA,
  output logic [1:0] oForwardB
);

  always_comb begin
    oForwardA = 2'b00;
    oForwardB = 2'b00;

    if (iExUsesRs1 && iMemForwardEn && (iMemRdAddr != 5'd0) &&
        (iMemRdAddr == iExRs1Addr)) begin
      oForwardA = 2'b10;
    end else if (iExUsesRs1 && iWbForwardEn && (iWbRdAddr != 5'd0) &&
                 (iWbRdAddr == iExRs1Addr)) begin
      oForwardA = 2'b01;
    end

    if (iExUsesRs2 && iMemForwardEn && (iMemRdAddr != 5'd0) &&
        (iMemRdAddr == iExRs2Addr)) begin
      oForwardB = 2'b10;
    end else if (iExUsesRs2 && iWbForwardEn && (iWbRdAddr != 5'd0) &&
                 (iWbRdAddr == iExRs2Addr)) begin
      oForwardB = 2'b01;
    end
  end

endmodule
