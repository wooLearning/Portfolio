#include <stdint.h>

#define GPIOA_BASE       0x40010000u
#define GPIO_OUT         0x00u
#define GPIO_DIR         0x08u

#define UART_BASE        0x40050000u
#define UART_CTRL        0x00u
#define UART_STATUS      0x04u
#define UART_BAUDDIV     0x08u
#define UART_TXDATA      0x0Cu

#define SRAM_BASE        0x20000000u

#define UART_STATUS_TX_FULL  (1u << 5)
#define UART_DIV_115200      26u

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

static void delay(volatile uint32_t count)
{
  while (count != 0u) {
    count--;
  }
}

static void uart_putc(uint8_t value)
{
  while ((MMIO32(UART_BASE + UART_STATUS) & UART_STATUS_TX_FULL) != 0u) {
  }

  MMIO32(UART_BASE + UART_TXDATA) = value;
}

static void uart_puts(const char *text)
{
  while (*text != '\0') {
    uart_putc((uint8_t)*text);
    text++;
  }
}

int main(void)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;
  uint32_t led = 1u;
  uint32_t ticks = 0u;

  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;
  MMIO32(GPIOA_BASE + GPIO_OUT) = 0x00000001u;

  MMIO32(UART_BASE + UART_CTRL) = 0u;
  MMIO32(UART_BASE + UART_BAUDDIV) = UART_DIV_115200;
  MMIO32(UART_BASE + UART_STATUS) = 0x0000001Eu;

  sram[0] = 0xB0A6D001u;
  sram[1] = 0x20001000u;
  sram[2] = 0x00000001u;
  sram[3] = 0x00000000u;

  while (1) {
    MMIO32(GPIOA_BASE + GPIO_OUT) = led;
    sram[2] = led;
    sram[3] = ticks;

    led <<= 1;
    if ((led == 0u) || (led > 0x8000u)) {
      led = 1u;
      ticks++;
      uart_puts("tick\r\n");
    }

    delay(5000000u);
  }

  return 0;
}
