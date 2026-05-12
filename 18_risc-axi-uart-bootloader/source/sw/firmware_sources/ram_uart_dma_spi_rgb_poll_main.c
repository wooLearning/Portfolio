#include <stdint.h>

#define GPIOA_BASE       0x40010000u
#define SPI_BASE         0x40030000u
#define UART_BASE        0x40050000u
#define DMA_BASE         0x40060000u
#define SRAM_BASE        0x20000000u

#define GPIO_OUT         0x00u
#define GPIO_DIR         0x08u

#define SPI_CTRL         0x00u
#define SPI_STATUS       0x04u
#define SPI_CLKDIV       0x08u

#define UART_CTRL        0x00u
#define UART_STATUS      0x04u
#define UART_BAUDDIV     0x08u

#define DMA_CTRL         0x00u
#define DMA_STATUS       0x04u
#define DMA_LEN_BYTES    0x08u
#define DMA_CLEAR        0x10u
#define DMA_BUF_ADDR     0x14u

#define DMA_STATUS_BUSY      (1u << 0)
#define DMA_STATUS_DONE      (1u << 1)
#define DMA_STATUS_ERROR     (1u << 2)
#define DMA_CLEAR_DONE_ERROR ((1u << 1) | (1u << 2))

#define UART_CTRL_RX_DMA_EN  (1u << 4)
#define SPI_CTRL_TX_DMA_EN   (1u << 5)

#define DMA_CTRL_START       (1u << 0)
#define DMA_CTRL_DIR_TX      (1u << 2)

#define UART_DIV_115200      26u
#define SPI_SAFE_DIV         99u
#ifndef IMAGE_BYTES_VALUE
#define IMAGE_BYTES_VALUE    12288u
#endif

#define IMAGE_BYTES          IMAGE_BYTES_VALUE

#define MMIO32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

static void gpio_set(uint32_t value)
{
  MMIO32(GPIOA_BASE + GPIO_OUT) = value;
}

static void mark_state(uint32_t state, uint32_t detail)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;

  sram[0] = state;
  sram[1] = detail;
  gpio_set(state & 0x0000FFFFu);
}

static void dma_setup(uint32_t length)
{
  MMIO32(DMA_BASE + DMA_CLEAR) = DMA_CLEAR_DONE_ERROR;
  MMIO32(DMA_BASE + DMA_BUF_ADDR) = 0u;
  MMIO32(DMA_BASE + DMA_LEN_BYTES) = length;
}

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

int main(void)
{
  volatile uint32_t * const sram = (volatile uint32_t *)(uintptr_t)SRAM_BASE;
  uint32_t frame_count = 0u;

  MMIO32(GPIOA_BASE + GPIO_DIR) = 0x0000FFFFu;
  mark_state(0x00001001u, IMAGE_BYTES);

  sram[2] = 0u;
  sram[3] = 0u;

  MMIO32(UART_BASE + UART_CTRL) = 0u;
  MMIO32(UART_BASE + UART_BAUDDIV) = UART_DIV_115200;
  MMIO32(UART_BASE + UART_STATUS) = 0x0000001Eu;
  MMIO32(UART_BASE + UART_CTRL) = UART_CTRL_RX_DMA_EN;

  MMIO32(SPI_BASE + SPI_CTRL) = 0u;
  MMIO32(SPI_BASE + SPI_CLKDIV) = SPI_SAFE_DIV;
  MMIO32(SPI_BASE + SPI_STATUS) = 0x0000000Eu;
  MMIO32(SPI_BASE + SPI_CTRL) = SPI_CTRL_TX_DMA_EN;

  while (1) {
    uint32_t status;

    dma_setup(IMAGE_BYTES);
    mark_state(0x00002100u, frame_count);
    MMIO32(DMA_BASE + DMA_CTRL) = DMA_CTRL_START;

    status = wait_dma_done();
    if ((status & DMA_STATUS_ERROR) != 0u) {
      mark_state(0x0000E101u, status);
      while (1) {
      }
    }

    mark_state(0x00002300u, status);

    dma_setup(IMAGE_BYTES);
    mark_state(0x00003100u, frame_count);
    MMIO32(DMA_BASE + DMA_CTRL) = DMA_CTRL_START | DMA_CTRL_DIR_TX;

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
