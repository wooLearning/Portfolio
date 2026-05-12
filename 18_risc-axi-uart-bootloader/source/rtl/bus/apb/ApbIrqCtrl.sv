`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbIrqCtrl
Role: Minimal APB external interrupt aggregator
Summary:
  - Latches external peripheral IRQ sources into pending bits
  - Provides enable, pending, clear, and claim-style polling registers
  - Drives one machine external interrupt line to the core
StateDescription:
  - Pending bits latch until cleared by software
[MODULE_INFO_END]
*/
module ApbIrqCtrl #(
  parameter integer P_NUM_SOURCES = 8
) (
  input  logic        iPclk,
  input  logic        iPresetn,
  input  logic [P_NUM_SOURCES-1:0] iIrqSources,
  input  logic        iPSEL,
  input  logic        iPENABLE,
  input  logic        iPWRITE,
  input  logic [11:0] iPADDR,
  input  logic [31:0] iPWDATA,
  input  logic [3:0]  iPSTRB,
  output logic [31:0] oPRDATA,
  output logic        oPREADY,
  output logic        oPSLVERR,
  output logic        oExternalIrq
);

  logic [31:0] rEnable;
  logic [31:0] rPending;
  logic        wWrite;
  logic [31:0] wSourceMask;
  logic [31:0] wEnabledPending;
  integer idx;

  assign wWrite = iPSEL && iPENABLE && iPWRITE;
  assign oPREADY = 1'b1;
  assign oPSLVERR = 1'b0;
  assign wEnabledPending = rEnable & rPending;
  assign oExternalIrq = |wEnabledPending;

  always_comb begin
    wSourceMask = 32'd0;

    for (idx = 0; idx < P_NUM_SOURCES; idx = idx + 1) begin
      wSourceMask[idx] = iIrqSources[idx];
    end
  end

  function automatic logic [31:0] first_pending_id(input logic [31:0] iPending);
    integer idy;
    begin
      first_pending_id = 32'd0;

      for (idy = 0; idy < P_NUM_SOURCES; idy = idy + 1) begin
        if ((first_pending_id == 32'd0) && iPending[idy]) begin
          first_pending_id = idy[31:0] + 32'd1;
        end
      end
    end
  endfunction

  always_comb begin
    oPRDATA = 32'd0;

    unique case (iPADDR[7:0])
      8'h00: oPRDATA = rEnable;
      8'h04: oPRDATA = rPending;
      8'h08: oPRDATA = wEnabledPending;
      8'h0C: oPRDATA = first_pending_id(wEnabledPending);
      default: oPRDATA = 32'd0;
    endcase
  end

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rEnable  <= 32'd0;
      rPending <= 32'd0;
    end
    else begin
      rPending <= rPending | wSourceMask;

      if (wWrite) begin
        unique case (iPADDR[7:0])
          8'h00: rEnable <= iPWDATA;
          8'h04: rPending <= rPending & ~iPWDATA;
          8'h10: begin
            if ((iPWDATA[4:0] != 5'd0) && (iPWDATA[4:0] <= P_NUM_SOURCES)) begin
              rPending <= rPending & ~(32'd1 << (iPWDATA[4:0] - 5'd1));
            end
          end
          default: begin end
        endcase
      end
    end
  end

endmodule
