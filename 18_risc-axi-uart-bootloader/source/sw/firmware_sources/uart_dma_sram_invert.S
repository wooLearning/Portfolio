  /*
   * uart_dma_sram_invert.S
   *
   * Master FPGA ROM program with a CPU image-processing stage:
   *   PC UART -> DMA internal buffer -> CPU SRAM -> CPU invert
   *           -> DMA internal buffer -> SPI -> slave FPGA -> UART -> PC
   *
   * Current hardware does not yet have a DMA SRAM-copy mode, so the CPU copies
   * bytes between the DMA debug buffer port and SRAM through MMIO while DMA is
   * idle. The stream transfers themselves still use DMA.
   */

  .equ GPIOA_BASE,       0x40010000
  .equ SPI_BASE,         0x40030000
  .equ UART_BASE,        0x40050000
  .equ DMA_BASE,         0x40060000
  .equ SRAM_BASE,        0x20000000

  .equ GPIO_OUT,         0x00
  .equ GPIO_DIR,         0x08

  .equ SPI_CTRL,         0x00
  .equ SPI_STATUS,       0x04
  .equ SPI_CLKDIV,       0x08

  .equ UART_CTRL,        0x00
  .equ UART_STATUS,      0x04
  .equ UART_BAUDDIV,     0x08

  .equ DMA_CTRL,         0x00
  .equ DMA_STATUS,       0x04
  .equ DMA_LEN_BYTES,    0x08
  .equ DMA_CLEAR,        0x10
  .equ DMA_BUF_ADDR,     0x14
  .equ DMA_BUF_DATA,     0x18

#ifndef IMAGE_BYTES_VALUE
#define IMAGE_BYTES_VALUE 4096
#endif

  .equ IMAGE_BYTES,      IMAGE_BYTES_VALUE
  .equ UART_DIV_115200,  26
  .equ SPI_SAFE_DIV,     99

  .section .vectors, "ax"
  .globl _start
  .align 2

_start:
  jal  zero, reset_main

  .section .text.startup, "ax"
  .align 2

reset_main:
  lui  sp, 0x20004
  lui  s0, 0x40010
  lui  s1, 0x40030
  lui  s2, 0x40050
  lui  s3, 0x40060
  lui  s4, 0x20000
  li   s5, IMAGE_BYTES

  addi t0, zero, -1
  sw   t0, GPIO_DIR(s0)

  lui  t0, 0x1
  addi t0, t0, 1
  sw   t0, GPIO_OUT(s0)

  sw   zero, UART_CTRL(s2)
  addi t0, zero, UART_DIV_115200
  sw   t0, UART_BAUDDIV(s2)
  addi t0, zero, 30
  sw   t0, UART_STATUS(s2)
  addi t0, zero, 16
  sw   t0, UART_CTRL(s2)

  sw   zero, SPI_CTRL(s1)
  addi t0, zero, SPI_SAFE_DIV
  sw   t0, SPI_CLKDIV(s1)
  addi t0, zero, 14
  sw   t0, SPI_STATUS(s1)
  addi t0, zero, 32
  sw   t0, SPI_CTRL(s1)

main_loop:
  addi t0, zero, 6
  sw   t0, DMA_CLEAR(s3)
  sw   zero, DMA_BUF_ADDR(s3)
  sw   s5, DMA_LEN_BYTES(s3)

  lui  t1, 0x2
  sw   t1, GPIO_OUT(s0)

  addi t0, zero, 1
  sw   t0, DMA_CTRL(s3)

wait_uart_to_dma:
  lw   t0, DMA_STATUS(s3)
  addi zero, zero, 0
  addi zero, zero, 0
  andi t1, t0, 4
  bne  t1, zero, dma_error
  andi t1, t0, 2
  beq  t1, zero, wait_uart_to_dma

  lui  t1, 0x4
  sw   t1, GPIO_OUT(s0)
  jal  ra, copy_dma_to_sram

  lui  t1, 0x8
  sw   t1, GPIO_OUT(s0)
  jal  ra, invert_sram

  lui  t1, 0x6
  sw   t1, GPIO_OUT(s0)
  jal  ra, copy_sram_to_dma

  addi t0, zero, 6
  sw   t0, DMA_CLEAR(s3)
  sw   zero, DMA_BUF_ADDR(s3)
  sw   s5, DMA_LEN_BYTES(s3)

  lui  t1, 0x3
  sw   t1, GPIO_OUT(s0)

  addi t0, zero, 5
  sw   t0, DMA_CTRL(s3)

wait_dma_to_spi:
  lw   t0, DMA_STATUS(s3)
  addi zero, zero, 0
  addi zero, zero, 0
  andi t1, t0, 4
  bne  t1, zero, dma_error
  andi t1, t0, 2
  beq  t1, zero, wait_dma_to_spi

  lui  t0, 0x5
  addi t0, t0, 13
  sw   t0, GPIO_OUT(s0)
  jal  zero, main_loop

copy_dma_to_sram:
  addi t2, zero, 0

copy_dma_to_sram_loop:
  add  t3, s4, t2
  sw   t2, DMA_BUF_ADDR(s3)
  addi zero, zero, 0
  addi zero, zero, 0
  addi zero, zero, 0
  addi zero, zero, 0
  lw   t4, DMA_BUF_DATA(s3)
  addi zero, zero, 0
  addi zero, zero, 0
  andi t4, t4, 255
  sb   t4, 0(t3)
  addi t2, t2, 1
  bne  t2, s5, copy_dma_to_sram_loop
  jalr zero, ra, 0

invert_sram:
  addi t2, zero, 0
  addi t5, zero, 255

invert_sram_loop:
  add  t3, s4, t2
  lbu  t4, 0(t3)
  addi zero, zero, 0
  addi zero, zero, 0
  sub  t4, t5, t4
  sb   t4, 0(t3)
  addi t2, t2, 1
  bne  t2, s5, invert_sram_loop
  jalr zero, ra, 0

copy_sram_to_dma:
  addi t2, zero, 0

copy_sram_to_dma_loop:
  add  t3, s4, t2
  lbu  t4, 0(t3)
  addi zero, zero, 0
  addi zero, zero, 0
  sw   t2, DMA_BUF_ADDR(s3)
  addi zero, zero, 0
  addi zero, zero, 0
  sw   t4, DMA_BUF_DATA(s3)
  addi t2, t2, 1
  bne  t2, s5, copy_sram_to_dma_loop
  jalr zero, ra, 0

dma_error:
  lui  t0, 0xE
  addi t0, t0, 1
  sw   t0, GPIO_OUT(s0)
  jal  zero, dma_error
