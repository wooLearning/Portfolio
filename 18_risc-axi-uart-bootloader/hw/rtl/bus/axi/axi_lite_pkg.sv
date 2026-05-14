`timescale 1ns / 1ps

package axi_lite_pkg;
  localparam logic [1:0] RESP_OKAY   = 2'b00;
  localparam logic [1:0] RESP_SLVERR = 2'b10;

  localparam logic [31:0] ROM_BASE    = 32'h0000_0000;
  localparam logic [31:0] ROM_MASK    = 32'hFFFF_0000;
  localparam logic [31:0] SRAM_BASE   = 32'h2000_0000;
  localparam logic [31:0] SRAM_MASK   = 32'hFFFF_0000;
  localparam logic [31:0] PERIPH_BASE = 32'h4000_0000;
  localparam logic [31:0] PERIPH_MASK = 32'hFFF0_0000;

  function automatic logic [3:0] size_to_strb(
    input logic [1:0]  iSize,
    input logic [1:0]  iAddr
  );
    begin
      unique case (iSize)
        2'b00: begin
          unique case (iAddr)
            2'd0:    size_to_strb = 4'b0001;
            2'd1:    size_to_strb = 4'b0010;
            2'd2:    size_to_strb = 4'b0100;
            default: size_to_strb = 4'b1000;
          endcase
        end

        2'b01: begin
          size_to_strb = iAddr[1] ? 4'b1100 : 4'b0011;
        end

        default: begin
          size_to_strb = 4'b1111;
        end
      endcase
    end
  endfunction
endpackage
