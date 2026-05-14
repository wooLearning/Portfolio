param(
  [string]$TimingMemName = "trap_call_probe.mem"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$swRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Resolve-Path (Join-Path $swRoot "..")
$outDir = Join-Path $swRoot "build_outputs"
$source = Join-Path $swRoot "firmware_sources\trap_call_probe.S"
$linker = Join-Path $swRoot "linker_scripts\linker.ld"
$elf = Join-Path $outDir "trap_call_probe.elf"
$bin = Join-Path $outDir "trap_call_probe.bin"
$mem = Join-Path $outDir "trap_call_probe.mem"
$dump = Join-Path $outDir "trap_call_probe.dump"
$timingMem = Join-Path $projectRoot (Join-Path "HW\rtl\src\timing_programs" $TimingMemName)
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
  "-nostdlib" `
  "-nostartfiles" `
  "-ffreestanding" `
  "-Wl,-T,$linker" `
  "-Wl,--build-id=none" `
  "-Wl,--no-relax" `
  "-o" `
  $elf `
  $source

& $objcopy -O binary $elf $bin
python (Join-Path $swRoot "loader_tools\bin_to_mem.py") $bin $mem --words 4096
Copy-Item -Force $mem $timingMem
& $objdump -d $elf | Out-File -Encoding ascii $dump

$bytes = (Get-Item $bin).Length
$words = (Get-Content $mem).Count
Write-Host "TRAP_CALL_PROBE_BUILD_PASS bytes=$bytes words=$words elf=$elf bin=$bin mem=$mem dump=$dump copied_to=$timingMem"
