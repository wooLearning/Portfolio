# RISC_AXI Clean Handoff

Date: 2026-05-09

This folder is a clean handoff package for the custom RV32I RISC_AXI project. It is organized for a new project or portfolio continuation, not as a full Vivado/xsim workspace dump.

## Top-Level Structure

- `docs/`: latest summary docs, portfolio notes, verification notes, and SVG/drawio diagrams.
- `HW/`: RTL, testbenches, constraints, ROM `.mem` images, Vivado helper Tcl, bitstreams, and selected reports.
- `SW/`: firmware source, startup/runtime code, linker scripts, compiler build scripts, loader packet tools, and reference firmware outputs.
- `image_uart_sender/`: Python PC-side UART image transfer tool and sample image assets.

## What Was Intentionally Excluded

- Vivado project cache folders such as `.Xil`, `.runs`, `.sim`, `.cache`, and `xsim.dir`.
- xsim generated logs, journals, waveform DBs, and temporary backup files.
- Large duplicated presentation/package folders that are not needed to rebuild the current handoff.

## Current Technical State

- Core: custom RV32I pipeline SoC.
- Bus/peripherals: AXI-Lite, APB peripherals, AXI-Stream DMA path, UART/SPI/GPIO/PLIC-style IRQ blocks.
- ROM flow: `.S` or C firmware -> ELF -> binary -> `.mem` -> `readmemh` ROM.
- C flow: freestanding RISC-V GCC using `startup.S`, linker scripts, no libc.
- Loader flow: fixed UART loader ROM receives executable RAM app over UART and jumps to SRAM.

## Known Verified Points

- C smoke firmware reached GPIO/SRAM expected values in simulation.
- UART loader simulation reached SRAM app and observed expected GPIO/SRAM result.
- UART loader bitstream met timing with positive slack.
- Existing assembly RGB IRQ ROM flow was kept separate and not replaced by the C/loader work.

Start with `FILE_INDEX.md`, then read `SW/README_SW.md` and `HW/README_HW.md`.
