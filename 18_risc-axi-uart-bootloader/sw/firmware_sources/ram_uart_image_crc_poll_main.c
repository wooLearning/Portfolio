#include <stdint.h>

#include "soc_address_map.h"

#define GPIO_OUT         0x00u
#define GPIO_DIR         0x08u

#define UART_CTRL        0x00u
#define UART_STATUS      0x04u
#define UART_BAUDDIV     0x08u
#define UART_TXDATA      0x0Cu
#define UART_RXDATA      0x10u

#define UART_STATUS_RX_VALID (1u << 2)
#define UART_STATUS_TX_FULL  (1u << 5)
#define UART_DIV_115200      26u
#define IMAGE_MAGIC          0x46474D49u

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

typedef struct {
  uint16_t width;
  uint16_t height;
  uint8_t channels;
  uint32_t payload_bytes;
  uint32_t crc32;
} image_header_t;

static void mark_state(uint32_t state, uint32_t detail)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;

  sram[0] = state;
  sram[1] = detail;
  MMIO32(GPIOA_BASE + GPIO_OUT) = state & 0x0000FFFFu;
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

static uint32_t crc32_byte(uint32_t crc, uint8_t data)
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
  uint32_t magic = 0u;
  uint8_t version;

  magic |= (uint32_t)uart_getc() << 0;
  magic |= (uint32_t)uart_getc() << 8;
  magic |= (uint32_t)uart_getc() << 16;
  magic |= (uint32_t)uart_getc() << 24;
  if (magic != IMAGE_MAGIC) {
    mark_state(0x0000E301u, magic);
    while (1) {
    }
  }

  version = uart_getc();
  header->channels = uart_getc();
  header->width = uart_get_u16();
  header->height = uart_get_u16();
  header->payload_bytes = uart_get_u32();
  header->crc32 = uart_get_u32();

  if (version != 1u) {
    mark_state(0x0000E302u, version);
    while (1) {
    }
  }
}

static void validate_image_header(const image_header_t *header)
{
  uint32_t expected_bytes;

  if ((header->channels != 1u) && (header->channels != 3u)) {
    mark_state(0x0000E303u, header->channels);
    while (1) {
    }
  }

  expected_bytes = mul_u32(mul_u32((uint32_t)header->width,
                                   (uint32_t)header->height),
                           (uint32_t)header->channels);

  if ((header->payload_bytes == 0u) ||
      (header->payload_bytes != expected_bytes) ||
      (header->payload_bytes > IMAGE_SIZE)) {
    mark_state(0x0000E304u, header->payload_bytes);
    while (1) {
    }
  }
}

int main(void)
{
  uint32_t frame_count = 0u;

  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;
  MMIO32(UART_BASE + UART_CTRL) = 0u;
  MMIO32(UART_BASE + UART_BAUDDIV) = UART_DIV_115200;
  MMIO32(UART_BASE + UART_STATUS) = 0x0000001Eu;
  mark_state(0x00001201u, IMAGE_SIZE);

  while (1) {
    image_header_t header;
    uint32_t crc = 0xFFFFFFFFu;

    read_image_header(&header);
    validate_image_header(&header);
    mark_state(0x00003200u, header.payload_bytes);

    uart_putc((uint8_t)'A');
    uart_putc((uint8_t)'C');
    uart_putc((uint8_t)'K');
    uart_putc((uint8_t)'\n');

    for (uint32_t idx = 0u; idx < header.payload_bytes; idx++) {
      crc = crc32_byte(crc, uart_getc());
    }
    crc = ~crc;

    if (crc != header.crc32) {
      mark_state(0x0000E305u, crc);
      while (1) {
      }
    }

    frame_count++;
    mark_state(0x0000530Cu, frame_count);
  }

  return 0;
}
