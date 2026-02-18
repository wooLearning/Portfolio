# FPGA Video Filtering (Ultra96-V2)
> Real-Time Video Filter Acceleration

## 📅 프로젝트 정보
- **기간**: 2025.09 ~ 2025.11
- **플랫폼**: `Ultra96-V2` (`Zynq UltraScale+ MPSoC`)
- **기술 스택**: `Verilog` `C` `AXI4-Lite` `Vivado`

## 📝 개요
**Ultra96-V2** 보드를 활용하여 카메라(OV5640) 영상을 실시간으로 필터링하는 시스템을 구현했습니다.  
PS(Processor)와 PL(FPGA) 영역을 나누어 설계한 HW/SW Co-design 프로젝트로, CPU 부하를 줄이면서 고속 영상 처리를 수행합니다.

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

## 📂 산출물
- **RTL Source**: `RTL/` (Verilog 모듈)
- **Driver Code**: `CdriverCode/` (Vitis 드라이버)
- **Demo**: `AIX2025_전자전시회.mp4` (참조용 동일 영상)
