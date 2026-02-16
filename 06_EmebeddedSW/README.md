# 임베디드 소프트웨어 프로젝트 포트폴리오 (ATtiny -> STM32)
# Embedded Software Portfolio (ATtiny to STM32)

## 1. 프로젝트 개요 | Portfolio Snapshot
- 구분 / Category: `전공 프로젝트 (Embedded Software)`
- 기간 / Period: `2024.12.23 ~ 2025.01.24`
- 근거 / Date reference: root experience CSV

## 2. 한국어 요약 | Korean Summary
ATtiny 기반 주변장치 제어에서 시작해 STM32 기반 그래픽/터치 프로젝트로 확장한 임베디드 프로젝트 모음입니다.  
타이머/인터럽트/PWM/UART/SPI 등을 단계적으로 적용하며 하드웨어-소프트웨어 통합 역량을 강화했습니다.

## 3. English Summary
This folder contains embedded projects that progress from ATtiny peripheral control to STM32 graphics and touch applications.  
The work incrementally applies timer, interrupt, PWM, UART, and SPI integration across AVR and STM32 platforms.

## 4. 프로젝트 트랙 | Project Tracks
### Track 1: ATtiny2313A timer project
- `1st project` 보고서
- HD44780, MAX7219, SH1106 동시 제어
- 스위치 기반 timer start/reset 동작

### Track 2: ATtiny4313 integration project
- `2nd project` 보고서
- 인터럽트 기반 rotary/keyboard 입력 처리
- PWM LED 밝기 제어
- UART 통신 경로 통합

### Track 3 (required): STM32F401CC rendering project
- `3-1 project` 보고서
- encoder 인터랙션
- addressable LED + display 연동
- ILI9341 gradient rendering 및 DMA 활용

### Track 3 (optional): STM32F401CC touch game
- `3-2 project` 보고서
- touch-screen card matching game 구현
- display/score 출력용 SPI 주변장치 연동

## 5. 증빙 자료 | Evidence and Media
- 각 트랙별 PDF/DOCX 보고서
- 트랙별 데모 비디오
- AVR/STM32 소스 트리 (`main.c`, `Core/Inc/Src`, startup files)

## 6. 기술 스택 | Tech Stack
- MCU: `ATtiny2313A/4313`, `STM32F401CC`
- Language: `C`
- Peripherals: GPIO, timer, PWM, SPI, UART, display, touch
