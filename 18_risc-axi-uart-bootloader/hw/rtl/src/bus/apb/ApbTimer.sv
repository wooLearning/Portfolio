`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbTimer
Role: Minimal APB machine timer peripheral
Summary:
  - Provides 64-bit mtime and mtimecmp registers
  - Supports polling through STATUS and interrupt mode through oTimerIrq
  - Uses zero-wait APB responses
StateDescription:
  - mtime increments while CTRL.EN is set
[MODULE_INFO_END]
*/
module ApbTimer (
  input  logic        iPclk,
  input  logic        iPresetn,
  input  logic        iPSEL,
  input  logic        iPENABLE,
  input  logic        iPWRITE,
  input  logic [11:0] iPADDR,
  input  logic [31:0] iPWDATA,
  input  logic [3:0]  iPSTRB,
  output logic [31:0] oPRDATA,
  output logic        oPREADY,
  output logic        oPSLVERR,
  output logic        oTimerIrq
);

  logic        rEnable;
  logic        rIrqEnable;
  logic [63:0] rMtime;
  logic [63:0] rMtimecmp;
  logic        wWrite;
  logic        wCompareHit;

  assign wWrite      = iPSEL && iPENABLE && iPWRITE;
  assign wCompareHit = (rMtime >= rMtimecmp);
  assign oTimerIrq   = rEnable && rIrqEnable && wCompareHit;
  assign oPREADY     = 1'b1;
  assign oPSLVERR    = 1'b0;

  always_comb begin
    oPRDATA = 32'd0;

    unique case (iPADDR[7:0])
      8'h00: oPRDATA = {30'd0, rIrqEnable, rEnable};
      8'h04: oPRDATA = {31'd0, wCompareHit};
      8'h08: oPRDATA = rMtime[31:0];
      8'h0C: oPRDATA = rMtime[63:32];
      8'h10: oPRDATA = rMtimecmp[31:0];
      8'h14: oPRDATA = rMtimecmp[63:32];
      default: oPRDATA = 32'd0;
    endcase
  end

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rEnable    <= 1'b0;
      rIrqEnable <= 1'b0;
      rMtime     <= 64'd0;
      rMtimecmp  <= 64'hFFFF_FFFF_FFFF_FFFF;
    end
    else begin
      if (rEnable) begin
        rMtime <= rMtime + 64'd1;
      end

      if (wWrite) begin
        unique case (iPADDR[7:0])
          8'h00: begin
            if (iPSTRB[0]) begin
              rEnable    <= iPWDATA[0];
              rIrqEnable <= iPWDATA[1];
            end
          end
          8'h08: rMtime[31:0]    <= iPWDATA;
          8'h0C: rMtime[63:32]   <= iPWDATA;
          8'h10: rMtimecmp[31:0] <= iPWDATA;
          8'h14: rMtimecmp[63:32] <= iPWDATA;
          default: begin end
        endcase
      end
    end
  end

endmodule
