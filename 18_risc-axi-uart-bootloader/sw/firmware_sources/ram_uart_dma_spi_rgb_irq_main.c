#include <stdint.h>

#define GPIOA_BASE          0x40010000u
#define SPI_BASE            0x40030000u
#define UART_BASE           0x40050000u
#define DMA_BASE            0x40060000u
#define PLIC_BASE           0x400F0000u
#define SRAM_BASE           0x20000000u

#define GPIO_OUT            0x00u
#define GPIO_DIR            0x08u

#define SPI_CTRL            0x00u
#define SPI_STATUS          0x04u
#define SPI_CLKDIV          0x08u

#define UART_CTRL           0x00u
#define UART_STATUS         0x04u
#define UART_BAUDDIV        0x08u

#define DMA_CTRL            0x00u
#define DMA_STATUS          0x04u
#define DMA_LEN_BYTES       0x08u
#define DMA_CLEAR           0x10u
#define DMA_BUF_ADDR        0x14u

#define PLIC_ENABLE         0x00u
#define PLIC_PENDING        0x04u
#define PLIC_ENABLED_PENDING 0x08u
#define PLIC_CLAIM          0x0Cu
#define PLIC_COMPLETE       0x10u
#define PLIC_THRESHOLD      0x14u
#define PLIC_PRIO_BASE      0x20u

#define IRQ_ID_UART_TX      1u
#define IRQ_ID_UART_RX      2u
#define IRQ_ID_SPI_TX       3u
#define IRQ_ID_SPI_RX       4u
#define IRQ_ID_UNUSED5      5u
#define IRQ_ID_DMA_DONE     6u
#define IRQ_ID_DMA_ERROR    7u
#define IRQ_ID_LIMIT        8u

#define IRQ_BIT(id)         (1u << ((id) - 1u))
#define PLIC_ENABLE_DMA     (IRQ_BIT(IRQ_ID_DMA_DONE) | IRQ_BIT(IRQ_ID_DMA_ERROR))

#define UART_CTRL_RX_IRQ_EN (1u << 2)
#define UART_CTRL_TX_DMA_EN (1u << 3)
#define UART_CTRL_RX_DMA_EN (1u << 4)

#define SPI_CTRL_TX_IRQ_EN  (1u << 3)
#define SPI_CTRL_RX_IRQ_EN  (1u << 4)
#define SPI_CTRL_TX_DMA_EN  (1u << 5)
#define SPI_CTRL_RX_DMA_EN  (1u << 6)

#define DMA_CTRL_START      (1u << 0)
#define DMA_CTRL_IRQ_EN     (1u << 1)
#define DMA_CTRL_DIR_TX     (1u << 2)
#define DMA_CLEAR_DONE      (1u << 1)
#define DMA_CLEAR_ERROR     (1u << 2)
#define DMA_CLEAR_ALL       (DMA_CLEAR_DONE | DMA_CLEAR_ERROR)

#define DMA_STATUS_DONE     (1u << 1)
#define DMA_STATUS_ERROR    (1u << 2)

#define MCAUSE_IRQ_BIT      0x80000000u
#define MCAUSE_CAUSE_MASK   0x0000000Fu
#define MCAUSE_MACHINE_EXT  11u
#define MIE_MEIE            (1u << 11)
#define MSTATUS_MIE         (1u << 3)

#define UART_DIV_115200     26u
#define SPI_SAFE_DIV        99u

#ifndef IMAGE_BYTES_VALUE
#define IMAGE_BYTES_VALUE   12288u
#endif

#define IMAGE_BYTES         IMAGE_BYTES_VALUE

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))
#define ALWAYS_INLINE __attribute__((always_inline)) inline

volatile uint32_t gDmaDone;
volatile uint32_t gDmaError;
volatile uint32_t gLastIrqId;
volatile uint32_t gLastMcause;
volatile uint32_t gIrqCount[IRQ_ID_LIMIT];
volatile uint32_t gFrameCount;

static inline uint32_t csr_read_mcause(void)
{
  uint32_t value;
  __asm__ volatile ("csrr %0, mcause" : "=r"(value));
  return value;
}

static inline void csr_set_mie(uint32_t mask)
{
  __asm__ volatile ("csrs mie, %0" :: "r"(mask) : "memory");
}

static inline void csr_set_mstatus(uint32_t mask)
{
  __asm__ volatile ("csrs mstatus, %0" :: "r"(mask) : "memory");
}

static ALWAYS_INLINE void gpio_set(uint32_t value)
{
  MMIO32(GPIOA_BASE + GPIO_OUT) = value;
}

static ALWAYS_INLINE void debug_words(uint32_t w0, uint32_t w1, uint32_t w2, uint32_t w3)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;

  sram[0] = w0;
  sram[1] = w1;
  sram[2] = w2;
  sram[3] = w3;
}

static ALWAYS_INLINE void mark_state(uint32_t state, uint32_t detail)
{
  debug_words(state, detail, gLastIrqId, gIrqCount[IRQ_ID_DMA_DONE]);
  gpio_set(state & 0x0000FFFFu);
}

void irq_trap_handler(void)
{
  const uint32_t mcause = csr_read_mcause();
  uint32_t claim_id;

  gLastMcause = mcause;

  if (((mcause & MCAUSE_IRQ_BIT) == 0u) ||
      ((mcause & MCAUSE_CAUSE_MASK) != MCAUSE_MACHINE_EXT)) {
    mark_state(0x0000E700u, mcause);
    return;
  }

  claim_id = MMIO32(PLIC_BASE + PLIC_CLAIM);
  gLastIrqId = claim_id;

  if (claim_id < IRQ_ID_LIMIT) {
    gIrqCount[claim_id]++;

    switch (claim_id) {
      case IRQ_ID_UART_TX:
        gpio_set(0x0000A001u);
        MMIO32(UART_BASE + UART_STATUS) = (1u << 1);
        break;

      case IRQ_ID_UART_RX:
        gpio_set(0x0000A002u);
        MMIO32(UART_BASE + UART_STATUS) = (1u << 2);
        break;

      case IRQ_ID_SPI_TX:
        gpio_set(0x0000A003u);
        MMIO32(SPI_BASE + SPI_STATUS) = (1u << 1);
        break;

      case IRQ_ID_SPI_RX:
        gpio_set(0x0000A004u);
        MMIO32(SPI_BASE + SPI_STATUS) = (1u << 2);
        break;

      case IRQ_ID_DMA_DONE:
        gDmaDone = 1u;
        gpio_set(0x0000A006u);
        MMIO32(DMA_BASE + DMA_CLEAR) = DMA_CLEAR_DONE;
        gpio_set(0x0000A016u);
        break;

      case IRQ_ID_DMA_ERROR:
        gDmaError = 1u;
        gpio_set(0x0000A007u);
        MMIO32(DMA_BASE + DMA_CLEAR) = DMA_CLEAR_ERROR;
        gpio_set(0x0000A017u);
        break;

      default:
        break;
    }
  }
  else {
    mark_state(0x0000E701u, claim_id);
  }

  if ((claim_id != 0u) && (claim_id <= IRQ_ID_UNUSED5 + 2u)) {
    gpio_set(0x0000A0C0u | claim_id);
    MMIO32(PLIC_BASE + PLIC_COMPLETE) = claim_id;
    gpio_set(0x0000A0D0u | claim_id);
  }
}

static ALWAYS_INLINE void plic_set_priority(uint32_t claim_id, uint32_t priority)
{
  if ((claim_id != 0u) && (claim_id < IRQ_ID_LIMIT)) {
    MMIO32(PLIC_BASE + PLIC_PRIO_BASE + ((claim_id - 1u) * 4u)) = priority;
  }
}

static ALWAYS_INLINE void plic_init(uint32_t enable_mask)
{
  MMIO32(PLIC_BASE + PLIC_ENABLE) = 0u;
  MMIO32(PLIC_BASE + PLIC_THRESHOLD) = 0u;

  plic_set_priority(IRQ_ID_UART_TX, 1u);
  plic_set_priority(IRQ_ID_UART_RX, 1u);
  plic_set_priority(IRQ_ID_SPI_TX, 1u);
  plic_set_priority(IRQ_ID_SPI_RX, 1u);
  plic_set_priority(IRQ_ID_DMA_DONE, 2u);
  plic_set_priority(IRQ_ID_DMA_ERROR, 3u);

  MMIO32(PLIC_BASE + PLIC_ENABLE) = enable_mask;

  csr_set_mie(MIE_MEIE);
  csr_set_mstatus(MSTATUS_MIE);
}

static ALWAYS_INLINE void dma_setup(uint32_t length)
{
  gDmaDone = 0u;
  gDmaError = 0u;
  MMIO32(DMA_BASE + DMA_CLEAR) = DMA_CLEAR_ALL;
  MMIO32(DMA_BASE + DMA_BUF_ADDR) = 0u;
  MMIO32(DMA_BASE + DMA_LEN_BYTES) = length;
}

static ALWAYS_INLINE int wait_dma_irq(void)
{
  while ((gDmaDone == 0u) && (gDmaError == 0u)) {
    uint32_t dma_status = MMIO32(DMA_BASE + DMA_STATUS);
    uint32_t plic_pending = MMIO32(PLIC_BASE + PLIC_PENDING);
    uint32_t plic_enabled_pending = MMIO32(PLIC_BASE + PLIC_ENABLED_PENDING);

    if ((dma_status & DMA_STATUS_ERROR) != 0u) {
      gpio_set(0x0000D0E7u);
    }
    else if ((plic_enabled_pending & IRQ_BIT(IRQ_ID_DMA_DONE)) != 0u) {
      gpio_set(0x0000D003u);
    }
    else if ((plic_pending & IRQ_BIT(IRQ_ID_DMA_DONE)) != 0u) {
      gpio_set(0x0000D002u);
    }
    else if ((dma_status & DMA_STATUS_DONE) != 0u) {
      gpio_set(0x0000D001u);
    }

    __asm__ volatile ("nop");
  }

  return (gDmaError == 0u) ? 0 : -1;
}

int main(void)
{
  gDmaDone = 0u;
  gDmaError = 0u;
  gLastIrqId = 0u;
  gLastMcause = 0u;
  gFrameCount = 0u;

  for (uint32_t i = 0u; i < IRQ_ID_LIMIT; i++) {
    gIrqCount[i] = 0u;
  }

  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;
  mark_state(0x00001080u, IMAGE_BYTES);

  gpio_set(0x00001100u);
  MMIO32(UART_BASE + UART_CTRL) = 0u;
  gpio_set(0x00001101u);
  MMIO32(UART_BASE + UART_BAUDDIV) = UART_DIV_115200;
  gpio_set(0x00001102u);
  MMIO32(UART_BASE + UART_STATUS) = 0x0000001Eu;
  gpio_set(0x00001103u);
  MMIO32(UART_BASE + UART_CTRL) = UART_CTRL_RX_DMA_EN;
  mark_state(0x00001180u, 0u);

  gpio_set(0x00001200u);
  MMIO32(SPI_BASE + SPI_CTRL) = 0u;
  gpio_set(0x00001201u);
  MMIO32(SPI_BASE + SPI_CLKDIV) = SPI_SAFE_DIV;
  gpio_set(0x00001202u);
  MMIO32(SPI_BASE + SPI_STATUS) = 0x0000000Eu;
  gpio_set(0x00001203u);
  MMIO32(SPI_BASE + SPI_CTRL) = SPI_CTRL_TX_DMA_EN;
  mark_state(0x00001280u, 0u);

  mark_state(0x00001380u, PLIC_ENABLE_DMA);
  plic_init(PLIC_ENABLE_DMA);
  mark_state(0x00001480u, PLIC_ENABLE_DMA);

  while (1) {
    dma_setup(IMAGE_BYTES);
    mark_state(0x00002180u, gFrameCount);
    MMIO32(DMA_BASE + DMA_CTRL) = DMA_CTRL_START | DMA_CTRL_IRQ_EN;

    if (wait_dma_irq() != 0) {
      mark_state(0x0000E181u, MMIO32(DMA_BASE + DMA_STATUS));
      while (1) {
      }
    }

    mark_state(0x00002380u, gIrqCount[IRQ_ID_DMA_DONE]);

    dma_setup(IMAGE_BYTES);
    mark_state(0x00003180u, gFrameCount);
    MMIO32(DMA_BASE + DMA_CTRL) = DMA_CTRL_START | DMA_CTRL_IRQ_EN | DMA_CTRL_DIR_TX;

    if (wait_dma_irq() != 0) {
      mark_state(0x0000E182u, MMIO32(DMA_BASE + DMA_STATUS));
      while (1) {
      }
    }

    gFrameCount++;
    mark_state(0x0000538Du, gFrameCount);
  }

  return 0;
}
