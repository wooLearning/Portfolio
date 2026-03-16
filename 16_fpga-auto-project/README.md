# FPGA Automation Toolkit
> Windows-first Verilog/SystemVerilog workflow automation toolkit

## 📅 프로젝트 정보
- **기간**: 2026.02 ~ 2026.03
- **형태**: FPGA 개발 환경 자동화 / Vivado workflow 개선
- **기술 스택**: `Batch` `PowerShell` `Python` `Node.js` `Vivado Tcl` `Icarus Verilog` `Yosys`
- **협업 형태**: 동료와 Git 기반 협업
- **외부 저장소**: [BUJH99/FPGA_Auto_Project](https://github.com/BUJH99/FPGA_Auto_Project)

## 📝 프로젝트 개요
이 프로젝트는 Vivado GUI에서 반복적으로 수행하던 작업을 `MAIN.bat` 중심의 메뉴형 실행 흐름으로 묶은 **FPGA 자동화 툴킷**입니다.
프로젝트 생성, hierarchy 분석, schematic/FSM 시각화, 시뮬레이션, waveform 변환, 빌드, 보고서 생성까지 HDL 개발 과정 전반을 자동화하는 데 초점을 맞췄습니다.

## 🧩 주요 기능 분석
### 1. 프로젝트 생성 자동화
- `project_create.bat` 기반으로 신규 프로젝트의 기본 폴더 구조와 `fpga_auto.yml` manifest를 자동 생성합니다.
- `src`, `tb`, `output`, `log`, `constrs`, `ip`, `Presentation` 등 FPGA 프로젝트에서 반복적으로 만드는 구조를 표준화했습니다.
- 신규 프로젝트 시작 시 동일한 구조를 빠르게 재사용할 수 있습니다.

### 2. Hierarchy 분석 기능
- `Browse HDL Hierarchy` 기능으로 Verilog/SystemVerilog 파일의 상하위 모듈 관계를 빠르게 확인할 수 있습니다.
- 모듈 연결 구조를 콘솔에서 바로 탐색할 수 있어 대형 RTL 구조 파악이 쉬워집니다.

### 3. Schematic / Block Diagram 시각화
- `Draw Schematic` 기능은 Yosys 기반으로 RTL을 파싱해 SVG 회로도를 생성합니다.
- 주요 연결 구조를 문서화된 그림 형태로 빠르게 확인할 수 있습니다.
- block diagram 성격의 구조 자료를 자동으로 정리하는 데 활용할 수 있습니다.

### 4. FSM 자동 추출 및 시각화
- `Draw FSM` 기능으로 상태기계를 자동으로 추출하고 state transition diagram 형태로 정리합니다.
- 제어 로직의 상태 전이 흐름을 문서화된 형태로 바로 확인할 수 있습니다.

### 5. 시뮬레이션 자동화
- Vivado GUI 시뮬레이션과 NO-GUI 배치 시뮬레이션을 모두 지원합니다.
- `Auto Sim + Report`, `Run Vivado Simulation`, `NO GUI Run Vivado Simulation`, `Run Iverilog VCD` 같은 기능으로 상황에 맞는 검증 경로를 선택할 수 있습니다.
- 반복 테스트와 회귀 검증을 일관된 절차로 실행할 수 있습니다.

### 6. Waveform / 결과 시각화 자동화
- VCD 기반 waveform을 SVG나 WaveDrom JSON으로 변환하는 기능을 포함했습니다.
- 파형 결과를 보고서나 발표 자료에 바로 활용 가능한 형태로 변환할 수 있습니다.

### 7. 빌드 및 보드 적용 자동화
- `Run Vivado Build Flow`, `Auto Build + Program`, `Program FPGA Device` 흐름으로 합성, 구현, 비트스트림 생성, 보드 프로그래밍을 연결했습니다.
- 합성부터 bitstream 생성, FPGA 적용까지 표준화된 실행 흐름으로 처리할 수 있습니다.

### 8. 문서 / 보고서 생성 자동화
- `Report Generator`, `Docs Generator`, `Generate Presentation` 기능으로 로그와 소스 정보를 기반으로 HTML/Markdown 보고서를 생성합니다.
- 합성/타이밍/파워 결과와 diagram/FSM 자료를 자동으로 정리할 수 있습니다.
- `Presentation\presentation_<project>_<timestamp>.html` 형태의 발표용 산출물도 생성할 수 있습니다.

### 9. 프로젝트 상태 점검 기능
- `Toolkit Doctor`로 manifest, 파일 경로, 테스트벤치 이름, 필수 도구 설치 상태를 한 번에 점검합니다.
- 장시간 시뮬레이션이나 빌드 전에 환경 문제를 빠르게 점검할 수 있습니다.

## 🏗 구조적 특징
- `MAIN.bat`를 최상위 메뉴 계약으로 두고 각 기능을 명확한 entrypoint로 연결했습니다.
- `code_intel`, `simulation`, `reporting`, `vivado`, `project_bootstrap`, `manifest`, `shared` 컨텍스트로 역할을 분리했습니다.
- 기능 추가와 유지보수를 고려한 구조로 정리했습니다.

## 🚀 이 프로젝트에서 드러나는 역량
- Vivado GUI 작업을 Tcl/스크립트 기반 자동화 흐름으로 재구성하는 능력
- hierarchy, schematic, FSM, waveform, report를 하나의 개발 체계로 묶는 설계 능력
- HDL 개발 과정 전체를 표준화된 도구 형태로 정리하는 역량

## 🧩 포트폴리오 관점
- 이 프로젝트는 RTL 설계 결과물보다 **설계 환경과 workflow 자체를 개선한 프로젝트**에 가깝습니다.
- Vivado 기반 FPGA 개발에서 자주 반복되는 작업을 자동화하고, 결과 정리까지 연결한 점이 핵심입니다.

## 🔗 바로가기
- **[원본 GitHub 저장소 보기](https://github.com/BUJH99/FPGA_Auto_Project)**

## 📌 참고
- 이 페이지는 포트폴리오용 요약입니다.
- 실제 메뉴 구성, 배치 스크립트, Tcl/Vivado 연동, diagram/FSM/report 생성 흐름은 외부 저장소에서 확인할 수 있습니다.
