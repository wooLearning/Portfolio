  /*
   * uart_dma_spi_forward.S
   *
   * Master FPGA ROM program for the image-transfer smoke test:
   *   PC UART -> master UART RX stream -> DMA internal buffer
   *           -> DMA TX stream -> master SPI -> slave FPGA -> UART -> PC
   *
   * The CPU only configures APB MMIO registers and polls DMA completion.
   * Image bytes never go through CPU SRAM; they live in the DMA internal
   * buffer. The expected payload length is 4096 bytes (64x64 gray8).
   */

  .equ GPIOA_BASE,       0x40010000
  .equ SPI_BASE,         0x40030000
  .equ UART_BASE,        0x40050000
  .equ DMA_BASE,         0x40060000

  .equ GPIO_OUT,         0x00
  .equ GPIO_IN,          0x04
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
  li   t0, IMAGE_BYTES
  sw   t0, DMA_LEN_BYTES(s3)

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

  addi t0, zero, 6
  sw   t0, DMA_CLEAR(s3)
  sw   zero, DMA_BUF_ADDR(s3)
  li   t0, IMAGE_BYTES
  sw   t0, DMA_LEN_BYTES(s3)

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

dma_error:
  lui  t0, 0xE
  addi t0, t0, 1
  sw   t0, GPIO_OUT(s0)
  jal  zero, dma_error
