# FPGA Video Filtering (Ultra96-V2)
> Real-Time Video Filter Acceleration

## 📅 프로젝트 정보
- **기간**: 2025.09 ~ 2025.11
- **플랫폼**: `Ultra96-V2` (`Zynq UltraScale+ MPSoC`)
- **기술 스택**: `Verilog` `C` `AXI4-Lite` `Vivado`

## 📝 개요
**Ultra96-V2** 보드를 활용하여 카메라(OV5640) 영상을 실시간으로 필터링하는 시스템을 구현했습니다.  
PS(Processor)와 PL(FPGA) 영역을 나누어 설계한 HW/SW Co-design 프로젝트로, CPU 부하를 줄이면서 고속 영상 처리를 수행합니다.

## 2. 시스템 아키텍처 및 결과물 (Architecture & Output)
> **HW/SW Co-Design 구조**
- **PS (ARM Cortex-A53)**: AXI4-Lite를 통해 PL의 필터 모드/커널 레지스터를 실시간 제어하고, I2C 통신으로 OV5640 카메라 센서를 초기화합니다.
- **PL (FPGA)**: 카메라 입력을 `InBuf_Ctrl (Double Buffering)`로 수신 후 `Window3x3`에서 Line Buffer를 거쳐 3x3 픽셀 공간을 생성합니다. `Conv3x3` 모듈에서 27개 MAC 연산기로 병렬 처리하여 1-Cycle 연산을 달성하고 `LcdCtrl`를 통해 12.5MHz 포맷으로 LCD 출력합니다.
> 🎞️ **설계 결과물 데모 (시연 동영상)**: [3조_FPGA_동작동영상.mp4](./3조_FPGA_동작동영상.mp4) (실시간 모드 스위칭 확인)
## 💡 주요 구현 사항
1.  **카메라-LCD 동기화 (Sync)**:
    - OV5640 카메라 입력 신호와 TFT-LCD 출력 신호 간의 **Timing Synchronization** 구현.
    - `HSYNC`, `VSYNC`, `DE` 신호를 정밀하게 제어하여 Frame Tearing 방지.
2.  **3x3 영상 필터 가속**:
    - **Window Buffer**: Line Buffer를 이용해 실시간 3x3 픽셀 윈도우 생성.
    - **Convolution Engine**: FPGA 하드웨어 로직으로 고속 연산 처리.
    - **AXI4-Lite 제어**: SW에서 실시간으로 필터 모드(Sharpen/Bypass) 변경.
3.  **성과**:
    - **81.97 FPS** 처리 성능 달성.

## 4. 🛠 핵심 문제 해결 및 트러블슈팅 (Trouble Shooting)
- **[이슈/문제 상황]**: 카메라 입력, PL 연산부(100MHz), TFT-LCD 출력단(12.5MHz)의 클럭 도메인 불일치 및 단일 메모리 접근 병목으로 인해 초반 설계에선 **8.25 FPS 수준의 심각한 Frame Drop 및 영상 깨짐(Tearing)** 현상이 발생했습니다.
- **[접근 방식 및 해결]**:
  - **Double Buffering 도입**: `InBuf_Ctrl`에 메모리 Bank 2개를 두어 카메라 수신(Write)과 시스템 전송(Read)을 교차 파이프라인으로 처리했습니다.
  - **병렬 아키텍처 개선 (1-Cycle Throughput)**: 기존 9개 연산기에서 RGB 각 채널별로 **총 27개의 MAC 연산기 및 3개의 ReLU 연산기를 병렬 배치**하여 Convolution 연산 소요를 크게 단축시켰습니다.
  - **Sync 동기화 (Latency Hiding)**: LCD의 Read State 동작 중 발생하는 Data 버퍼 오버라이트를 막기 위해 VSYNC 엣지 기반 프레임 드랍 로직을 적용하고, 2-Stage Synchronizer로 CDC에 의한 Metastability를 예방했습니다. 
- **[결과]**: 프레임 찢어짐 현상과 색상 반전 장애를 완벽히 해결하고, 기존 대비 **약 9.93배 향상된 81.97 FPS의 실시간 고속 영상 병렬 처리**를 안정적으로 달성했습니다.

## 📂 산출물
- **RTL Source**: `RTL/` (Verilog 모듈)
- **Driver Code**: `CdriverCode/` (Vitis 드라이버)
- **Demo**: `AIX2025_전자전시회.mp4` (참조용 동일 영상)
