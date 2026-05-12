# Portfolio Summary

## 프로젝트 제목

Custom RV32I AXI SoC 및 UART Bootloader 기반 Firmware Download 환경 구현

## 프로젝트 개요

직접 설계한 RV32I 기반 SoC를 AHB 중심 구조에서 AXI-Lite/APB/AXI-Stream 기반 구조로 재구성하고, UART/SPI/DMA/PLIC peripheral을 통합했다. 이후 firmware 개발 속도를 개선하기 위해 ROM에는 고정 bootloader만 탑재하고, PC에서 컴파일한 RISC-V C application을 UART로 SRAM에 다운로드해 실행하는 개발 구조를 구현했다.

## 담당 / 구현 내용

- RV32I SoC memory map 정리
- AXI-Lite instruction/data/control path 구성
- AXI-Lite-to-APB bridge 기반 peripheral access 구조 구성
- APB UART/SPI/GPIO/PLIC/DMA 연동
- APB-controlled AXI-Stream DMA 기반 이미지 전달 구조 구현
- RISC-V GCC 기반 C firmware build flow 구축
- freestanding C runtime 작성
  - stack pointer 초기화
  - `.data` ROM-to-SRAM copy
  - `.bss` zero clear
  - `main()` 호출
- ROM-resident UART bootloader 구현
- executable SRAM fetch path 추가
- PC-side firmware download workflow 구현
  - PowerShell build script
  - Python packet generator
  - Python UART sender
  - Tkinter 기반 간단 GUI launcher
- Vivado/xsim simulation 및 routed bitstream timing 검증

## 핵심 성과

- FPGA bitstream 재빌드 없이 C firmware를 빠르게 반복 실행할 수 있는 구조 구축
- UART loader를 통해 PC에서 SRAM으로 application binary를 다운로드하고 entry address로 jump하는 흐름 검증
- custom RV32I core에서 C runtime, linker script, binary-to-memory image 변환 과정을 직접 구성
- AXI-Lite/APB/AXI-Stream bus 역할을 분리해 control path와 streaming data path를 구분

## 검증 결과

- C smoke firmware simulation PASS
- UART loader simulation PASS
- RAM app execution PASS
- UART loader bitstream timing met
  - WNS: `2.100 ns`
  - target: `20.000 ns`
  - estimated Fmax: `55.866 MHz`

## 포트폴리오 한 줄

> Custom RV32I SoC에서 ROM UART bootloader와 executable SRAM path를 구현하고, PC-side RISC-V compiler 및 Python UART downloader를 연동하여 FPGA bitstream 재생성 없이 C firmware를 동적으로 적재/실행하는 개발 환경을 구축했다.

## 강조하면 좋은 포인트

- 단순 HDL 구현이 아니라 hardware/software co-design 문제를 해결했다.
- linker script, startup code, memory map, ROM/RAM execution, UART protocol까지 end-to-end로 다뤘다.
- simulation-only가 아니라 bitstream timing까지 확인했다.
- 기존 assembly ROM 흐름을 보존하면서 C 기반 workflow를 새로 추가했다.

## 면접 답변용 짧은 설명

기존에는 firmware를 바꿀 때마다 `.mem`을 다시 만들고 Vivado bitstream을 재생성해야 했습니다. 이 반복 시간이 길어서, ROM에는 UART bootloader만 고정하고 application은 PC에서 RISC-V GCC로 컴파일해 UART로 SRAM에 다운로드하는 구조를 만들었습니다. 이를 위해 CPU instruction fetch path가 SRAM도 읽을 수 있게 RTL을 확장했고, C startup code와 linker script를 작성해 RAM app이 독립적으로 실행되도록 했습니다. xsim에서 UART packet download, SRAM write, RAM app jump를 검증했고, loader bitstream도 timing closure를 확인했습니다.
