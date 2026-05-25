`timescale 1ns / 1ps

package address_map_pkg;
  // Generated from config/address_map.yml by Project Console.
  localparam logic [31:0] BOOT_ROM_BASE = 32'h0000_0000;
  localparam logic [31:0] BOOT_ROM_SIZE = 32'h0000_4000;
  localparam integer BOOT_ROM_WORD_ADDR_WIDTH = 12;
  localparam logic [31:0] ISRAM_BASE = 32'h2000_0000;
  localparam logic [31:0] ISRAM_SIZE = 32'h0000_4000;
  localparam integer ISRAM_WORD_ADDR_WIDTH = 12;
  localparam logic [31:0] DSRAM_BASE = 32'h2001_0000;
  localparam logic [31:0] DSRAM_SIZE = 32'h0000_8000;
  localparam integer DSRAM_WORD_ADDR_WIDTH = 13;
  localparam logic [31:0] SRAM_BASE = DSRAM_BASE;
  localparam logic [31:0] SRAM_SIZE = DSRAM_SIZE;
  localparam integer SRAM_WORD_ADDR_WIDTH = DSRAM_WORD_ADDR_WIDTH;
  localparam logic [31:0] RAM_APP_BASE = 32'h2000_0000;
  localparam logic [31:0] RAM_APP_SIZE = 32'h0000_4000;
  localparam logic [31:0] DEBUG_WORKSPACE_BASE = 32'h2001_0000;
  localparam logic [31:0] DEBUG_WORKSPACE_SIZE = 32'h0000_1000;
  localparam logic [31:0] RAM_DATA_BASE = 32'h2001_1000;
  localparam logic [31:0] RAM_DATA_SIZE = 32'h0000_3000;
  localparam logic [31:0] IMAGE_STAGING_BASE = 32'h2001_4000;
  localparam logic [31:0] IMAGE_STAGING_SIZE = 32'h0000_4000;
  localparam logic [31:0] IMAGE_STAGING_HEADER_SIZE = 32'h0000_0012;
  localparam logic [31:0] TIMER_BASE = 32'h4000_0000;
  localparam logic [31:0] TIMER_SIZE = 32'h0000_1000;
  localparam logic [31:0] GPIO_BASE = 32'h4001_0000;
  localparam logic [31:0] GPIO_SIZE = 32'h0000_1000;
  localparam logic [31:0] GPIO_B_BASE = 32'h4002_0000;
  localparam logic [31:0] GPIO_B_SIZE = 32'h0000_1000;
  localparam logic [31:0] SPI_BASE = 32'h4003_0000;
  localparam logic [31:0] SPI_SIZE = 32'h0000_1000;
  localparam logic [31:0] I2C_BASE = 32'h4004_0000;
  localparam logic [31:0] I2C_SIZE = 32'h0000_1000;
  localparam logic [31:0] UART_BASE = 32'h4005_0000;
  localparam logic [31:0] UART_SIZE = 32'h0000_1000;
  localparam logic [31:0] DMA_BASE = 32'h4006_0000;
  localparam logic [31:0] DMA_SIZE = 32'h0000_1000;
  localparam logic [31:0] GPIO_C_BASE = 32'h4007_0000;
  localparam logic [31:0] GPIO_C_SIZE = 32'h0000_1000;
  localparam logic [31:0] PLIC_BASE = 32'h400F_0000;
  localparam logic [31:0] PLIC_SIZE = 32'h0000_1000;
  localparam logic [31:0] PERIPH_BASE = 32'h4000_0000;
  localparam logic [31:0] PERIPH_SIZE = 32'h0010_0000;

  function automatic logic in_range(
    input logic [31:0] iAddr,
    input logic [31:0] iBase,
    input logic [31:0] iSize
  );
    begin
      in_range = (iAddr >= iBase) && (iAddr < (iBase + iSize));
    end
  endfunction

  function automatic logic apb_local_in_range(
    input logic [31:0] iLocalAddr,
    input logic [31:0] iAbsoluteBase,
    input logic [31:0] iSize
  );
    begin
      apb_local_in_range = in_range(iLocalAddr, iAbsoluteBase - PERIPH_BASE, iSize);
    end
  endfunction
endpackage
