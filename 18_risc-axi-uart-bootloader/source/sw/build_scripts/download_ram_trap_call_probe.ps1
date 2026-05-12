param(
  [Parameter(Mandatory=$true)]
  [string]$Port,
  [int]$Baud = 115200,
  [int]$Chunk = 32,
  [double]$ChunkDelay = 0.002
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$swRoot = Resolve-Path (Join-Path $scriptDir "..")

& (Join-Path $scriptDir "build_ram_trap_call_probe.ps1")

$packetBin = Join-Path $swRoot "build_outputs\ram_trap_call_probe_loader_packet.bin"
python (Join-Path $swRoot "loader_tools\send_loader_packet.py") $Port $packetBin --baud $Baud --chunk $Chunk --chunk-delay $ChunkDelay

Write-Host "RAM_TRAP_CALL_PROBE_DOWNLOAD_PASS port=$Port baud=$Baud packet=$packetBin"
