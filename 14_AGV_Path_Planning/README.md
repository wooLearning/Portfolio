# AGV Parking Algorithm
> Multi-Agent Path Finding & Deadlock Resolution

## 📅 프로젝트 정보
- **기간**: 2025
- **수상**: 제 n회 형남과학상 **동상 (Bronze Prize)**
- **기술 스택**: `C` `Algorithms` `Simulation`

## 📝 개요
과밀한 주차 공간에서 다수의 무인 운반 차량(AGV)이 충돌 없이 효율적으로 이동하도록 돕는 **경로 계획(Path Planning) 및 교착 상태(Deadlock) 해결 시뮬레이션** 프로젝트입니다.  
기존의 `A*`, `D* Lite`, `WHCA*` 등 다양한 경로 탐색 알고리즘을 비교 분석하고, 특히 좁은 골목길에서의 교착 상태를 해결하기 위해 **SCC (Strongly Connected Components)** 기반의 순환 대기 감지 및 회피 로직을 구현했습니다.

## 💡 주요 알고리즘 (Key Algorithms)
1.  **Path Planning**:
    - **A* (Static)**: 정적 장애물 환경에서의 최단 경로 탐색.
    - **D* Lite (Dynamic)**: 동적 장애물 발생 시 경로 재탐색 효율화.
    - **WHCA* (Time-Window)**: 시간축(Time-Dimension)을 고려하여 차량 간 충돌 회피.
2.  **Deadlock Resolution**:
    - Multi-Robot 환경에서 발생하는 Cycle Deadlock을 **Tarjan's SCC Algorithm**으로 감지.
    - 우선순위 기반의 대기(Wait) 또는 우회(Detour) 명령 생성.
3.  **Simulator**:
    - Windows Console 기반의 그리드 맵 시뮬레이터 구현.
    - 실시간 차량 이동, 경로 시각화, 충돌 감지 테스트.

## 📂 산출물
- **Simulation Code**: `agv_simul.c`
- **Paper**: 졸업논문 (AGV 경로 계획 알고리즘 비교 및 최적화)
- **Executable**: `agv_simul.exe`
