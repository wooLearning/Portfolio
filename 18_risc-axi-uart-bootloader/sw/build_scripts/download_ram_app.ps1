param(
  [Parameter(Mandatory=$true)]
  [string]$Port,
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$Source,
  [string]$Startup = "firmware_sources\startup.S",
  [string[]]$ExtraCFlags = @(),
  [UInt32]$LoadAddr = 0x20001000,
  [UInt32]$EntryAddr = 0x20001000,
  [int]$Baud = 115200,
  [int]$Chunk = 32,
  [double]$ChunkDelay = 0.002
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$swRoot = Resolve-Path (Join-Path $scriptDir "..")
& (Join-Path $scriptDir "build_ram_app.ps1") -Name $Name -Source $Source -Startup $Startup -ExtraCFlags $ExtraCFlags -LoadAddr $LoadAddr -EntryAddr $EntryAddr

$packetBin = Join-Path $swRoot (Join-Path "build_outputs" "${Name}_loader_packet.bin")
python (Join-Path $swRoot "loader_tools\send_loader_packet.py") $Port $packetBin --baud $Baud --chunk $Chunk --chunk-delay $ChunkDelay

Write-Host "RAM_APP_DOWNLOAD_PASS name=$Name port=$Port baud=$Baud packet=$packetBin"
