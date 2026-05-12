@echo off
setlocal
if "%~1"=="" (
  echo Usage: %~nx0 COM_PORT
  echo Example: %~nx0 COM4
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0download_ram_trap_call_probe.ps1" -Port "%~1"
