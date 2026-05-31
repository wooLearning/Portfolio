`timescale 1ns/1ps

module uart_baud_tick #(
  parameter int SYS_CLK_HZ   = 100_000_000,
  parameter int DEFAULT_BAUD = 9600,
  parameter int OVERSAMPLE   = 16,
  parameter int ACC_WIDTH    = 32,
  parameter int TICK_GEN_MODE = 1
) (
  input  logic       iClk,
  input  logic       iRst,
  input  logic [3:0] iBaudSel,
  output logic       oTick16x
);

  localparam int MIN_BAUD = 9600;
  localparam int MAX_DIVISOR = (SYS_CLK_HZ + ((MIN_BAUD * OVERSAMPLE) / 2)) /
                               (MIN_BAUD * OVERSAMPLE);
  localparam int DIV_CNT_W = (MAX_DIVISOR > 1) ? $clog2(MAX_DIVISOR) : 1;

  logic [DIV_CNT_W-1:0] rDivCnt;
  logic [ACC_WIDTH-1:0] rPhaseAcc;
  logic [ACC_WIDTH-1:0] wPhaseInc;
  logic [ACC_WIDTH:0]   wPhaseSum;
  logic [DIV_CNT_W-1:0] wDivisor;

  function automatic int select_baud(input logic [3:0] iSel);
    case (iSel)
      4'd0:    select_baud = 9600;
      4'd1:    select_baud = 14400;
      4'd2:    select_baud = 19200;
      4'd3:    select_baud = 38400;
      4'd4:    select_baud = 57600;
      4'd5:    select_baud = 115200;
      4'd6:    select_baud = 230400;
      4'd7:    select_baud = 460800;
      4'd8:    select_baud = 921600;
      default: select_baud = DEFAULT_BAUD;
    endcase
  endfunction

  function automatic logic [DIV_CNT_W-1:0] calc_divisor(input int iBaud);
    logic [63:0] wTickHz;
    logic [63:0] wDivisorFull;
    begin
      wTickHz = iBaud * OVERSAMPLE;
      wDivisorFull = (SYS_CLK_HZ + (wTickHz / 2)) / wTickHz;

      if (wDivisorFull <= 1) begin
        calc_divisor = {{(DIV_CNT_W-1){1'b0}}, 1'b1};
      end
      else begin
        calc_divisor = wDivisorFull[DIV_CNT_W-1:0];
      end
    end
  endfunction

  function automatic logic [ACC_WIDTH-1:0] calc_phase_inc(input int iBaud);
    logic [63:0] wTickHz;
    logic [63:0] wPhaseIncFull;
    begin
      wTickHz = iBaud * OVERSAMPLE;
      wPhaseIncFull = ((wTickHz << ACC_WIDTH) + (SYS_CLK_HZ / 2)) / SYS_CLK_HZ;

      if (wPhaseIncFull == 0) begin
        calc_phase_inc = {{(ACC_WIDTH-1){1'b0}}, 1'b1};
      end
      else begin
        calc_phase_inc = wPhaseIncFull[ACC_WIDTH-1:0];
      end
    end
  endfunction

  always_comb begin
    wDivisor  = calc_divisor(select_baud(iBaudSel));
    wPhaseInc = calc_phase_inc(select_baud(iBaudSel));
  end

  assign wPhaseSum = {1'b0, rPhaseAcc} + {1'b0, wPhaseInc};

  generate
    if (TICK_GEN_MODE == 0) begin : gIntegerDivider
      always_ff @(posedge iClk or posedge iRst) begin
        if (iRst) begin
          rDivCnt  <= '0;
          oTick16x <= 1'b0;
        end
        else if (rDivCnt >= (wDivisor - 1'b1)) begin
          rDivCnt  <= '0;
          oTick16x <= 1'b1;
        end
        else begin
          rDivCnt  <= rDivCnt + 1'b1;
          oTick16x <= 1'b0;
        end
      end
    end
    else begin : gPhaseAccumulator
      always_ff @(posedge iClk or posedge iRst) begin
        if (iRst) begin
          rPhaseAcc <= '0;
          oTick16x  <= 1'b0;
        end
        else begin
          rPhaseAcc <= wPhaseSum[ACC_WIDTH-1:0];
          oTick16x  <= wPhaseSum[ACC_WIDTH];
        end
      end
    end
  endgenerate

endmodule
