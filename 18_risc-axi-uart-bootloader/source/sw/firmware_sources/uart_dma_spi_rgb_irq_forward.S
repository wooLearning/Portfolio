  /*
   * uart_dma_spi_rgb_irq_forward.S
   *
   * RGB888 64x64 이미지 패스스루용 master FPGA ROM 코드.
   *
   * 전체 데이터 흐름:
   *   1. PC가 master FPGA의 UART RX로 RGB byte stream을 보낸다.
   *   2. UART RX stream은 DMA 내부 byte buffer에 저장된다.
   *   3. DMA RX가 IMAGE_BYTES만큼 받으면 DMA_DONE interrupt를 발생시킨다.
   *   4. PLIC가 DMA_DONE interrupt를 CPU machine external interrupt로 전달한다.
   *   5. CPU trap handler가 PLIC claim ID를 읽고, software vector table로 handler를 고른다.
   *   6. DMA_DONE handler가 SRAM FLAG_DONE을 1로 세운다.
   *   7. main loop는 FLAG_DONE을 보고 DMA TX 방향을 켜서 DMA buffer를 SPI로 내보낸다.
   *   8. slave FPGA가 SPI byte를 받아 UART TX로 PC에 다시 보낸다.
   *
   * 주의:
   *   - 이미지 payload는 CPU SRAM에 저장하지 않는다.
   *   - CPU는 MMIO 제어와 interrupt 처리만 담당한다.
   *   - DMA payload는 DMA 내부 buffer에 있다.
   *   - trap handler 안에서는 PLIC claim ID를 software vector table 인덱스로 사용한다.
   */

  .equ GPIOA_BASE,       0x40010000
  .equ SPI_BASE,         0x40030000
  .equ UART_BASE,        0x40050000
  .equ DMA_BASE,         0x40060000
  .equ PLIC_BASE,        0x400F0000
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
  .equ DMA_LEN_BYTES,    0x08
  .equ DMA_CLEAR,        0x10
  .equ DMA_BUF_ADDR,     0x14

  .equ PLIC_ENABLE,      0x00
  .equ PLIC_CLAIM,       0x0C
  .equ PLIC_COMPLETE,    0x10
  .equ PLIC_THRESHOLD,   0x14
  .equ PLIC_PRIO_DMA_DONE,  0x34
  .equ PLIC_PRIO_DMA_ERROR, 0x38

  .equ FLAG_DONE,        0x00
  .equ FLAG_ERROR,       0x04
  .equ LAST_IRQ_SOURCE,  0x08
  .equ IRQ_COUNT,        0x0C

#ifndef IMAGE_BYTES_VALUE
#define IMAGE_BYTES_VALUE 12288
#endif

  .equ IMAGE_BYTES,      IMAGE_BYTES_VALUE
  .equ UART_DIV_115200,  26
  .equ SPI_SAFE_DIV,     99
  .equ IRQ_ID_DMA_DONE,  6
  .equ IRQ_ID_DMA_ERROR, 7
  .equ PLIC_DMA_MASK,    0x60

  .section .vectors, "ax"
  .globl _start
  .align 2

_start:
  /* reset 직후에는 trap 영역을 건너뛰고 실제 초기화 코드로 이동한다. */
  jal  zero, reset_main

  /*
   * mtvec direct mode 진입 주소.
   * reset_main에서 mtvec을 0x80으로 설정하므로 모든 trap/interrupt는 여기로 들어온다.
   */
  .org 0x80
trap_entry:
  /*
   * trap handler가 main loop의 임시 레지스터 값을 깨지 않도록 caller-saved 일부를 보존한다.
   * 이 ROM에서는 s0~s5를 base address 레지스터로 계속 쓰므로 handler에서 건드리지 않는다.
   */
  addi sp, sp, -64
  sw   ra, 0(sp)
  sw   t0, 4(sp)
  sw   t1, 8(sp)
  sw   t2, 12(sp)
  sw   t3, 16(sp)
  sw   t4, 20(sp)
  sw   t5, 24(sp)
  sw   t6, 28(sp)
  sw   a0, 32(sp)
  sw   a1, 36(sp)
  sw   a2, 40(sp)
  sw   a3, 44(sp)

  /*
   * mcause[31]이 1이면 interrupt, 0이면 exception이다.
   * 현재 demo에서 정상적으로 기대하는 것은 PLIC를 통한 machine external interrupt뿐이다.
   */
  csrr t0, mcause
  addi zero, zero, 0
  addi zero, zero, 0
  blt  t0, zero, irq_external
  jal  zero, trap_unhandled

irq_external:
  /*
   * PLIC claim register를 읽어서 어떤 interrupt source가 들어왔는지 확인한다.
   * 이 SoC의 source ID는 PLIC 내부 bit index + 1이다.
   *
   *   claim ID 6: DMA_DONE
   *   claim ID 7: DMA_ERROR
   *
   * APB/AXI-Lite read data가 CPU load 결과로 안정화될 시간을 주기 위해
   * claim load 뒤에는 여유 NOP를 둔다. 현재 core의 load-use 경로에서
   * MMIO read 바로 다음 분기를 타면 값이 늦게 보일 수 있어서 안전하게 둔 것이다.
   */
  lui  t0, 0x400F0
  lw   t1, PLIC_CLAIM(t0)
  addi zero, zero, 0
  addi zero, zero, 0
  addi zero, zero, 0
  addi zero, zero, 0
  addi zero, zero, 0
  addi zero, zero, 0
  beq  t1, zero, trap_exit

  /*
   * 디버그용 소프트웨어 상태를 SRAM 앞쪽에 저장한다.
   * FLAG_DONE/FLAG_ERROR는 main loop가 기다리는 완료 플래그이고,
   * LAST_IRQ_SOURCE/IRQ_COUNT는 보드나 시뮬레이션에서 interrupt 진행 상황을 볼 때 쓴다.
   */
  lui  t2, 0x20000
  sw   t1, LAST_IRQ_SOURCE(t2)
  lw   t3, IRQ_COUNT(t2)
  addi zero, zero, 0
  addi zero, zero, 0
  addi zero, zero, 0
  addi zero, zero, 0
  addi t3, t3, 1
  sw   t3, IRQ_COUNT(t2)

  /*
   * Software vector table dispatch.
   *
   * PLIC claim ID를 table index로 사용한다.
   * table[0]은 claim ID 0, 즉 "처리할 interrupt 없음" 자리라 unused handler로 둔다.
   * DMA_DONE은 ID 6, DMA_ERROR는 ID 7에 handler를 연결했다.
   *
   * 하드웨어 mtvec vectored mode가 아니라, direct trap handler 안에서
   * 소프트웨어가 직접 handler 주소를 읽고 jalr로 분기하는 방식이다.
   */
  addi t4, zero, 8
  bgeu t1, t4, irq_complete
  slli t4, t1, 2
  la   t5, irq_vector_table
  add  t5, t5, t4
  lw   t5, 0(t5)
  addi zero, zero, 0
  addi zero, zero, 0
  jalr zero, t5, 0

  .align 2
irq_vector_table:
  .word irq_unused      /* ID 0: claim 없음 */
  .word irq_unused      /* ID 1: UART_TX, 현재 demo 미사용 */
  .word irq_unused      /* ID 2: UART_RX, 현재 demo 미사용 */
  .word irq_unused      /* ID 3: SPI_TX, 현재 demo 미사용 */
  .word irq_unused      /* ID 4: SPI_RX, 현재 demo 미사용 */
  .word irq_unused      /* ID 5: 예약/미사용 */
  .word irq_dma_done    /* ID 6: DMA_DONE */
  .word irq_dma_error   /* ID 7: DMA_ERROR */

irq_unused:
  /* 현재 demo에서 쓰지 않는 interrupt는 complete만 하고 복귀한다. */
  jal  zero, irq_complete

irq_dma_done:
  /*
   * DMA가 정상 완료된 경우.
   * main loop가 polling하던 SRAM FLAG_DONE을 1로 세우고,
   * DMA 내부 done sticky bit를 clear한다.
   */
  addi t5, zero, 1
  sw   t5, FLAG_DONE(t2)
  lui  t6, 0x40060
  addi t5, zero, 2
  sw   t5, DMA_CLEAR(t6)
  jal  zero, irq_complete

irq_dma_error:
  /*
   * DMA 오류가 난 경우.
   * main loop가 즉시 error path로 빠질 수 있게 FLAG_ERROR를 1로 세우고,
   * DMA 내부 error sticky bit를 clear한다.
   */
  addi t5, zero, 1
  sw   t5, FLAG_ERROR(t2)
  lui  t6, 0x40060
  addi t5, zero, 4
  sw   t5, DMA_CLEAR(t6)
  jal  zero, irq_complete

irq_complete:
  /*
   * PLIC complete write.
   * 현재 PLIC 구현은 claim read에서 pending을 지우지 않고,
   * complete write에서 해당 source를 정리한다.
   * 이렇게 해야 AXI/APB read 타이밍에서 claim ID가 사라지는 문제를 피할 수 있다.
   */
  lui  t0, 0x400F0
  sw   t1, PLIC_COMPLETE(t0)
  jal  zero, trap_exit

trap_unhandled:
  /* 예상하지 않은 exception/trap이면 LED에 error pattern을 띄우고 멈춘다. */
  lui  t0, 0x40010
  lui  t1, 0xD
  sw   t1, GPIO_OUT(t0)
  jal  zero, trap_unhandled

trap_exit:
  /* 저장했던 레지스터를 복구하고 mret으로 main loop의 중단 지점으로 돌아간다. */
  lw   ra, 0(sp)
  lw   t0, 4(sp)
  lw   t1, 8(sp)
  lw   t2, 12(sp)
  lw   t3, 16(sp)
  lw   t4, 20(sp)
  lw   t5, 24(sp)
  lw   t6, 28(sp)
  lw   a0, 32(sp)
  lw   a1, 36(sp)
  lw   a2, 40(sp)
  lw   a3, 44(sp)
  addi sp, sp, 64
  mret

  .section .text.startup, "ax"
  .align 2

reset_main:
  /*
   * s0~s5는 main loop 전체에서 계속 쓰는 MMIO/SRAM base register다.
   * interrupt handler에서는 이 레지스터들을 건드리지 않는다.
   */
  lui  sp, 0x20004
  lui  s0, 0x40010
  lui  s1, 0x40030
  lui  s2, 0x40050
  lui  s3, 0x40060
  lui  s4, 0x400F0
  lui  s5, 0x20000

  addi t0, zero, -1
  sw   t0, GPIO_DIR(s0)

  /* LED 초기 상태. 하위 16비트만 보드 LED에 나타난다. */
  lui  t0, 0x1
  addi t0, t0, 1
  sw   t0, GPIO_OUT(s0)

  /* SRAM software flag 초기화. */
  sw   zero, FLAG_DONE(s5)
  sw   zero, FLAG_ERROR(s5)
  sw   zero, LAST_IRQ_SOURCE(s5)
  sw   zero, IRQ_COUNT(s5)

  /*
   * UART 설정.
   * CTRL=16은 RX DMA stream enable 용도로 사용한다.
   * PC -> master UART RX byte가 DMA stream 입력으로 흐르게 한다.
   */
  sw   zero, UART_CTRL(s2)
  addi t0, zero, UART_DIV_115200
  sw   t0, UART_BAUDDIV(s2)
  addi t0, zero, 30
  sw   t0, UART_STATUS(s2)
  addi t0, zero, 16
  sw   t0, UART_CTRL(s2)

  /*
   * SPI 설정.
   * CTRL=32은 TX DMA stream enable 용도로 사용한다.
   * DMA TX stream byte가 SPI TX FIFO로 들어가 slave FPGA로 전송된다.
   */
  sw   zero, SPI_CTRL(s1)
  addi t0, zero, SPI_SAFE_DIV
  sw   t0, SPI_CLKDIV(s1)
  addi t0, zero, 14
  sw   t0, SPI_STATUS(s1)
  addi t0, zero, 32
  sw   t0, SPI_CTRL(s1)

  /*
   * PLIC 설정.
   * DMA_DONE(ID 6)과 DMA_ERROR(ID 7)만 enable한다.
   * priority는 1, threshold는 0이라 둘 다 claim 가능하다.
   */
  addi t0, zero, 1
  sw   t0, PLIC_PRIO_DMA_DONE(s4)
  sw   t0, PLIC_PRIO_DMA_ERROR(s4)
  sw   zero, PLIC_THRESHOLD(s4)
  addi t0, zero, PLIC_DMA_MASK
  sw   t0, PLIC_ENABLE(s4)

  /*
   * RISC-V machine interrupt 설정.
   * mtvec = 0x80: 모든 trap은 trap_entry로 진입
   * mie.MEIE = 1: machine external interrupt 허용
   * mstatus.MIE = 1: global machine interrupt 허용
   */
  addi t0, zero, 0x80
  csrw mtvec, t0
  lui  t0, 0x1
  addi t0, t0, -2048
  csrw mie, t0
  addi t0, zero, 8
  csrs mstatus, t0

main_loop:
  /*
   * 1단계: PC UART -> master UART RX -> DMA 내부 buffer.
   * FLAG는 handler가 세우므로 transfer 시작 전에 반드시 0으로 비운다.
   */
  sw   zero, FLAG_DONE(s5)
  sw   zero, FLAG_ERROR(s5)
  addi t0, zero, 6
  sw   t0, DMA_CLEAR(s3)
  sw   zero, DMA_BUF_ADDR(s3)
  li   t0, IMAGE_BYTES
  sw   t0, DMA_LEN_BYTES(s3)

  lui  t1, 0x21
  sw   t1, GPIO_OUT(s0)

  addi t0, zero, 3
  sw   t0, DMA_CTRL(s3)

wait_rx_irq:
  /*
   * RX DMA 완료 대기.
   * CPU가 DMA status register를 직접 polling하지 않고,
   * interrupt handler가 SRAM에 써준 FLAG_DONE/FLAG_ERROR만 본다.
   *
   * 이 wait loop는 함수 호출(jal ra)을 쓰지 않고 inline으로 둔다.
   * wait 함수 안에서 interrupt가 걸리면 현재 core의 ra/trap 복귀 타이밍이 꼬일 수 있어서,
   * 안정성을 위해 return address에 의존하지 않는 구조로 만들었다.
   */
  lw   t0, FLAG_ERROR(s5)
  addi zero, zero, 0
  addi zero, zero, 0
  bne  t0, zero, wait_rx_irq_done
  lw   t0, FLAG_DONE(s5)
  addi zero, zero, 0
  addi zero, zero, 0
  beq  t0, zero, wait_rx_irq

wait_rx_irq_done:

  lw   t0, FLAG_ERROR(s5)
  addi zero, zero, 0
  addi zero, zero, 0
  bne  t0, zero, dma_error

  /* RX가 끝났으므로 다음 단계로 넘어간다는 LED 표시. */
  lui  t1, 0x23
  sw   t1, GPIO_OUT(s0)

  /*
   * 2단계: DMA 내부 buffer -> SPI TX stream.
   * 같은 buffer address 0에서 IMAGE_BYTES만큼 다시 읽어 SPI로 보낸다.
   */
  sw   zero, FLAG_DONE(s5)
  sw   zero, FLAG_ERROR(s5)
  addi t0, zero, 6
  sw   t0, DMA_CLEAR(s3)
  sw   zero, DMA_BUF_ADDR(s3)
  li   t0, IMAGE_BYTES
  sw   t0, DMA_LEN_BYTES(s3)

  lui  t1, 0x31
  sw   t1, GPIO_OUT(s0)

  addi t0, zero, 7
  sw   t0, DMA_CTRL(s3)

wait_tx_irq:
  /* TX DMA도 interrupt handler가 세우는 SRAM flag만 보고 완료를 판단한다. */
  lw   t0, FLAG_ERROR(s5)
  addi zero, zero, 0
  addi zero, zero, 0
  bne  t0, zero, wait_tx_irq_done
  lw   t0, FLAG_DONE(s5)
  addi zero, zero, 0
  addi zero, zero, 0
  beq  t0, zero, wait_tx_irq

wait_tx_irq_done:

  lw   t0, FLAG_ERROR(s5)
  addi zero, zero, 0
  addi zero, zero, 0
  bne  t0, zero, dma_error

  /* 한 frame 왕복 처리가 끝났다. 다음 frame 수신을 위해 main_loop로 돌아간다. */
  lui  t0, 0x53
  addi t0, t0, 13
  sw   t0, GPIO_OUT(s0)
  jal  zero, main_loop

dma_error:
  /* DMA error가 발생하면 LED error pattern을 띄우고 멈춘다. */
  lui  t0, 0xE
  addi t0, t0, 6
  sw   t0, GPIO_OUT(s0)
  jal  zero, dma_error
