#include <stdint.h>

#include "soc_address_map.h"

#define GPIO_OUT             0x00u
#define GPIO_DIR             0x08u

#define SPI_CTRL             0x00u
#define SPI_STATUS           0x04u
#define SPI_CLKDIV           0x08u

#define UART_CTRL            0x00u
#define UART_STATUS          0x04u
#define UART_BAUDDIV         0x08u
#define UART_TXDATA          0x0Cu
#define UART_RXDATA          0x10u

#define DMA_CTRL             0x00u
#define DMA_STATUS           0x04u
#define DMA_SRC_ADDR         0x08u
#define DMA_DST_ADDR         0x0Cu
#define DMA_LEN_BYTES        0x10u
#define DMA_COUNT_BYTES      0x14u
#define DMA_IRQ_ENABLE       0x18u
#define DMA_IRQ_STATUS       0x1Cu

#define PLIC_ENABLE          0x00u
#define PLIC_PENDING         0x04u
#define PLIC_ENABLED_PENDING 0x08u
#define PLIC_CLAIM           0x0Cu
#define PLIC_COMPLETE        0x10u
#define PLIC_THRESHOLD       0x14u
#define PLIC_PRIO_BASE       0x20u

#define IRQ_ID_UART_TX       1u
#define IRQ_ID_UART_RX       2u
#define IRQ_ID_SPI_TX        3u
#define IRQ_ID_SPI_RX        4u
#define IRQ_ID_UNUSED5       5u
#define IRQ_ID_DMA_DONE      6u
#define IRQ_ID_DMA_ERROR     7u
#define IRQ_ID_LIMIT         8u

#define IRQ_BIT(id)          (1u << ((id) - 1u))
#define PLIC_ENABLE_DMA      (IRQ_BIT(IRQ_ID_DMA_DONE) | IRQ_BIT(IRQ_ID_DMA_ERROR))

#define UART_CTRL_RX_DMA_EN  (1u << 4)
#define UART_STATUS_RX_VALID (1u << 2)
#define UART_STATUS_TX_FULL  (1u << 5)

#define SPI_CTRL_TX_DMA_EN   (1u << 5)

#define DMA_CTRL_START       (1u << 0)
#define DMA_CTRL_DIR_MM2S    (1u << 1)
#define DMA_IRQ_DONE         (1u << 0)
#define DMA_IRQ_ERROR        (1u << 1)
#define DMA_CLEAR_ALL        (DMA_IRQ_DONE | DMA_IRQ_ERROR)
#define DMA_STATUS_DONE      (1u << 1)
#define DMA_STATUS_ERROR     (1u << 2)

#define MCAUSE_IRQ_BIT       0x80000000u
#define MCAUSE_CAUSE_MASK    0x0000000Fu
#define MCAUSE_MACHINE_EXT   11u
#define MIE_MEIE             (1u << 11)
#define MSTATUS_MIE          (1u << 3)

#define UART_DIV_115200      26u
#define SPI_SAFE_DIV         99u
#define IMAGE_MAGIC          0x46474D49u

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))
#define ALWAYS_INLINE __attribute__((always_inline)) inline

typedef struct {
  uint16_t width;
  uint16_t height;
  uint8_t channels;
  uint32_t payload_bytes;
  uint32_t crc32;
} image_header_t;

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

    if (claim_id == IRQ_ID_DMA_DONE) {
      gDmaDone = 1u;
      MMIO32(DMA_BASE + DMA_IRQ_STATUS) = DMA_IRQ_DONE;
    }
    else if (claim_id == IRQ_ID_DMA_ERROR) {
      gDmaError = 1u;
      MMIO32(DMA_BASE + DMA_IRQ_STATUS) = DMA_IRQ_ERROR;
    }
  }
  else {
    mark_state(0x0000E701u, claim_id);
  }

  if ((claim_id != 0u) && (claim_id < IRQ_ID_LIMIT)) {
    MMIO32(PLIC_BASE + PLIC_COMPLETE) = claim_id;
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

  plic_set_priority(IRQ_ID_DMA_DONE, 2u);
  plic_set_priority(IRQ_ID_DMA_ERROR, 3u);

  MMIO32(PLIC_BASE + PLIC_ENABLE) = enable_mask;
  csr_set_mie(MIE_MEIE);
  csr_set_mstatus(MSTATUS_MIE);
}

static uint8_t uart_getc(void)
{
  while ((MMIO32(UART_BASE + UART_STATUS) & UART_STATUS_RX_VALID) == 0u) {
  }

  return (uint8_t)MMIO32(UART_BASE + UART_RXDATA);
}

static void uart_putc(uint8_t value)
{
  while ((MMIO32(UART_BASE + UART_STATUS) & UART_STATUS_TX_FULL) != 0u) {
  }

  MMIO32(UART_BASE + UART_TXDATA) = value;
}

static uint16_t uart_get_u16(void)
{
  uint16_t value = 0u;

  value |= (uint16_t)uart_getc() << 0;
  value |= (uint16_t)uart_getc() << 8;

  return value;
}

static uint32_t uart_get_u32(void)
{
  uint32_t value = 0u;

  value |= (uint32_t)uart_getc() << 0;
  value |= (uint32_t)uart_getc() << 8;
  value |= (uint32_t)uart_getc() << 16;
  value |= (uint32_t)uart_getc() << 24;

  return value;
}

static void wait_for_image_magic(void)
{
  uint32_t matched = 0u;

  while (matched < 4u) {
    const uint8_t value = uart_getc();

    if (matched == 0u) {
      matched = (value == (uint8_t)'I') ? 1u : 0u;
    }
    else if (matched == 1u) {
      matched = (value == (uint8_t)'M') ? 2u :
                (value == (uint8_t)'I') ? 1u : 0u;
    }
    else if (matched == 2u) {
      matched = (value == (uint8_t)'G') ? 3u :
                (value == (uint8_t)'I') ? 1u : 0u;
    }
    else {
      matched = (value == (uint8_t)'F') ? 4u :
                (value == (uint8_t)'I') ? 1u : 0u;
    }
  }
}

static uint32_t image_crc32_byte(uint32_t crc, uint8_t data)
{
  crc ^= data;

  for (uint32_t bit = 0u; bit < 8u; bit++) {
    if ((crc & 1u) != 0u) {
      crc = (crc >> 1) ^ 0xEDB88320u;
    }
    else {
      crc >>= 1;
    }
  }

  return crc;
}

static uint32_t image_crc32(const volatile uint8_t *data, uint32_t length)
{
  uint32_t crc = 0xFFFFFFFFu;

  for (uint32_t idx = 0u; idx < length; idx++) {
    crc = image_crc32_byte(crc, data[idx]);
  }

  return ~crc;
}

static void store_u16(volatile uint8_t *data, uint32_t offset, uint16_t value)
{
  data[offset + 0u] = (uint8_t)(value >> 0);
  data[offset + 1u] = (uint8_t)(value >> 8);
}

static void store_u32(volatile uint8_t *data, uint32_t offset, uint32_t value)
{
  data[offset + 0u] = (uint8_t)(value >> 0);
  data[offset + 1u] = (uint8_t)(value >> 8);
  data[offset + 2u] = (uint8_t)(value >> 16);
  data[offset + 3u] = (uint8_t)(value >> 24);
}

static uint32_t mul_u32(uint32_t lhs, uint32_t rhs)
{
  uint32_t result = 0u;

  while (rhs != 0u) {
    if ((rhs & 1u) != 0u) {
      result += lhs;
    }

    lhs <<= 1;
    rhs >>= 1;
  }

  return result;
}

static void read_image_header(image_header_t *header)
{
  uint8_t version;

  wait_for_image_magic();
  version = uart_getc();
  header->channels = uart_getc();
  header->width = uart_get_u16();
  header->height = uart_get_u16();
  header->payload_bytes = uart_get_u32();
  header->crc32 = uart_get_u32();

  if (version != 1u) {
    mark_state(0x0000E282u, version);
    while (1) {
    }
  }
}

static void validate_image_header(const image_header_t *header)
{
  uint32_t expected_bytes;

  if ((header->channels != 1u) && (header->channels != 3u)) {
    mark_state(0x0000E283u, header->channels);
    while (1) {
    }
  }

  expected_bytes = mul_u32(mul_u32((uint32_t)header->width,
                                   (uint32_t)header->height),
                           (uint32_t)header->channels);

  if ((header->payload_bytes == 0u) ||
      (header->payload_bytes != expected_bytes) ||
      (header->payload_bytes > IMAGE_SIZE) ||
      ((IMAGE_PAYLOAD_BASE + header->payload_bytes) > SRAM_END)) {
    mark_state(0x0000E284u, header->payload_bytes);
    while (1) {
    }
  }
}

static void build_spi_header(const image_header_t *header, uint32_t payload_crc)
{
  volatile uint8_t * const frame = (volatile uint8_t *)(uintptr_t)IMAGE_BASE;

  frame[0] = (uint8_t)'I';
  frame[1] = (uint8_t)'M';
  frame[2] = (uint8_t)'G';
  frame[3] = (uint8_t)'F';
  frame[4] = 1u;
  frame[5] = header->channels;
  store_u16(frame, 6u, header->width);
  store_u16(frame, 8u, header->height);
  store_u32(frame, 10u, header->payload_bytes);
  store_u32(frame, 14u, payload_crc);
}

static ALWAYS_INLINE void dma_setup_s2mm(uint32_t dst_addr, uint32_t length)
{
  gDmaDone = 0u;
  gDmaError = 0u;
  MMIO32(DMA_BASE + DMA_IRQ_STATUS) = DMA_CLEAR_ALL;
  MMIO32(DMA_BASE + DMA_IRQ_ENABLE) = DMA_CLEAR_ALL;
  MMIO32(DMA_BASE + DMA_DST_ADDR) = dst_addr;
  MMIO32(DMA_BASE + DMA_LEN_BYTES) = length;
}

static ALWAYS_INLINE void dma_setup_mm2s(uint32_t src_addr, uint32_t length)
{
  gDmaDone = 0u;
  gDmaError = 0u;
  MMIO32(DMA_BASE + DMA_IRQ_STATUS) = DMA_CLEAR_ALL;
  MMIO32(DMA_BASE + DMA_IRQ_ENABLE) = DMA_CLEAR_ALL;
  MMIO32(DMA_BASE + DMA_SRC_ADDR) = src_addr;
  MMIO32(DMA_BASE + DMA_LEN_BYTES) = length;
}

static void invert_image(uint32_t length)
{
  volatile uint8_t * const image = (volatile uint8_t *)(uintptr_t)IMAGE_PAYLOAD_BASE;

  for (uint32_t idx = 0u; idx < length; idx++) {
    image[idx] = (uint8_t)(0xFFu - image[idx]);
  }
}

static ALWAYS_INLINE int wait_dma_irq(void)
{
  while ((gDmaDone == 0u) && (gDmaError == 0u)) {
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
  mark_state(0x0000108Du, IMAGE_SIZE);

  MMIO32(UART_BASE + UART_CTRL) = 0u;
  MMIO32(UART_BASE + UART_BAUDDIV) = UART_DIV_115200;
  MMIO32(UART_BASE + UART_STATUS) = 0x0000001Eu;
  MMIO32(UART_BASE + UART_CTRL) = 0u;

  MMIO32(SPI_BASE + SPI_CTRL) = 0u;
  MMIO32(SPI_BASE + SPI_CLKDIV) = SPI_SAFE_DIV;
  MMIO32(SPI_BASE + SPI_STATUS) = 0x0000000Eu;
  MMIO32(SPI_BASE + SPI_CTRL) = SPI_CTRL_TX_DMA_EN;

  plic_init(PLIC_ENABLE_DMA);
  mark_state(0x0000148Du, PLIC_ENABLE_DMA);

  while (1) {
    image_header_t header;
    uint32_t actual_crc;

    read_image_header(&header);
    validate_image_header(&header);
    mark_state(0x0000218Du, gFrameCount);

    dma_setup_s2mm(IMAGE_PAYLOAD_BASE, header.payload_bytes);
    MMIO32(UART_BASE + UART_CTRL) = UART_CTRL_RX_DMA_EN;
    MMIO32(DMA_BASE + DMA_CTRL) = DMA_CTRL_START;

    uart_putc((uint8_t)'A');
    uart_putc((uint8_t)'C');
    uart_putc((uint8_t)'K');
    uart_putc((uint8_t)'\n');

    if (wait_dma_irq() != 0) {
      mark_state(0x0000E181u, MMIO32(DMA_BASE + DMA_STATUS));
      while (1) {
      }
    }

    MMIO32(UART_BASE + UART_CTRL) = 0u;
    mark_state(0x0000238Du, gIrqCount[IRQ_ID_DMA_DONE]);

    actual_crc = image_crc32((volatile uint8_t *)(uintptr_t)IMAGE_PAYLOAD_BASE,
                             header.payload_bytes);
    if (actual_crc != header.crc32) {
      mark_state(0x0000E285u, actual_crc);
      while (1) {
      }
    }

    invert_image(header.payload_bytes);
    actual_crc = image_crc32((volatile uint8_t *)(uintptr_t)IMAGE_PAYLOAD_BASE,
                             header.payload_bytes);
    build_spi_header(&header, actual_crc);

    dma_setup_mm2s(IMAGE_BASE, IMAGE_HEADER_SIZE + header.payload_bytes);
    mark_state(0x0000318Du, gFrameCount);
    MMIO32(DMA_BASE + DMA_CTRL) = DMA_CTRL_START | DMA_CTRL_DIR_MM2S;

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
