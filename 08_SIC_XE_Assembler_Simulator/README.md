# SIC/XE Assembler & Simulator Implementation
> System Programming: Hand-crafted Assembler, Linker/Loader & Simulator

## 📅 프로젝트 정보
- **기간**: 2025.03 ~ 2025.06
- **과목**: 시스템 프로그래밍 (System Programming)
- **기술 스택**: `C` `Java` `SIC/XE Assembly`

## 📝 개요
가상의 **SIC/XE (Simplified Instructional Computer)** 아키텍처를 기반으로 시스템 소프트웨어의 핵심인 **Assembler, Linker/Loader, Simulator**를 밑바닥부터(from scratch) 구현했습니다.  
소스 코드가 기계어로 변환되고 메모리에 적재되어 최종 실행되는 컴퓨터 시스템의 전체 동작 원리를 완벽하게 이해하고 구현하는 것을 목표로 했습니다.

## 💡 주요 구현 내용
1.  **Two-Pass Assembler**:
    - **Pass 1**: 소스 코드를 스캔하여 `Symbol Table` 생성 및 주소 할당 (`LOCCTR`).
    - **Pass 2**: 명령어 포맷(Format 1~4)에 맞춰 기계어(Object Code) 생성.
2.  **Linking Loader**:
    - 여러 개의 Object Program을 메모리에 연결(Link) 및 적재(Load).
    - `ESTAB`을 활용한 외부 심볼(External Reference) 주소 해석(Relocation) 수행.
3.  **Instruction Simulator**:
    - 메모리에 로드된 프로그램을 실제 하드웨어처럼 실행.
    - **Fetch-Decode-Execute** 사이클 구현.
    - 레지스터(A, X, L, PC, SW 등) 상태 변화 추적 및 메모리 덤프/수정 기능.

## 📂 산출물
- **Source Code**:
    - `Assembler/` (C 및 Java 버전 구현)
    - `Simulator/` (Java 기반 GUI/CLI 시뮬레이터)
- **Docs**: 설계 보고서 및 실행 결과 보고서
