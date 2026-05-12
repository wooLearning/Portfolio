@echo off
setlocal
if "%~1"=="" (
  echo Usage: %~nx0 COM_PORT
  echo Example: %~nx0 COM7
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0download_ram_app.ps1" -Port "%~1" -Name "ram_uart_dma_spi_rgb_irq_app" -Source "firmware_sources\ram_uart_dma_spi_rgb_irq_main.c" -Startup "firmware_sources\startup_irq.S" -ExtraCFlags "-DIMAGE_BYTES_VALUE=12288"
