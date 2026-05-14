`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: InstrRom_master_spi_button
Role: Master FPGA boot ROM for button-triggered SPI switch exchange
Summary:
  - Reads master switches from GPIOA
  - Uses GPIOC bit 0 as a SEND button with software delay debounce
  - Sends a 0x55, low-byte, high-byte SPI frame to the slave
  - Latches the slave switch response onto master LEDs through GPIOA OUT
StateDescription:
  - Program state is held by the RISC-V core registers and APB peripherals
[MODULE_INFO_END]
*/
module InstrRom_master_spi_button #(
  parameter integer P_ADDR_WIDTH = 8,
  parameter integer P_DATA_WIDTH = 32
) (
  input  logic [31:0]             iAddr,
  output logic [P_DATA_WIDTH-1:0] oInstr
);

  localparam integer LP_DEPTH = 48;
  localparam integer LP_WORD_ADDR_WIDTH = (P_ADDR_WIDTH < 6) ? P_ADDR_WIDTH : 6;

  logic [LP_WORD_ADDR_WIDTH-1:0] wWordAddr;
  logic [31:0]                  wWordAddrExt;
  logic                         wAddrInRange;

  assign wWordAddr    = iAddr[LP_WORD_ADDR_WIDTH+1:2];
  assign wWordAddrExt = {{(32-LP_WORD_ADDR_WIDTH){1'b0}}, wWordAddr};
  assign wAddrInRange = (iAddr[31:LP_WORD_ADDR_WIDTH+2] == '0) && (wWordAddrExt < LP_DEPTH);

  function automatic logic [31:0] get_word(input logic [LP_WORD_ADDR_WIDTH-1:0] iWordAddr);
    begin
      unique case (iWordAddr)
        6'd0:  get_word = 32'h40010437; // lui  s0, 0x40010       ; GPIOA base
        6'd1:  get_word = 32'h400304B7; // lui  s1, 0x40030       ; SPI base
        6'd2:  get_word = 32'h40070937; // lui  s2, 0x40070       ; GPIOC/button base
        6'd3:  get_word = 32'hFFF00293; // addi t0, x0, -1
        6'd4:  get_word = 32'h00542423; // sw   t0, 8(s0)         ; GPIOA_DIR
        6'd5:  get_word = 32'h06300293; // addi t0, x0, 99
        6'd6:  get_word = 32'h0054A423; // sw   t0, 8(s1)         ; SPI_CLKDIV
        6'd7:  get_word = 32'h0004A023; // sw   x0, 0(s1)         ; SPI_CTRL mode0/CS0
        6'd8:  get_word = 32'h00492283; // lw   t0, 4(s2)         ; main: read SEND
        6'd9:  get_word = 32'h0012F293; // andi t0, t0, 1
        6'd10: get_word = 32'hFE028CE3; // beq  t0, x0, main
        6'd11: get_word = 32'h084000EF; // jal  ra, delay
        6'd12: get_word = 32'h00492283; // lw   t0, 4(s2)
        6'd13: get_word = 32'h0012F293; // andi t0, t0, 1
        6'd14: get_word = 32'hFE0284E3; // beq  t0, x0, main
        6'd15: get_word = 32'h00442983; // lw   s3, 4(s0)         ; master switches
        6'd16: get_word = 32'h05500513; // addi a0, x0, 0x55      ; frame header
        6'd17: get_word = 32'h03C000EF; // jal  ra, spi_transfer
        6'd18: get_word = 32'h00098513; // addi a0, s3, 0         ; low byte
        6'd19: get_word = 32'h034000EF; // jal  ra, spi_transfer
        6'd20: get_word = 32'h0FF57A13; // andi s4, a0, 255       ; slave low
        6'd21: get_word = 32'h0089D513; // srli a0, s3, 8         ; high byte
        6'd22: get_word = 32'h028000EF; // jal  ra, spi_transfer
        6'd23: get_word = 32'h0FF57513; // andi a0, a0, 255       ; slave high
        6'd24: get_word = 32'h00851513; // slli a0, a0, 8
        6'd25: get_word = 32'h00AA6A33; // or   s4, s4, a0
        6'd26: get_word = 32'h01442023; // sw   s4, 0(s0)         ; master LEDs
        6'd27: get_word = 32'h00492283; // lw   t0, 4(s2)         ; release wait
        6'd28: get_word = 32'h0012F293; // andi t0, t0, 1
        6'd29: get_word = 32'hFE029CE3; // bne  t0, x0, release
        6'd30: get_word = 32'h038000EF; // jal  ra, delay
        6'd31: get_word = 32'hFA5FF06F; // jal  x0, main
        6'd32: get_word = 32'h0044A283; // lw   t0, 4(s1)         ; spi_transfer: STATUS
        6'd33: get_word = 32'h0102F293; // andi t0, t0, 16        ; TX full
        6'd34: get_word = 32'hFE029CE3; // bne  t0, x0, wait_tx
        6'd35: get_word = 32'h00A4A623; // sw   a0, 12(s1)        ; TXDATA
        6'd36: get_word = 32'h0044A283; // lw   t0, 4(s1)         ; wait_rx
        6'd37: get_word = 32'h0042F293; // andi t0, t0, 4         ; RX valid
        6'd38: get_word = 32'hFE028CE3; // beq  t0, x0, wait_rx
        6'd39: get_word = 32'h0104A503; // lw   a0, 16(s1)        ; RXDATA
        6'd40: get_word = 32'h0FF57513; // andi a0, a0, 255
        6'd41: get_word = 32'h00E00293; // addi t0, x0, 14        ; clear sticky bits
        6'd42: get_word = 32'h0054A223; // sw   t0, 4(s1)         ; STATUS clear
        6'd43: get_word = 32'h00008067; // jalr x0, ra, 0
        6'd44: get_word = 32'h00100337; // lui  t1, 0x00100       ; delay
        6'd45: get_word = 32'hFFF30313; // addi t1, t1, -1
        6'd46: get_word = 32'hFE031EE3; // bne  t1, x0, delay_loop
        6'd47: get_word = 32'h00008067; // jalr x0, ra, 0
        default: get_word = 32'h00000013; // nop
      endcase
    end
  endfunction

  assign oInstr = wAddrInRange ? get_word(wWordAddr) : 32'h00000013;

endmodule
