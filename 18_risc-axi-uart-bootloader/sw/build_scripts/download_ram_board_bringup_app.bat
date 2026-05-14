@echo off
setlocal
if "%~1"=="" (
  echo Usage: %~nx0 COM_PORT
  echo Example: %~nx0 COM7
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0download_ram_app.ps1" -Port "%~1" -Name "ram_board_bringup_app" -Source "firmware_sources\ram_board_bringup_main.c"
