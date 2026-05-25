#include <stdint.h>

#include "soc_address_map.h"

#define GPIO_OUT         0x00u
#define GPIO_DIR         0x08u

#define SPI_CTRL         0x00u
#define SPI_STATUS       0x04u
#define SPI_CLKDIV       0x08u

#define UART_CTRL        0x00u
#define UART_STATUS      0x04u
#define UART_BAUDDIV     0x08u
#define UART_TXDATA      0x0Cu
#define UART_RXDATA      0x10u

#define DMA_CTRL         0x00u
#define DMA_STATUS       0x04u
#define DMA_SRC_ADDR     0x08u
#define DMA_DST_ADDR     0x0Cu
#define DMA_LEN_BYTES    0x10u
#define DMA_COUNT_BYTES  0x14u
#define DMA_IRQ_ENABLE   0x18u
#define DMA_IRQ_STATUS   0x1Cu

#define DMA_STATUS_BUSY      (1u << 0)
#define DMA_STATUS_DONE      (1u << 1)
#define DMA_STATUS_ERROR     (1u << 2)
#define DMA_IRQ_DONE         (1u << 0)
#define DMA_IRQ_ERROR        (1u << 1)
#define DMA_CLEAR_DONE_ERROR (DMA_IRQ_DONE | DMA_IRQ_ERROR)

#define UART_CTRL_RX_DMA_EN  (1u << 4)
#define UART_STATUS_RX_VALID (1u << 2)
#define UART_STATUS_TX_FULL  (1u << 5)

#define SPI_CTRL_TX_DMA_EN   (1u << 5)

#define DMA_CTRL_START       (1u << 0)
#define DMA_CTRL_DIR_MM2S    (1u << 1)

#define UART_DIV_115200      26u
#define SPI_SAFE_DIV         99u
#define IMAGE_MAGIC          0x46474D49u

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

typedef struct {
  uint16_t width;
  uint16_t height;
  uint8_t channels;
  uint32_t payload_bytes;
  uint32_t crc32;
} image_header_t;

/* Drive the low 16 LED bits through GPIOA. */
static void gpio_set(uint32_t value)
{
  MMIO32(GPIOA_BASE + GPIO_OUT) = value;
}

/* Leave a breadcrumb in SRAM[0:1] and mirror the state on LEDs. */
static void mark_state(uint32_t state, uint32_t detail)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;

  sram[0] = state;
  sram[1] = detail;
  gpio_set(state & 0x0000FFFFu);
}

/* Blocking UART byte receive through the APB RXDATA register. */
static uint8_t uart_getc(void)
{
  while ((MMIO32(UART_BASE + UART_STATUS) & UART_STATUS_RX_VALID) == 0u) {
  }

  return (uint8_t)MMIO32(UART_BASE + UART_RXDATA);
}

/* Blocking UART byte transmit through the APB TXDATA register. */
static void uart_putc(uint8_t value)
{
  while ((MMIO32(UART_BASE + UART_STATUS) & UART_STATUS_TX_FULL) != 0u) {
  }

  MMIO32(UART_BASE + UART_TXDATA) = value;
}

/* Read one little-endian 16-bit field from the PC image header. */
static uint16_t uart_get_u16(void)
{
  uint16_t value = 0u;

  value |= (uint16_t)uart_getc() << 0;
  value |= (uint16_t)uart_getc() << 8;

  return value;
}

/* Read one little-endian 32-bit field from the PC image header. */
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

/* CRC32 update for one byte, using the same polynomial as the PC sender. */
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

/* Compute CRC32 over the image payload that DMA placed in SRAM. */
static uint32_t image_crc32(const volatile uint8_t *data, uint32_t length)
{
  uint32_t crc = 0xFFFFFFFFu;

  for (uint32_t idx = 0u; idx < length; idx++) {
    crc = image_crc32_byte(crc, data[idx]);
  }

  return ~crc;
}

/* Write a little-endian 16-bit field into the outbound IMGF header. */
static void store_u16(volatile uint8_t *data, uint32_t offset, uint16_t value)
{
  data[offset + 0u] = (uint8_t)(value >> 0);
  data[offset + 1u] = (uint8_t)(value >> 8);
}

/* Write a little-endian 32-bit field into the outbound IMGF header. */
static void store_u32(volatile uint8_t *data, uint32_t offset, uint32_t value)
{
  data[offset + 0u] = (uint8_t)(value >> 0);
  data[offset + 1u] = (uint8_t)(value >> 8);
  data[offset + 2u] = (uint8_t)(value >> 16);
  data[offset + 3u] = (uint8_t)(value >> 24);
}

/* Small RV32I-friendly multiply helper; avoids pulling in libgcc __mulsi3. */
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

/* Read and minimally validate the fixed IMGF header before enabling DMA. */
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
    mark_state(0x0000E202u, version);
    while (1) {
    }
  }
}

/* Check that the requested variable-size payload fits the SRAM image area. */
static void validate_image_header(const image_header_t *header)
{
  uint32_t expected_bytes;

  if ((header->channels != 1u) && (header->channels != 3u)) {
    mark_state(0x0000E203u, header->channels);
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
    mark_state(0x0000E204u, header->payload_bytes);
    while (1) {
    }
  }
}

/* Clear sticky DMA done/error bits before starting a new transfer. */
static void dma_clear(void)
{
  MMIO32(DMA_BASE + DMA_IRQ_STATUS) = DMA_CLEAR_DONE_ERROR;
}

/* Start S2MM: UART RX AXI-Stream -> DMA -> SRAM image buffer. */
static void dma_start_s2mm(uint32_t dst_addr, uint32_t length)
{
  dma_clear();
  MMIO32(DMA_BASE + DMA_DST_ADDR) = dst_addr;
  MMIO32(DMA_BASE + DMA_LEN_BYTES) = length;
  MMIO32(UART_BASE + UART_CTRL) = UART_CTRL_RX_DMA_EN;
  MMIO32(DMA_BASE + DMA_CTRL) = DMA_CTRL_START;
}

/* Start MM2S: SRAM image buffer -> DMA -> SPI TX AXI-Stream. */
static void dma_start_mm2s(uint32_t src_addr, uint32_t length)
{
  dma_clear();
  MMIO32(DMA_BASE + DMA_SRC_ADDR) = src_addr;
  MMIO32(DMA_BASE + DMA_LEN_BYTES) = length;
  MMIO32(DMA_BASE + DMA_CTRL) = DMA_CTRL_START | DMA_CTRL_DIR_MM2S;
}

/* Poll DMA STATUS until DONE or ERROR. This is the non-interrupt version. */
static uint32_t wait_dma_done(void)
{
  uint32_t status;

  do {
    status = MMIO32(DMA_BASE + DMA_STATUS);
    if ((status & DMA_STATUS_ERROR) != 0u) {
      return status;
    }
  } while ((status & DMA_STATUS_DONE) == 0u);

  return status;
}

/* CPU-side image processing step: invert each received pixel byte in SRAM. */
static void invert_image(uint32_t length)
{
  volatile uint8_t * const image = (volatile uint8_t *)(uintptr_t)IMAGE_PAYLOAD_BASE;

  for (uint32_t idx = 0u; idx < length; idx++) {
    image[idx] = (uint8_t)(0xFFu - image[idx]);
  }
}

/* Build the framed SPI output: IMGF header followed by processed payload. */
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

int main(void)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;
  uint32_t frame_count = 0u;

  /* Bring up LEDs/debug GPIO and publish the configured max image size. */
  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;
  mark_state(0x00001001u, IMAGE_SIZE);

  /* SRAM[2:3] are simple debug counters visible from simulation/debug reads. */
  sram[2] = 0u;
  sram[3] = 0u;

  /* UART is shared with the bootloader. Reinitialize it for the RAM app. */
  MMIO32(UART_BASE + UART_CTRL) = 0u;
  MMIO32(UART_BASE + UART_BAUDDIV) = UART_DIV_115200;
  MMIO32(UART_BASE + UART_STATUS) = 0x0000001Eu;
  MMIO32(UART_BASE + UART_CTRL) = 0u;

  /* SPI TX is the outgoing stream sink for the DMA MM2S path. */
  MMIO32(SPI_BASE + SPI_CTRL) = 0u;
  MMIO32(SPI_BASE + SPI_CLKDIV) = SPI_SAFE_DIV;
  MMIO32(SPI_BASE + SPI_STATUS) = 0x0000000Eu;
  MMIO32(SPI_BASE + SPI_CTRL) = SPI_CTRL_TX_DMA_EN;

  while (1) {
    image_header_t header;
    uint32_t status;
    uint32_t actual_crc;

    /* 1. PC sends only the IMGF header first. CPU reads it by UART polling. */
    read_image_header(&header);
    validate_image_header(&header);
    mark_state(0x00002100u, frame_count);

    /* 2. Header is valid, so arm DMA before allowing payload bytes to arrive. */
    dma_start_s2mm(IMAGE_PAYLOAD_BASE, header.payload_bytes);

    /* 3. Tell the PC sender it may now stream the variable-size payload. */
    uart_putc((uint8_t)'A');
    uart_putc((uint8_t)'C');
    uart_putc((uint8_t)'K');
    uart_putc((uint8_t)'\n');

    /* 4. Wait until UART RX stream has been written into SRAM by DMA. */
    status = wait_dma_done();
    MMIO32(UART_BASE + UART_CTRL) = 0u;
    if ((status & DMA_STATUS_ERROR) != 0u) {
      mark_state(0x0000E101u, status);
      while (1) {
      }
    }

    mark_state(0x00002300u, status);

    /* 5. CPU verifies the payload that DMA just stored in SRAM. */
    actual_crc = image_crc32((volatile uint8_t *)(uintptr_t)IMAGE_PAYLOAD_BASE,
                             header.payload_bytes);
    if (actual_crc != header.crc32) {
      mark_state(0x0000E205u, actual_crc);
      while (1) {
      }
    }

    /* 6. CPU processes the SRAM image in place. */
    invert_image(header.payload_bytes);
    actual_crc = image_crc32((volatile uint8_t *)(uintptr_t)IMAGE_PAYLOAD_BASE,
                             header.payload_bytes);
    build_spi_header(&header, actual_crc);

    /* 7. DMA streams a framed processed image to SPI TX. */
    mark_state(0x00003100u, frame_count);
    dma_start_mm2s(IMAGE_BASE, IMAGE_HEADER_SIZE + header.payload_bytes);

    /* 8. Poll for TX-side DMA completion, then publish frame debug state. */
    status = wait_dma_done();
    if ((status & DMA_STATUS_ERROR) != 0u) {
      mark_state(0x0000E102u, status);
      while (1) {
      }
    }

    frame_count++;
    sram[2] = frame_count;
    sram[3] = status;
    mark_state(0x0000530Du, frame_count);
  }

  return 0;
}
