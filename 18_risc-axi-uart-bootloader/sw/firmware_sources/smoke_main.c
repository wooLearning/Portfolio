#include <stdint.h>

#include "soc_address_map.h"

#define GPIO_OUT   0x00u
#define GPIO_DIR   0x08u

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

volatile uint32_t g_smoke_data = 0x11112222u;
volatile uint32_t g_bss_counter;

int main(void)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;

  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;
  MMIO32(GPIOA_BASE + GPIO_OUT) = 0x000000C5u;

  sram[0] = 0xC0DE0001u;
  sram[1] = g_smoke_data;
  sram[2] = g_bss_counter;

  g_bss_counter = 0x00000055u;
  sram[3] = 0xC0DEF00Du;

  MMIO32(GPIOA_BASE + GPIO_OUT) = 0x000000C6u;

  while (1) {
  }

  return 0;
}
