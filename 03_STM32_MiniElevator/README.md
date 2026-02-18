# STM32 Mini Elevator Controller

## 📅 Project Info
- **Period**: 2024
- **Platform**: `STM32 Nucleo`
- **Language**: `C` (Embedded)
- **Stack**: `GPIO` `Step Motor` `7-Segment`

## 📝 Summary
STM32 Nucleo 보드를 활용하여 **3층 엘리베이터 시스템**을 모사한 임베디드 제어 프로젝트입니다.  
층별 버튼 입력(Hall/Car), 스텝 모터 구동, 7-세그먼트 층수 표시를 연동하며, SCAN 알고리즘과 유사한 **요청 우선순위 스케줄링**을 구현하여 효율적인 이동을 처리했습니다.

## 💡 Key Features
- **Scheduling**: 진행 방향 요청 우선 처리 + 대기 요청 큐 관리.
- **Motor Control**: Step Motor 드라이버 제어 (가감속 및 위치 제어).
- **IO Handling**: Hall Up/Down 버튼 및 내부 층 버튼 디바운싱 처리.

## 📂 Artifacts
- Source: `elevator_final.c` (Final version with scheduling)
- Specs: Project PDF/PPT
