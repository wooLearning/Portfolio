param(
  [UInt32]$LoadAddr = 0x20001000,
  [UInt32]$EntryAddr = 0x20001000
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir "build_ram_app.ps1") `
  -Name "ram_board_bringup_app" `
  -Source "firmware_sources\ram_board_bringup_main.c" `
  -LoadAddr $LoadAddr `
  -EntryAddr $EntryAddr
