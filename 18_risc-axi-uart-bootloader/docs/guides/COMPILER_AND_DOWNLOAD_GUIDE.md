# Compiler And Download Guide

## Toolchain

The working scripts use the RISC-V GCC bundled with Vivado/AMD tools:

```powershell
C:\AMDDesignTools_vivado\2025.2\gnu\riscv\nt\bin\riscv64-unknown-elf-gcc.exe
```

Common compile flags:

```text
-march=rv32i_zicsr
-mabi=ilp32
-mcmodel=medany
-mstrict-align
-msmall-data-limit=0
-nostdlib
-nostartfiles
-ffreestanding
-fno-pic
-fno-builtin
-Os
```

This is a freestanding flow. Do not assume libc, startup files, syscalls, heap, printf, or OS services.

## Build C Smoke ROM

From this handoff folder:

```powershell
.\SW\build_scripts\build_c_smoke.ps1
```

Expected outputs:

- `SW\build_outputs\c_smoke.elf`
- `SW\build_outputs\c_smoke.bin`
- `SW\build_outputs\c_smoke.mem`
- `SW\build_outputs\c_smoke.dump`
- copied ROM image at `HW\rtl\src\timing_programs\c_smoke.mem`

## Build Fixed UART Loader ROM

```powershell
.\SW\build_scripts\build_uart_loader.ps1
```

Expected output copied to:

```text
HW\rtl\src\timing_programs\uart_loader.mem
```

This is the ROM that stays fixed in hardware.

## Build A RAM App Packet

```powershell
.\SW\build_scripts\build_ram_app.ps1 -Name ram_led -Source firmware_sources\ram_led_main.c
```

Expected packet outputs:

- `SW\build_outputs\ram_led_loader_packet.bin`
- `SW\build_outputs\ram_led_loader_packet.hex`

Default load and entry address:

```text
0x20001000
```

## Download A RAM App Over UART

With the board already programmed with `risc_axi_uart_loader.bit`:

```powershell
.\SW\build_scripts\download_ram_app.ps1 -Port COMx -Name ram_led -Source firmware_sources\ram_led_main.c
```

Replace `COMx` with the board UART COM port.

The ROM loader receives the packet, writes executable SRAM, then jumps to the RAM app entry address.

## Relationship To Image UART Sender

The loader tools in `SW/loader_tools/` send executable code packets to the MCU-like loader ROM.

The `image_uart_sender/` folder is a separate PC tool for sending image payloads through the UART/image-data path. It is useful for the DMA/image demo direction, but it is not the same as executable RAM app loading.
