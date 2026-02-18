# 형남과학상: Multi-AGV 주차 경로 계획
> Hyeongnam Science Award (Bronze Prize)

## 📅 Project Info
- **Period**: 2025
- **Award**: **동상 (Bronze Prize)**
- **Stack**: `C` `Algorithms` `Simulation`

## 📝 Summary
밀집된 주차 공간에서 다수의 무인 운반 차량(AGV)이 충돌 없이 이동하도록 **경로 계획 및 교착 상태(Deadlock) 해결 알고리즘**을 C언어로 시뮬레이션한 프로젝트입니다.  
`A*`, `D* Lite` 등 기존 알고리즘과 **Hybrid WHCA* + CBS** 방식을 비교 검증하였으며, SCC(Strongly Connected Components) 기반의 Deadlock 감지 및 해소 로직을 구현했습니다.

## 💡 Key Algorithms
- **Pathfinding**: A* (Static), D* Lite (Dynamic), WHCA* (Time-Window).
- **Deadlock Handling**: SCC(강한 연결 요소) 탐색을 통한 순환 대기 감지 및 회피.
- **Simulator**: Map 편집, 실시간 차량 추가, 충돌/회전 제약 검증 (Windows Console).

## 📂 Artifacts
- `agv_simul.c`: 시뮬레이터 소스 코드
- `졸업논문_우상욱.pdf`: 상세 논문
- `agv_simul.exe`: 실행 바이너리
