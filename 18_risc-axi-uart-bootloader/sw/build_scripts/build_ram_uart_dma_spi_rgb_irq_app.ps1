param(
  [UInt32]$ImageBytes = 12288,
  [UInt32]$LoadAddr = 0x20001000,
  [UInt32]$EntryAddr = 0x20001000
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir "build_ram_app.ps1") `
  -Name "ram_uart_dma_spi_rgb_irq_app" `
  -Source "firmware_sources\ram_uart_dma_spi_rgb_irq_main.c" `
  -Startup "firmware_sources\startup_irq.S" `
  -ExtraCFlags @("-DIMAGE_BYTES_VALUE=$ImageBytes") `
  -LoadAddr $LoadAddr `
  -EntryAddr $EntryAddr
