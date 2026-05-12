param(
  [Parameter(Mandatory=$true)]
  [string]$Name,
  [Parameter(Mandatory=$true)]
  [string]$Source,
  [string]$Startup = "firmware_sources\startup.S",
  [string[]]$ExtraCFlags = @(),
  [UInt32]$LoadAddr = 0x20001000,
  [UInt32]$EntryAddr = 0x20001000
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$swRoot = Resolve-Path (Join-Path $scriptDir "..")
$outDir = Join-Path $swRoot "build_outputs"
$startupPath = if ([System.IO.Path]::IsPathRooted($Startup)) { $Startup } else { Join-Path $swRoot $Startup }
$sourcePath = if ([System.IO.Path]::IsPathRooted($Source)) { $Source } else { Join-Path $swRoot $Source }
if (!(Test-Path -LiteralPath $sourcePath)) {
  $sourcePath = Join-Path $swRoot (Join-Path "firmware_sources" (Split-Path -Leaf $Source))
}
$linker = Join-Path $swRoot "linker_scripts\linker_ram.ld"
$elf = Join-Path $outDir "$Name.elf"
$bin = Join-Path $outDir "$Name.bin"
$map = Join-Path $outDir "$Name.map"
$dump = Join-Path $outDir "$Name.dump"
$packetBin = Join-Path $outDir "${Name}_loader_packet.bin"
$packetHex = Join-Path $outDir "${Name}_loader_packet.hex"
$toolRoot = "C:\AMDDesignTools_vivado\2025.2\gnu\riscv\nt\bin"
$gcc = Join-Path $toolRoot "riscv64-unknown-elf-gcc.exe"
$objcopy = Join-Path $toolRoot "riscv64-unknown-elf-objcopy.exe"
$objdump = Join-Path $toolRoot "riscv64-unknown-elf-objdump.exe"

if (!(Test-Path -LiteralPath $sourcePath)) {
  throw "RAM app source not found: $sourcePath"
}
if (!(Test-Path -LiteralPath $startupPath)) {
  throw "Startup source not found: $startupPath"
}

New-Item -ItemType Directory -Force $outDir | Out-Null

$gccArgs = @(
  "-march=rv32i_zicsr",
  "-mabi=ilp32",
  "-mcmodel=medany",
  "-mstrict-align",
  "-msmall-data-limit=0",
  "-nostdlib",
  "-nostartfiles",
  "-ffreestanding",
  "-fno-pic",
  "-fno-builtin",
  "-fno-asynchronous-unwind-tables",
  "-fno-unwind-tables",
  "-Os",
  $ExtraCFlags,
  "-Wl,-T,$linker",
  "-Wl,--build-id=none",
  "-Wl,--no-relax",
  "-Wl,-Map,$map",
  "-o",
  $elf,
  $startupPath,
  $sourcePath
)

& $gcc @gccArgs
& $objcopy -O binary $elf $bin
& $objdump -d $elf | Out-File -Encoding ascii $dump
python (Join-Path $swRoot "loader_tools\make_loader_packet.py") $bin $packetBin $packetHex --load-addr ("0x{0:x8}" -f $LoadAddr) --entry ("0x{0:x8}" -f $EntryAddr)

$bytes = (Get-Item $bin).Length
$packetBytes = (Get-Item $packetBin).Length
Write-Host "RAM_APP_BUILD_PASS name=$Name bytes=$bytes packet_bytes=$packetBytes elf=$elf bin=$bin dump=$dump packet_bin=$packetBin packet_hex=$packetHex"
