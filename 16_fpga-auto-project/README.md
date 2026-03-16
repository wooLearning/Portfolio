# FPGA Automation Toolkit
> Windows-first Verilog/SystemVerilog workflow automation toolkit

## 📅 프로젝트 정보
- **기간**: 2026.02 ~ 2026.03
- **형태**: 개인 개발 툴링 / FPGA workflow automation
- **기술 스택**: `Batch` `Python` `Node.js` `Vivado` `Icarus Verilog` `Yosys`
- **외부 저장소**: [BUJH99/FPGA_Auto_Project](https://github.com/BUJH99/FPGA_Auto_Project)

## 📝 개요
Windows 환경에서 Verilog/SystemVerilog 프로젝트의 반복 작업을 줄이기 위해 만든 **메뉴 기반 FPGA 자동화 툴킷**입니다.
`MAIN.bat`를 중심으로 프로젝트 탐색, 시뮬레이션, Vivado 빌드, 회로도 생성, 문서화, 리포트 생성을 하나의 흐름으로 묶어 HDL 개발 생산성을 높이는 데 초점을 맞췄습니다.

## 💡 핵심 포인트
1. **메뉴 기반 실행 흐름**
   - `MAIN.bat`에서 프로젝트를 선택하고, 시뮬레이션/리포트/빌드/프로그래밍 같은 작업을 일관된 UX로 실행할 수 있도록 구성했습니다.
2. **DDD 스타일 구조화**
   - `templates/contexts/*` 아래에 `code_intel`, `simulation`, `vivado`, `reporting`, `manifest`, `project_bootstrap` 컨텍스트를 분리해 기능 확장성과 유지보수성을 높였습니다.
3. **HDL 개발 자동화 통합**
   - Vivado GUI/NO-GUI 시뮬레이션, Icarus Verilog VCD 생성, Yosys 기반 schematic/FSM 시각화, 문서/HTML 리포트 생성을 한 저장소 안에서 연결했습니다.
4. **운영 보조 기능**
   - `Toolkit Doctor`로 프로젝트 상태를 점검하고, Telegram bot 인터페이스까지 연결해 원격 실행/결과 확인 흐름도 지원합니다.

## 🧩 포트폴리오 관점
- HDL 설계 자체뿐 아니라 **설계 생산성을 높이는 도구를 직접 만든 경험**을 보여주는 프로젝트입니다.
- FPGA 프로젝트가 커질수록 반복되는 시뮬레이션/빌드/문서화 작업을 자동화했다는 점에서, 단순 RTL 작성 이상의 개발 환경 설계 역량을 드러냅니다.

## 🔗 바로가기
- **[원본 GitHub 저장소 보기](https://github.com/BUJH99/FPGA_Auto_Project)**

## 📌 참고
- 포트폴리오에서는 핵심 성격만 요약했습니다.
- 실제 스크립트 구조, 메뉴 흐름, 배치 자동화 구현은 외부 저장소에서 확인할 수 있습니다.
