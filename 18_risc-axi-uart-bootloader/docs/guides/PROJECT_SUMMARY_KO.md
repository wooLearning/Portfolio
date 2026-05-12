# RISC_AXI Project Summary

## 한 줄 요약

Custom RV32I SoC를 AHB 기반 구조에서 AXI-Lite/APB/AXI-Stream 기반 구조로 재구성하고, UART bootloader를 통해 PC에서 컴파일한 RISC-V C firmware를 bitstream 재생성 없이 SRAM에 다운로드해 실행하는 개발 루프를 구현했다.

## 시스템 구조

- CPU: custom RV32I core
- Instruction path:
  - `0x0000_0000`: ROM fetch
  - `0x2000_0000`: SRAM executable fetch
- Data/control bus:
  - core DBus -> AXI-Lite master adapter
  - AXI-Lite interconnect -> ROM / SRAM / peripheral window
  - peripheral window -> AXI-Lite-to-APB bridge
- Peripherals:
  - GPIO
  - UART
  - SPI
  - I2C
  - Timer
  - PLIC-lite
  - APB-controlled AXI-Stream DMA
- Bulk image path:
  - UART RX stream -> DMA internal buffer -> SPI TX stream

## Firmware Evolution

1. 기존 firmware는 `.S` assembly 기반 ROM이었다.
2. RISC-V GCC를 이용해 assembly를 ELF/BIN/MEM으로 만드는 흐름은 있었다.
3. C를 사용하기 위해 freestanding startup/runtime을 추가했다.
4. C smoke firmware로 GPIO/SRAM write를 검증했다.
5. ROM-resident UART bootloader를 구현했다.
6. SRAM instruction fetch path를 추가해 RAM app 실행이 가능해졌다.
7. PC compiler + Python UART download workflow를 구축했다.

## UART Bootloader 구조

ROM에는 고정 loader만 탑재한다.

PC에서:

```text
C source
-> riscv64-unknown-elf-gcc
-> ELF
-> BIN
-> loader packet
-> Python UART send
```

FPGA에서:

```text
ROM loader
-> UART packet receive
-> checksum/load range validation
-> payload write to SRAM
-> jump to entry address
-> RAM app execution
```

## Loader Packet Format

All integer fields are little-endian.

```text
magic       4 bytes  "RAXI"
load_addr   4 bytes
byte_count  4 bytes
entry_addr  4 bytes
checksum    4 bytes  additive byte checksum over payload
payload     N bytes  word-padded raw binary
```

Default RAM app address: `0x20001000`

Default RAM app stack top: `0x20004000`

## Key Verification

- C smoke simulation PASS:
  - GPIO final: `0x00C6`
  - SRAM debug words: `C0DE0001 / 11112222 / 00000000 / C0DEF00D`
- UART loader simulation PASS:
  - packet received over UART
  - SRAM write succeeded
  - PC jumped to SRAM app
  - RAM app final GPIO: `0x00A5`
- UART loader bitstream timing PASS:
  - WNS: `2.100 ns` at `20.000 ns`
  - estimated Fmax: `55.866 MHz`

## Current Limitation / Next Work

- Loader is verified with LED and UART echo RAM apps.
- DMA image firmware still needs to be ported from assembly to C RAM app.
- Recommended next path:
  1. UART echo app board test
  2. DMA 4-byte polling app in C
  3. DMA RGB 12,288-byte polling app in C
  4. DMA RGB IRQ app in C + small trap assembly
  5. GUI integration for image send/receive/compare
