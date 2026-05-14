# RISC-V Core 기반 AXI-Lite/APB/AXI-Stream Mini MCU RTL 통합 설계

직접 구현한 RV32I pipeline core를 중심으로 AXI-Lite 제어 경로, APB peripheral subsystem, AXI-Stream DMA data path, PLIC-style interrupt, ROM UART bootloader를 하나의 SoC 시나리오로 통합한 프로젝트입니다.

![Overall block diagram](./docs/images/png/anti_fpgatop_block_diagram.png)

## 프로젝트 개요

| 항목 | 내용 |
|---|---|
| 유형 | 개인 프로젝트 / RISC-V 기반 SoC RTL 통합 설계 |
| 기간 | 2026.04 - 2026.05 |
| 언어 및 도구 | SystemVerilog, Verilog-HDL, C, Python, Vivado, RISC-V GCC |
| 핵심 키워드 | RV32I pipeline core, AXI-Lite, APB, AXI-Stream DMA, UART bootloader, PLIC-lite |
| 결과물 | RTL source, SystemVerilog testbench, UART bootloader download flow, 발표 PDF |

초기에는 STM32F103 계열 MCU의 AHB/APB 구조를 참고해 작은 MCU 형태의 SoC를 구성하는 것에서 출발했습니다. 이후 RGB byte stream 처리와 DMA 확장을 고려하면서, CPU가 담당하는 register control path와 DMA가 담당하는 payload data path를 분리할 필요가 있었습니다. 최종 구조는 RV32I core, instruction ROM, executable SRAM, AXI-Lite fabric, AXI-Lite-to-APB bridge, APB UART/SPI/GPIO/I2C/Timer/PLIC-lite/DMA로 구성했습니다.

## 설계 목표

이 프로젝트의 목표는 CPU 단품 구현이 아니라, firmware가 실제 peripheral을 제어하고 data stream demo까지 수행할 수 있는 mini MCU SoC를 구성하는 것이었습니다.

- RV32I core가 ROM/SRAM/peripheral memory map을 통해 동작하도록 SoC top 구성
- AXI-Lite는 memory-mapped control transaction, APB는 peripheral register access로 역할 분리
- UART RX stream -> DMA internal buffer -> SPI TX stream으로 이어지는 byte stream path 구성
- PLIC-lite interrupt를 통해 DMA done/error event를 machine external interrupt로 전달
- ROM에는 UART bootloader만 고정하고, C application은 UART로 SRAM에 다운로드해 실행

## 담당 및 구현 내용

- RV32I pipeline core와 SoC memory map 정리
- IBus ROM fetch 및 SRAM executable fetch path 구성
- DBus -> AXI-Lite master adapter -> AXI-Lite interconnect -> APB bridge 연결
- APB UART/SPI/GPIO/I2C/Timer/PLIC-lite/DMA peripheral integration
- AXI-Stream DMA 기반 UART-to-SPI RGB byte stream path 구성
- RISC-V GCC 기반 freestanding C firmware build flow 구성
- `_start`, stack 초기화, `.data` copy, `.bss` clear, `main()` 진입 runtime 작성
- ROM-resident UART bootloader와 RAXI loader packet protocol 구현
- Python sender/packet builder 및 간단 GUI 기반 download workflow 정리
- xsim simulation과 routed bitstream timing으로 주요 흐름 검증

## 핵심 구조

![AXI path summary](./docs/images/png/axi_path_summary.png)

```text
RV32I Core
├── IBus
│   ├── ROM fetch at 0x00000000
│   └── SRAM executable fetch at 0x20000000
└── DBus
    └── AXI-Lite Master Adapter
        ├── AXI-Lite ROM/SRAM
        └── AXI-Lite-to-APB Bridge
            ├── UART / SPI / GPIO / I2C / Timer
            ├── PLIC-lite
            └── APB-controlled AXI-Stream DMA
```

RGB image transfer scenario에서는 CPU가 byte payload를 직접 복사하지 않고, CPU는 DMA/UART/SPI/PLIC register 설정과 interrupt 처리만 담당합니다. 실제 payload는 UART stream에서 DMA buffer를 거쳐 SPI stream으로 이동합니다.

![UART-to-SPI DMA path](./docs/images/png/end_to_end_image_transfer.png)

## UART Bootloader Flow

기존에는 firmware를 바꿀 때마다 `.mem` 파일을 다시 만들고 bitstream을 재생성해야 했습니다. 이 반복 시간을 줄이기 위해 ROM에는 고정 UART loader만 두고, PC에서 빌드한 RAM application을 UART packet으로 SRAM에 적재한 뒤 entry address로 jump하는 구조를 만들었습니다.

![Bootloader flow](./docs/images/png/rgb_irq_rom_flow_v2.png)

```text
C source
-> riscv64-unknown-elf-gcc
-> ELF/BIN
-> RAXI loader packet
-> PC UART send
-> ROM UART loader
-> SRAM write at 0x20001000
-> jump to RAM app entry
```

## 검증 결과

```text
SOC_C_SMOKE_PASS gpio=0x00c6
SOC_UART_LOADER_PASS pc=0x20001158 gpio=0x00a5
UART_LOADER_IMPL_TIMING WNS_NS=2.100 REQUIREMENT_NS=20.000 FMAX_EST_MHZ=55.866
```

- C smoke simulation으로 startup, `.data` copy, `.bss` clear, GPIO/SRAM MMIO write 확인
- UART loader simulation으로 packet receive, SRAM write, SRAM instruction fetch, RAM app jump 확인
- RGB image scenario 기준 UART receive, DMA buffering, SPI transmit, PLIC interrupt 흐름 정리
- UART loader bitstream은 50 MHz target에서 positive slack으로 timing closure 확인

## 산출물

- [Presentation PDF](./RISC_AXI_UART_Bootloader_slides.pdf)
- [Technical Details](./DETAILS.md)
- `hw/`: RTL, testbench, constraints, ROM memory images
- `sw/`: firmware source, linker scripts, build/download scripts, UART loader tools
- `docs/images/png`: README/PDF용 diagram preview
- `docs/images/svg`: 원본 SVG diagram
- `docs/images/drawio`: editable Draw.io diagram source

## 주요 파일

```text
hw/rtl/soc/SocTop.sv
hw/rtl/soc/SocFpgaTop.sv
hw/rtl/core/pipeline/Rv32Core.sv
hw/rtl/core/pipeline/PipelineControl.sv
hw/rtl/core/pipeline/CsrFile.sv
hw/rtl/core/pipeline/TrapController.sv
hw/rtl/bus/apb/ApbPlicLite.sv
hw/rtl/bus/apb/ApbAxiStreamDma.sv
sw/firmware_sources/uart_loader_main.c
sw/firmware_sources/ram_uart_dma_spi_rgb_irq_main.c
sw/firmware_sources/startup_irq.S
sw/linker_scripts/linker_ram.ld
```

## 배운 점

처음에는 MCU block diagram의 각 bus와 peripheral이 추상적으로만 보였지만, core, bus fabric, bridge, peripheral, interrupt, firmware runtime을 직접 연결하면서 데이터시트의 블록들이 실제 RTL과 firmware 경계에서 어떤 역할을 갖는지 이해할 수 있었습니다. 특히 UART bootloader와 RAM execution flow를 구성하면서 linker script, startup code, memory map, packet protocol, interrupt return timing까지 하나의 hardware/software co-design 문제로 다루게 되었습니다.
