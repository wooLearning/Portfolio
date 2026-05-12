# Portfolio Package Manifest

## Included

- Full curated RTL source under `source/rtl`.
- Focused SystemVerilog testbenches under `source/tb`.
- Basys3 constraints under `source/constraints`.
- Firmware C/assembly, linker scripts, build scripts, and UART loader tools under `source/sw`.
- PC-side image UART sender under `source/image_uart_sender`.
- Portfolio PDF under `docs/presentation`.
- Core Korean technical notes under `docs/guides` and `docs/portfolio`.
- SVG and draw.io diagrams under `diagrams`.
- UART loader ROM mem and optional bitstreams under `artifacts`.

## Excluded

- Vivado `.log` and `.jou` files.
- XSim generated working directories.
- Browser export cache/profile folders.
- Python `__pycache__`.
- Bulk generated build outputs, except selected ROM/bit artifacts.
- FPGA_AUTO framework templates and node modules.

## Most Important Files For Review

```text
source/rtl/soc/SocTop.sv
source/rtl/soc/SocFpgaTop.sv
source/rtl/core/pipeline/Rv32Core.sv
source/rtl/core/pipeline/PipelineControl.sv
source/rtl/core/pipeline/CsrFile.sv
source/rtl/core/pipeline/TrapController.sv
source/rtl/core/pipeline/MachineInterruptController.sv
source/rtl/bus/apb/ApbPlicLite.sv
source/rtl/bus/apb/ApbAxiStreamDma.sv
source/sw/firmware_sources/uart_loader_main.c
source/sw/firmware_sources/startup_irq.S
source/sw/firmware_sources/ram_uart_dma_spi_rgb_irq_main.c
source/sw/linker_scripts/linker_ram.ld
docs/guides/RAM_LOADER_LINKER_IRQ_DEBUG_KO.md
docs/presentation/RISC_AXI_UART_Bootloader_slides.pdf
```
