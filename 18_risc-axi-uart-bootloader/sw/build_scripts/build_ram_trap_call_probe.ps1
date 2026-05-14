param(
  [UInt32]$LoadAddr = 0x20001000,
  [UInt32]$EntryAddr = 0x20001000
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$swRoot = Resolve-Path (Join-Path $scriptDir "..")
$outDir = Join-Path $swRoot "build_outputs"
$source = Join-Path $swRoot "firmware_sources\ram_trap_call_probe.S"
$linker = Join-Path $swRoot "linker_scripts\linker_ram.ld"
$elf = Join-Path $outDir "ram_trap_call_probe.elf"
$bin = Join-Path $outDir "ram_trap_call_probe.bin"
$map = Join-Path $outDir "ram_trap_call_probe.map"
$dump = Join-Path $outDir "ram_trap_call_probe.dump"
$packetBin = Join-Path $outDir "ram_trap_call_probe_loader_packet.bin"
$packetHex = Join-Path $outDir "ram_trap_call_probe_loader_packet.hex"
$toolRoot = "C:\AMDDesignTools_vivado\2025.2\gnu\riscv\nt\bin"
$gcc = Join-Path $toolRoot "riscv64-unknown-elf-gcc.exe"
$objcopy = Join-Path $toolRoot "riscv64-unknown-elf-objcopy.exe"
$objdump = Join-Path $toolRoot "riscv64-unknown-elf-objdump.exe"

New-Item -ItemType Directory -Force $outDir | Out-Null

& $gcc `
  "-march=rv32i_zicsr" `
  "-mabi=ilp32" `
  "-mcmodel=medany" `
  "-mstrict-align" `
  "-msmall-data-limit=0" `
  "-nostdlib" `
  "-nostartfiles" `
  "-ffreestanding" `
  "-Wl,-T,$linker" `
  "-Wl,--build-id=none" `
  "-Wl,--no-relax" `
  "-Wl,-Map,$map" `
  "-o" `
  $elf `
  $source

& $objcopy -O binary $elf $bin
& $objdump -d $elf | Out-File -Encoding ascii $dump
python (Join-Path $swRoot "loader_tools\make_loader_packet.py") $bin $packetBin $packetHex --load-addr ("0x{0:x8}" -f $LoadAddr) --entry ("0x{0:x8}" -f $EntryAddr)

$bytes = (Get-Item $bin).Length
$packetBytes = (Get-Item $packetBin).Length
Write-Host "RAM_TRAP_CALL_PROBE_BUILD_PASS bytes=$bytes packet_bytes=$packetBytes elf=$elf packet_hex=$packetHex"
