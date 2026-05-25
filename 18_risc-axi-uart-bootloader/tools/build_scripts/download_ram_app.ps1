param(
  [Parameter(Mandatory=$true)]
  [string]$Port,
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$Source,
  [string]$Startup = "firmware_sources\startup.S",
  [string[]]$ExtraCFlags = @(),
  [UInt32]$LoadAddr = 0,
  [UInt32]$EntryAddr = 0,
  [int]$Baud = 115200,
  [int]$Chunk = 32,
  [double]$ChunkDelay = 0.002
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..\..")).Path
$swRoot = Join-Path $repoRoot "SW"
$buildRoot = Join-Path $repoRoot "build"
$loaderToolRoot = Join-Path $repoRoot "tools\flows\loader"
$linkerRoot = Join-Path $repoRoot "tools\flows\linker\current"
$packetToolRoot = Join-Path $loaderToolRoot "packet_tools"
& (Join-Path $scriptDir "build_ram_app.ps1") -Name $Name -Source $Source -Startup $Startup -ExtraCFlags $ExtraCFlags -LoadAddr $LoadAddr -EntryAddr $EntryAddr

$packetBin = Join-Path (Join-Path $buildRoot "sw\current") "${Name}_loader_packet.bin"
py -3 (Join-Path $packetToolRoot "send_loader_packet.py") $Port $packetBin --baud $Baud --chunk $Chunk --chunk-delay $ChunkDelay
if ($LASTEXITCODE -ne 0) {
  throw "send_loader_packet.py failed with exit code $LASTEXITCODE"
}

Write-Host "RAM_APP_DOWNLOAD_PASS name=$Name port=$Port baud=$Baud packet=$packetBin"
