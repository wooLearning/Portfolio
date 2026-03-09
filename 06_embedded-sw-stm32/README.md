# 임베디드 소프트웨어 (ATtiny to STM32)
> Embedded Software Project Portfolio

## 📅 Project Info
- **Period**: 2024.12.23 ~ 2025.01.24
- **Platform**: `ATtiny2313A` `STM32F401CC`
- **Stack**: `C` `GPIO` `Timer` `SPI` `UART`

## 📝 Summary
AVR(ATtiny2313A/4313)부터 ARM(STM32F401CC) 아키텍처까지 다양한 MCU 환경에서 디바이스 제어 및 통신 인터페이스 통합을 수행한 **임베디드 소프트웨어 실무 프로젝트**입니다.
단순한 타이머 제어를 넘어 하드웨어 리소스 최적화, 다중 디스플레이 제어, DMA 기반의 고속 그래픽 렌더링, 그리고 자체적인 터치 UI 게임 구현에 이르기까지 단계별로 고도화된 시스템 통합 역량을 입증했습니다.

## 💡 Key Features & Achievements
1. **[1차] ATtiny2313A 다중 디스플레이 타이머 제어**
   * 한정된 핀을 활용하여 세 가지 디스플레이(HD44780, MAX7219, SH1106)를 동시 제어.
   * Clock Loop를 기반으로 한 시간 측정 동작 구현.

2. **[2차] ATtiny4313 주변장치 및 통신 통합 제어**
   * **Interrupt & PWM**: Rotary Switch 인터럽트를 활용한 가변 값 증감 및 OCR 레지스터 조작을 통한 LED 밝기(PWM) 제어.
   * **Software/Hardware UART**: 한정된 H/W 자원의 제약을 극복하기 위해 UART RX는 소프트웨어로, TX는 내부 하드웨어 모듈로 분리 구현하여 키보드(PS/2) ASCII 입력을 PC로 전송.

3. **[3차 필수] STM32F401CC DMA 기반 그래픽 고속 렌더링**
   * **DMA & Double Buffering**: ILI9341 디스플레이를 활용한 그래픽 출력 시 DMA와 듀얼 버퍼를 도입, 렌더링 및 데이터 전송 오버헤드를 대폭 감소시킴.
   * **Graphics Optimization**: Gamma Correction 기법 및 Sprite Rendering을 도입하여 색감을 자연스럽게 보정하고 RGB Gradation 효과를 완벽에 가깝게 구현.

4. **[3차 선택] SPI 채널 다중 활용 및 터치스크린 UI 게임 설계**
   * **Multi-SPI Control**: STM32 보드 내 가용 가능한 3개의 SPI 채널을 극한으로 응용하여 ILI9341 디스플레이, MAX7219, Addressable LED를 동시/병렬 제어.
   * **Touch UI Implementation**: XPT2046 컨트롤러 터치 이벤트 및 좌표 매핑을 통합하여 자체 알고리즘 기반의 카드 매칭 미니 게임 개발.

## 📂 Artifacts
- **Source Code**: 각 차수별 펌웨어 핵심 소스 (`1차/2차/3차 프로젝트 Zip`)
- **Reports**: 기술 이슈 및 구현 원리가 포함된 차수별 상세 최종 결과 보고서 (.docx, .pdf)
