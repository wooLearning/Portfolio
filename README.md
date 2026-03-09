# 👨‍💻 우상욱 (Sang-Wook Woo)
> "탄탄한 하드웨어 이해도를 바탕으로 디지털 회로 설계 및 검증, 그리고 임베디드 시스템 개발을 주도하는 엔지니어로 성장하고 싶습니다."

> 📧 Email: wu3643@gmail.com | 🐙 GitHub: @wooLearning | 🔗 OPIc: Intermediate High

## 💡 About Me
- **디지털 회로 설계 및 검증**: Verilog를 이용한 AMBA 버스(AXI4/APB), CNN 가속기, 그리고 AES 암호화 모듈 등 FPGA 환경에서의 HW 설계 및 검증 역량 보유
- **임베디드 시스템 최적화**: C/Assembly 기반의 RTOS(xv6) 환경 및 STM32, Zynq MCU를 활용한 저수준 하드웨어 제어와 HW/SW Co-design 경험
- **목표 지향적 문제 해결**: 한정된 자원(FPGA 로직 등)과 타이밍 이슈(CDC)를 극복하며, 펌웨어와 하드웨어 간의 병목 현상을 해결하는 로우레벨 엔지니어링을 지향합니다.

## 🛠 Tech Skills
- **Hardware/FPGA**: `Verilog HDL`, `AMBA (AXI, APB)`, `Xilinx Zynq`
- **Embedded/System**: `C/C++`, `ARM Assembly`, `RTOS(xv6)`, `STM32`
- **Tools**: `Cadence Virtuoso`, `OrCAD`, `PSpice`, `ModelSim`, `Keil`

## 🌟 Featured Projects
> 제 핵심 역량이 가장 잘 녹아있는 중요 프로젝트입니다.

### 1. AXI4 to APB Bridge IP Design (인턴십)
*High-speed AXI 트랜잭션을 저속 APB 버스로 안정적으로 변환하는 브릿지 회로 설계*
- **기간**: 2026.01 / **역할**: 하드웨어 설계 인턴
- **기술**: `Verilog`, `AMBA Protocol`
- **핵심 기여**: 
  - AXI4 Burst Transaction을 분할하여 개별 APB Single Transfer로 변환하는 FSM 구현
  - 4-Slave 모듈에 대한 PSEL 디코딩 로직 설계 및 Waveform 자체 검증 통과
- ➡️ **[👉 상세 문서 및 트러블슈팅 보기](./15_axi2apb-bridge)**

### 2. AGV Path Planning & Deadlock Resolution (🏆 형남과학상 동상)
*물류 창고 등 과밀 환경의 AGV간 교착상태 탐지 및 경로 최적화 시뮬레이터*
- **기간**: 2025.03 ~ 2025.11
- **사용 기술**: `C`, `A* / D* Lite`, `Tarjan's SCC Algorithm`
- **주요 성과**:
  - WHCA*, WFG/SCC, Partial CBS를 결합한 협력 경로계획 방식을 적용하여 과밀도 맵에서의 타임라인 최적화
  - 실제 주차장 및 확장 맵 환경에서 교착 발생을 회피하고 고밀도 운용 환경의 연산 효율 검증 완료
- ➡️ **[👉 데모 및 상세 보기](./11_agv-path-planning)**

### 3. FPGA Video Filtering 가속기 설계
*카메라 실시간 입력(Streaming image)을 받아 CNN 1-Layer 연산을 FPGA 하드웨어로 가속하여 디스플레이하는 HW/SW Co-design 프로젝트*
- **기간**: 2025.09 ~ 2025.11
- **기술**: `Verilog HDL`, `Ultra96-V2(Zynq)`, `C (MCU Control)`
- **핵심 기여**:
  - HW(FPGA 로직)와 SW(MCU 제어)를 통합 연동하여 81.97 FPS 고속 영상 처리 성능 확보
  - CDC(Clock Domain Crossing) 및 Frame drop 문제를 해소하기 위한 Window logic 변경 등 트러블슈팅 완료
- ➡️ **[👉 상세 문서 및 트러블슈팅 보기](./14_fpga-video-filtering)**

## 🗂 Archive & Other Projects
<details>
<summary><b>더 많은 프로젝트 열어보기 (Click)</b></summary>

| 프로젝트명 | 한 줄 소개 | 기간 | 기술 스택 | 링크 |
| --- | --- | --- | --- | --- |
| **AIX 2025 하드웨어 경진대회** | 딥러닝 하드웨어 가속기 구조 설계(장려상) | 2025.02~06 | `Verilog` `AI Accelerator` | [Link](./08_aix2025-dl-hw-contest) |
| **PCB Design & OrCAD** | OrCAD를 활용한 PCB 회로 설계 구현 | 2025.07 | `OrCAD` `PCB Editor` | [Link](./13_pcb-design-orcad) |
| **ARM Assembly Optimization** | ARM 아키텍처 타겟 어셈블리 코드 최적화 | 2025.04~06 | `ARM` `Assembly` | [Link](./12_arm-assembly-optimization) |
| **xv6 Kernel Implementation** | C 기반 교육용 운영체제 xv6 기능 구현 및 분석 | 2025.03~06 | `C` `Kernel` | [Link](./10_xv6-kernel-implementation) |
| **SIC/XE Assembler Simulator** | SIC/XE 어셈블러 및 시뮬레이터 개발 | 2025.03~06 | `Java` `Assembler` | [Link](./09_sic-xe-assembler-simulator) |
| **STM32 임베디드 소프트웨어** | STM32/AVR 기반 시스템 제어 | 2024.12~01 | `C` `STM32` | [Link](./06_embedded-sw-stm32) |
| **APB-AES Design (인턴십)** | APB 버스 기반 AES 암호화 모듈 설계 | 2024.12~01 | `Verilog` `AES` | [Link](./07_apb-aes-design) |
| **반도체 디스플레이 공정** | LDO 공정 관련 프로젝트 | 2024.11~12 | `Process` `LDO` | [Link](./05_semiconductor-display-process) |
| **Verilog FIR Filter Design** | FIR 필터 디지털 블록 설계 | 2024.11 | `Verilog` | [Link](./04_verilog-fir-filter) |
| **STM32 미니 엘리베이터** | 상태기반 엘리베이터 모터 제어 구현 | 2024.08~11 | `C` `Motor Control` | [Link](./03_stm32-mini-elevator) |
| **Full-Custom IC 설계** | Virtuoso를 활용한 아날로그/디지털 회로 레이아웃 | 2024.07~08 | `Cadence` `Virtuoso` | [Link](./02_full-custom-ic-design) |
| **IoT 출입제어 (캡스톤)** | 라즈베리파이 기반 비접촉 출입 제어(장려상) | 2021.06~07 | `Python` `RPi` | [Link](./01_iot-capstone-design) |

</details>

## 🏆 Awards & Honors
- **[2025.12] 형남과학상 동상 (Bronze Prize)** (숭실대학교 공과대학)
- **[2025.06] AIX 2025 딥러닝 하드웨어 경진대회 장려상** (서울대학교 차세대 반도체 사업단)
- **[2021.09] 2021 숭실 캡스톤디자인 경진대회 장려상** (숭실대학교)

## 💼 Activities & Internships
- **[2025.12 ~ 2026.01] 학부 연구생 인턴** (송인철 교수 연구실) - AXI-to-APB Bridge RTL 설계 및 검증
- **[2025.07] PCB Circuit Design & PSpice Designer 교육 수료** (60시간, 9ES Campus - Cadence 공인 교육장)
- **[2024.12 ~ 2025.01] 학부 연구생 인턴** (송인철 교수 연구실) - APB 버스 기반 AES 암호화 모듈 설계
- **[2024.07 ~ 2024.10] Full-Custom IC Design 과정 수료** (60시간, 숭실대학교) - Cadence Virtuoso 활용 레이아웃 설계
- **[2021.03 ~ 현재] 숭실대학교 전자전시회(SEE) 동아리 활동** - 신입생 C 프로그래밍 강사 및 팀 프로젝트 멘토링

## 📜 Certifications
- OPIc (IH) - 2025.03
- 컴퓨터활용능력 1급 - 2023.07
- 정보처리기능사 - 2019.05
