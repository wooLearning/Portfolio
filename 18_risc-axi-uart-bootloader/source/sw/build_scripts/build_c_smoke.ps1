param(
  [string]$TimingMemName = "c_smoke.mem"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$swRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Resolve-Path (Join-Path $swRoot "..")
$outDir = Join-Path $swRoot "build_outputs"
$startup = Join-Path $swRoot "firmware_sources\startup.S"
$main = Join-Path $swRoot "firmware_sources\smoke_main.c"
$linker = Join-Path $swRoot "linker_scripts\linker_c.ld"
$elf = Join-Path $outDir "c_smoke.elf"
$bin = Join-Path $outDir "c_smoke.bin"
$mem = Join-Path $outDir "c_smoke.mem"
$map = Join-Path $outDir "c_smoke.map"
$dump = Join-Path $outDir "c_smoke.dump"
$timingMem = Join-Path $projectRoot (Join-Path "HW\rtl\src\timing_programs" $TimingMemName)
$toolRoot = "C:\AMDDesignTools_vivado\2025.2\gnu\riscv\nt\bin"
$gcc = Join-Path $toolRoot "riscv64-unknown-elf-gcc.exe"
$objcopy = Join-Path $toolRoot "riscv64-unknown-elf-objcopy.exe"
$objdump = Join-Path $toolRoot "riscv64-unknown-elf-objdump.exe"

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
  "-Wl,-T,$linker",
  "-Wl,--build-id=none",
  "-Wl,-Map,$map",
  "-o",
  $elf,
  $startup,
  $main
)

& $gcc @gccArgs
& $objcopy -O binary $elf $bin
python (Join-Path $swRoot "loader_tools\bin_to_mem.py") $bin $mem --words 4096
Copy-Item -Force $mem $timingMem
& $objdump -d $elf | Out-File -Encoding ascii $dump

$bytes = (Get-Item $bin).Length
$words = (Get-Content $mem).Count
Write-Host "C_SMOKE_ROM_BUILD_PASS bytes=$bytes words=$words elf=$elf bin=$bin mem=$mem dump=$dump copied_to=$timingMem"
