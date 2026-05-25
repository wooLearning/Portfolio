param(
  [UInt32]$ImageBytes = 12288,
  [UInt32]$LoadAddr = 0,
  [UInt32]$EntryAddr = 0
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir "build_ram_app.ps1") `
  -Name "ram_uart_dma_spi_rgb_poll_app" `
  -Source "firmware_sources\ram_uart_dma_spi_rgb_poll_main.c" `
  -ExtraCFlags @("-DIMAGE_BYTES_VALUE=$ImageBytes") `
  -LoadAddr $LoadAddr `
  -EntryAddr $EntryAddr
