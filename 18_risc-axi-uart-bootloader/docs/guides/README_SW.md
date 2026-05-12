# SW Package

This folder contains firmware and PC-side loader tooling for the RISC_AXI custom RV32I SoC.

## Main Pieces

- `firmware_sources/startup.S`: freestanding C runtime entry. Initializes stack, copies `.data`, clears `.bss`, sets trap vector path as implemented, calls `main`, then parks.
- `firmware_sources/smoke_main.c`: minimal C smoke firmware that writes GPIO/SRAM markers.
- `firmware_sources/uart_loader_main.c`: fixed ROM UART loader.
- `firmware_sources/ram_led_main.c`: RAM app loaded by UART loader.
- `firmware_sources/ram_uart_echo_main.c`: RAM UART echo-style app.
- `firmware_sources/uart_dma_spi_rgb_irq_forward.S`: existing working assembly RGB IRQ firmware.

## Build Scripts

- `build_scripts/build_c_smoke.ps1`: builds C smoke ROM and emits `.elf/.bin/.mem/.dump/.map`.
- `build_scripts/build_uart_loader.ps1`: builds fixed loader ROM `.mem`.
- `build_scripts/build_ram_app.ps1`: builds a C RAM app and creates loader packet files.
- `build_scripts/download_ram_app.ps1`: builds a RAM app, then sends the loader packet over UART.
- `build_scripts/run_loader_gui.bat`: starts the loader GUI wrapper.

## Linker Scripts

- `linker_scripts/linker_c.ld`: ROM firmware layout. ROM starts at `0x00000000`; SRAM starts at `0x20000000`.
- `linker_scripts/linker_ram.ld`: executable RAM app layout. Default app load/entry area is around `0x20001000`.
- `linker_scripts/linker.ld`: legacy assembly ROM linker script.

## Tools

- `loader_tools/bin_to_mem.py`: raw binary to Vivado `.mem`.
- `loader_tools/make_loader_packet.py`: wraps a RAM app binary with loader header/checksum.
- `loader_tools/send_loader_packet.py`: sends packet to the board over UART.
- `loader_tools/loader_gui.py`: GUI wrapper for build/download flow.

For exact compiler/download commands, read `COMPILER_AND_DOWNLOAD_GUIDE.md`.
