# HW Package

This folder contains hardware-side material only: RTL, testbenches, constraints, ROM machine-code images, selected bitstreams, Vivado helper scripts, and reports.

## Important RTL Areas

- `rtl/src/soc/SocTop.sv`: SoC integration. Current loader-capable design muxes instruction fetch between ROM at `0x0000_0000` and executable SRAM at `0x2000_0000`.
- `rtl/src/bus/axi/AxiLiteSram.sv`: AXI-Lite SRAM with instruction-read local port for RAM app execution.
- `rtl/src/bus/axi/AxiLiteRom.sv` and `rtl/src/soc/IcodeLocalRom.sv`: ROM readmemh path.
- `rtl/src/core/pipeline/`: RV32I custom core pipeline. Loader work did not intentionally change forwarding/hazard/core execution logic.
- `rtl/src/bus/apb/`: APB UART/SPI/GPIO/timer/IRQ/DMA peripherals.

## ROM Images

`rom_images/timing_programs/` contains `.mem` files used by RTL via `readmemh`.

Key images:

- `uart_dma_spi_rgb_irq_forward.mem`: existing assembly RGB IRQ demo.
- `c_smoke.mem`: minimal C firmware smoke test image.
- `uart_loader.mem`: fixed ROM loader image.
- `ram_*` apps are built/downloaded as packets from SW, not normally loaded as ROM.

## Bitstreams

`bitstreams/` contains selected known-useful programming files:

- `risc_axi_uart_loader.bit`: loader ROM hardware image.
- `risc_axi_c_smoke.bit`: C smoke hardware image.
- `master_risc_axi_rgb_irq_forward.bit`: existing assembly RGB IRQ demo bitstream.

## Notes

`constraints/SocFpgaTop_basys3.xdc` is for the main/master SoC FPGA top. Slave-side constraints are kept separately under `constraints/slave/` so they do not get mixed into the active master Vivado build by accident.

This handoff intentionally excludes xsim build output. Use the source testbenches in `tb/` if simulation is needed, but this package is not meant to include generated simulation databases.
