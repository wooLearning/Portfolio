/*
 * Minimal freestanding RV32I startup for C firmware smoke tests.
 */

  .section .vectors, "ax"
  .globl _start
  .align 2

_start:
  jal  zero, reset_start

  .org 0x80
trap_entry:
  jal  zero, trap_entry

  .section .text.startup, "ax"
  .globl reset_start
  .align 2

reset_start:
  la   sp, __stack_top

  la   t0, trap_entry
  csrw mtvec, t0

  la   t0, __data_load_start
  la   t1, __data_start
  la   t2, __data_end

copy_data:
  bgeu t1, t2, clear_bss_start
  lw   t3, 0(t0)
  sw   t3, 0(t1)
  addi t0, t0, 4
  addi t1, t1, 4
  jal  zero, copy_data

clear_bss_start:
  la   t1, __bss_start
  la   t2, __bss_end

clear_bss:
  bgeu t1, t2, call_main
  sw   zero, 0(t1)
  addi t1, t1, 4
  jal  zero, clear_bss

call_main:
  call main

main_returned:
  jal  zero, main_returned
