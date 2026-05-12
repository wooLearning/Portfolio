#include <stdint.h>

#define GPIOA_BASE       0x40010000u
#define GPIO_OUT         0x00u
#define GPIO_DIR         0x08u

#define UART_BASE        0x40050000u
#define UART_CTRL        0x00u
#define UART_STATUS      0x04u
#define UART_BAUDDIV     0x08u
#define UART_RXDATA      0x10u

#define SRAM_BASE        0x20000000u
#define SRAM_APP_BASE    0x20001000u
#define SRAM_END         0x20004000u

#define UART_STATUS_RX_VALID (1u << 2)
#define UART_DIV_115200      26u
#define LOADER_MAGIC0        0x52u
#define LOADER_MAGIC1        0x41u
#define LOADER_MAGIC2        0x58u
#define LOADER_MAGIC3        0x49u

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

typedef void (*entry_fn_t)(void);

static void gpio_set(uint32_t value)
{
  MMIO32(GPIOA_BASE + GPIO_OUT) = value;
}

static uint8_t uart_getc(void)
{
  while ((MMIO32(UART_BASE + UART_STATUS) & UART_STATUS_RX_VALID) == 0u) {
  }

  return (uint8_t)MMIO32(UART_BASE + UART_RXDATA);
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

static void loader_error(uint32_t code)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;

  sram[0] = 0xBAD00000u | code;
  gpio_set(0x0000E000u | code);

  while (1) {
  }
}

int main(void)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;

  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;
  gpio_set(0x0000B001u);

  MMIO32(UART_BASE + UART_CTRL) = 0u;
  MMIO32(UART_BASE + UART_BAUDDIV) = UART_DIV_115200;
  MMIO32(UART_BASE + UART_STATUS) = 0x0000001Eu;

  if (uart_getc() != LOADER_MAGIC0) {
    loader_error(1u);
  }
  if (uart_getc() != LOADER_MAGIC1) {
    loader_error(2u);
  }
  if (uart_getc() != LOADER_MAGIC2) {
    loader_error(3u);
  }
  if (uart_getc() != LOADER_MAGIC3) {
    loader_error(4u);
  }

  gpio_set(0x0000B002u);

  const uint32_t load_addr = uart_get_u32();
  const uint32_t byte_count = uart_get_u32();
  const uint32_t entry_addr = uart_get_u32();
  const uint32_t expected_sum = uart_get_u32();

  if ((load_addr < SRAM_APP_BASE) || (load_addr >= SRAM_END)) {
    loader_error(5u);
  }
  if ((entry_addr < load_addr) || (entry_addr >= SRAM_END)) {
    loader_error(6u);
  }
  if ((byte_count == 0u) || ((byte_count & 3u) != 0u)) {
    loader_error(7u);
  }
  if ((load_addr + byte_count) > SRAM_END) {
    loader_error(8u);
  }

  volatile uint32_t *dst = (volatile uint32_t *)(uintptr_t)load_addr;
  uint32_t actual_sum = 0u;

  for (uint32_t byte_index = 0u; byte_index < byte_count; byte_index += 4u) {
    uint32_t word = 0u;

    for (uint32_t lane = 0u; lane < 4u; lane++) {
      uint32_t byte_value = (uint32_t)uart_getc();
      actual_sum += byte_value;
      word |= byte_value << (lane * 8u);
    }

    *dst = word;
    dst++;
  }

  if (actual_sum != expected_sum) {
    loader_error(9u);
  }

  sram[0] = 0xB0070001u;
  sram[1] = load_addr;
  sram[2] = byte_count;
  sram[3] = entry_addr;
  gpio_set(0x0000B003u);

  __asm__ volatile (".word 0x0000100f" ::: "memory");

  ((entry_fn_t)(uintptr_t)entry_addr)();

  loader_error(10u);
  return 0;
}
