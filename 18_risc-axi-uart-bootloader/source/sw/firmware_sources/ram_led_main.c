#include <stdint.h>

#define GPIOA_BASE 0x40010000u
#define GPIO_OUT   0x00u
#define GPIO_DIR   0x08u
#define SRAM_BASE  0x20000000u

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

volatile uint32_t g_ram_app_data = 0xABCD1234u;
volatile uint32_t g_ram_app_bss;

int main(void)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;

  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;

  sram[0] = 0xA5500001u;
  sram[1] = 0x20001000u;
  sram[2] = g_ram_app_data;
  sram[3] = g_ram_app_bss;

  g_ram_app_bss = 0x00000077u;
  MMIO32(GPIOA_BASE + GPIO_OUT) = 0x000000A5u;

  while (1) {
  }

  return 0;
}
