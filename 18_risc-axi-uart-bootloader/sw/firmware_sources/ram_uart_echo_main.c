#include <stdint.h>

#define GPIOA_BASE       0x40010000u
#define GPIO_OUT         0x00u
#define GPIO_DIR         0x08u

#define UART_BASE        0x40050000u
#define UART_CTRL        0x00u
#define UART_STATUS      0x04u
#define UART_BAUDDIV     0x08u
#define UART_TXDATA      0x0Cu
#define UART_RXDATA      0x10u

#define SRAM_BASE        0x20000000u

#define UART_STATUS_TX_FULL  (1u << 5)
#define UART_STATUS_RX_VALID (1u << 2)
#define UART_DIV_115200      26u

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

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

int main(void)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;
  uint32_t count = 0u;

  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;
  MMIO32(GPIOA_BASE + GPIO_OUT) = 0x000000E1u;

  MMIO32(UART_BASE + UART_CTRL) = 0u;
  MMIO32(UART_BASE + UART_BAUDDIV) = UART_DIV_115200;
  MMIO32(UART_BASE + UART_STATUS) = 0x0000001Eu;

  sram[0] = 0xEC000001u;
  sram[1] = 0u;
  sram[2] = 0u;
  sram[3] = 0u;

  while (1) {
    uint8_t value = uart_getc();

    uart_putc(value);
    count++;

    sram[0] = 0xEC000000u | (count & 0xFFFFu);
    sram[1] = value;
    sram[2] = count;
    MMIO32(GPIOA_BASE + GPIO_OUT) = 0x000000E0u | (value & 0x0Fu);
  }

  return 0;
}
