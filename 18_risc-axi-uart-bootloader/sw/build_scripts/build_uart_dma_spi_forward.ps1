$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$swRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Resolve-Path (Join-Path $swRoot "..")
$outDir = Join-Path $swRoot "build_outputs"
$src = Join-Path $swRoot "firmware_sources\uart_dma_spi_forward.S"
$linker = Join-Path $swRoot "linker_scripts\linker.ld"
$elf = Join-Path $outDir "uart_dma_spi_forward.elf"
$bin = Join-Path $outDir "uart_dma_spi_forward.bin"
$mem = Join-Path $outDir "uart_dma_spi_forward.mem"
$romMem = Join-Path $projectRoot "HW\rtl\src\timing_programs\link_demo.mem"
$toolRoot = "C:\AMDDesignTools_vivado\2025.2\gnu\riscv\nt\bin"
$gcc = Join-Path $toolRoot "riscv64-unknown-elf-gcc.exe"
$objcopy = Join-Path $toolRoot "riscv64-unknown-elf-objcopy.exe"
$objdump = Join-Path $toolRoot "riscv64-unknown-elf-objdump.exe"

New-Item -ItemType Directory -Force $outDir | Out-Null

$map = Join-Path $outDir "uart_dma_spi_forward.map"
$gccArgs = @(
  "-march=rv32i_zicsr",
  "-mabi=ilp32",
  "-nostdlib",
  "-nostartfiles",
  "-ffreestanding",
  "-Wl,-T,$linker",
  "-Wl,--build-id=none",
  "-Wl,-Map,$map",
  "-o",
  $elf,
  $src
)

& $gcc @gccArgs

& $objcopy -O binary $elf $bin
python (Join-Path $swRoot "loader_tools\bin_to_mem.py") $bin $mem --words 4096
Copy-Item -Force $mem $romMem
& $objdump -d $elf | Out-File -Encoding ascii (Join-Path $outDir "uart_dma_spi_forward.dump")

$bytes = (Get-Item $bin).Length
$words = (Get-Content $mem).Count
Write-Host "MASTER_ROM_BUILD_PASS bytes=$bytes words=$words mem=$mem copied_to=$romMem"
