/*
 * Probe the exact trap-entry call/return shape used by startup_irq.S:
 * trap saves registers, calls a handler, handler returns with ret,
 * trap writes A0F0 and mret returns to main.
 */

  .section .vectors, "ax"
  .globl _start
  .align 2

_start:
  jal zero, reset_start

  .org 0x80
trap_entry:
  addi sp, sp, -128
  sw   ra, 0(sp)
  sw   gp, 4(sp)
  sw   tp, 8(sp)
  sw   t0, 12(sp)
  sw   t1, 16(sp)
  sw   t2, 20(sp)
  sw   s0, 24(sp)
  sw   s1, 28(sp)
  sw   a0, 32(sp)
  sw   a1, 36(sp)
  sw   a2, 40(sp)
  sw   a3, 44(sp)
  sw   a4, 48(sp)
  sw   a5, 52(sp)
  sw   a6, 56(sp)
  sw   a7, 60(sp)
  sw   s2, 64(sp)
  sw   s3, 68(sp)
  sw   s4, 72(sp)
  sw   s5, 76(sp)
  sw   s6, 80(sp)
  sw   s7, 84(sp)
  sw   s8, 88(sp)
  sw   s9, 92(sp)
  sw   s10, 96(sp)
  sw   s11, 100(sp)
  sw   t3, 104(sp)
  sw   t4, 108(sp)
  sw   t5, 112(sp)
  sw   t6, 116(sp)

  call trap_probe_handler

  li   t0, 0x40010000
  li   t1, 0xA0F0
  sw   t1, 0(t0)

  lw   ra, 0(sp)
  lw   gp, 4(sp)
  lw   tp, 8(sp)
  lw   t0, 12(sp)
  lw   t1, 16(sp)
  lw   t2, 20(sp)
  lw   s0, 24(sp)
  lw   s1, 28(sp)
  lw   a0, 32(sp)
  lw   a1, 36(sp)
  lw   a2, 40(sp)
  lw   a3, 44(sp)
  lw   a4, 48(sp)
  lw   a5, 52(sp)
  lw   a6, 56(sp)
  lw   a7, 60(sp)
  lw   s2, 64(sp)
  lw   s3, 68(sp)
  lw   s4, 72(sp)
  lw   s5, 76(sp)
  lw   s6, 80(sp)
  lw   s7, 84(sp)
  lw   s8, 88(sp)
  lw   s9, 92(sp)
  lw   s10, 96(sp)
  lw   s11, 100(sp)
  lw   t3, 104(sp)
  lw   t4, 108(sp)
  lw   t5, 112(sp)
  lw   t6, 116(sp)
  addi sp, sp, 128
  mret

  .section .text.startup, "ax"
  .align 2

reset_start:
  la   sp, __stack_top
  li   s0, 0x40010000
  li   t0, 0xffff
  sw   t0, 8(s0)

  la   t0, trap_entry
  csrw mtvec, t0

  li   t0, 0x1001
  sw   t0, 0(s0)
  ecall

  li   t0, 0x55aa
pass_loop:
  sw   t0, 0(s0)
  jal  zero, pass_loop

trap_probe_handler:
  li   t0, 0x40010000
  li   t1, 0xA0D6
  sw   t1, 0(t0)

  csrr t1, mepc
  addi t1, t1, 4
  csrw mepc, t1
  ret
