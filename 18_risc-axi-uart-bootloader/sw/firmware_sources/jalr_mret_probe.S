/*
 * Minimal ROM probe for JALR/RET and MRET control-flow behavior.
 *
 * GPIOA values:
 *   0x1001: reset code started
 *   0x1111: entered func_ret
 *   0x2002: returned from func_ret
 *   0x2222: entered func_jalr
 *   0x3003: returned from func_jalr
 *   0x5005: la + jalr target reached
 *   0x6006: before ecall
 *   0x6606: trap handler reached
 *   0x7007: returned from mret
 *   0x55aa: pass loop
 */

  .section .vectors, "ax"
  .globl _start
  .align 2

_start:
  jal zero, reset_start

  .org 0x80
trap_entry:
  li   t0, 0x40010000
  li   t1, 0x6606
  sw   t1, 0(t0)

  csrr t2, mepc
  addi t2, t2, 4
  csrw mepc, t2
  mret

  .section .text.startup, "ax"
  .align 2

reset_start:
  li   s0, 0x40010000
  li   t0, 0x0000ffff
  sw   t0, 8(s0)

  li   t0, 0x1001
  sw   t0, 0(s0)

  jal  ra, func_ret

  li   t0, 0x2002
  sw   t0, 0(s0)

  jal  ra, func_jalr

  li   t0, 0x3003
  sw   t0, 0(s0)

  la   t0, jalr_target
  jalr zero, 0(t0)

wrong_path:
  li   t0, 0xe001
  sw   t0, 0(s0)
  jal  zero, wrong_path

jalr_target:
  li   t0, 0x5005
  sw   t0, 0(s0)

  la   t0, trap_entry
  csrw mtvec, t0

  li   t0, 0x6006
  sw   t0, 0(s0)
  ecall

  li   t0, 0x7007
  sw   t0, 0(s0)

pass_loop:
  li   t0, 0x55aa
  sw   t0, 0(s0)
  jal  zero, pass_loop

func_ret:
  li   t0, 0x1111
  sw   t0, 0(s0)
  ret

func_jalr:
  li   t0, 0x2222
  sw   t0, 0(s0)
  jalr zero, 0(ra)
