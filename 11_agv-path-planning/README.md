# AGV Parking Algorithm
> Multi-Agent Path Finding & Deadlock Resolution

## 📅 프로젝트 정보
- **Period**: 2025.03 ~ 2025.11
- **수상**: 제 43회 형남과학상 **동상 (Bronze Prize)**
- **기술 스택**: `C` `Algorithms` `Simulation`

## 📝 개요
과밀한 주차 공간에서 다수의 무인 운반 차량(AGV)이 충돌 없이 효율적으로 이동하도록 돕는 **경로 계획(Path Planning) 및 교착 상태(Deadlock) 해결 시뮬레이션** 프로젝트입니다.  
기존의 `A*`, `D* Lite`, `WHCA*` 등 다양한 경로 탐색 알고리즘을 비교 분석하고, 특히 좁은 골목길에서의 교착 상태를 해결하기 위해 **SCC (Strongly Connected Components)** 기반의 순환 대기 감지 및 회피 로직을 구현했습니다.

## 2. 시스템 아키텍처 및 결과물 (Architecture & Output)
> *(시뮬레이터 구동 GIF 추후 추가 예정)*
![AGV 시뮬레이터 데모]()

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

## 4. 🛠 핵심 문제 해결 및 트러블슈팅 (Trouble Shooting)
- **[이슈/문제 상황]**: 주차 공간이 부족하고 회전 반경이 좁은 고밀도 환경(Map 3: 주차면 900개, AGV 8대)에서 다중 에이전트들이 얽히며 발생하는 심각한 **순환성 교착 상태(Cycle Deadlock)** 가 기존의 단순 회피(Wait) 알고리즘으로는 임계점에 도달해 시뮬레이션 전체 정지로 이어지는 문제 발생.
- **[접근 방식 및 해결]**:
  - **Deadlock 탐지 구조화**: 현재 시스템의 대기 상태를 나타내는 `WFG (Wait-For Graph)` 자료구조를 구축하고, `Tarjan's SCC (Strongly Connected Components)` 알고리즘을 도입해 크기 2 이상의 Cycle Group(교착 상태의 주범)을 수학적으로 정확히 식별했습니다.
  - **Partial CBS 협상 및 우회 적용**: 교착 상태로 묶인 그룹 내부에서 국소적으로 Conflict-Based Search(CBS) 알고리즘을 가동하여 가장 충돌 Cost가 낮은 대체 경로를 재탐색했습니다. 이조차 실패할 경우, 최상위 우선순위 리더 차량을 제외한 다른 차량들을 강제로 `Pull-over (한 칸 후진/우회)` 하도록 Rule을 최적화했습니다.
- **[결과]**: 고밀도 환경에서 일반적인 A*나 D* Lite가 처리 불가했던 복합 충돌 상황을 100% 감지 후 해소해냄으로써 맵 내 시뮬레이션 중단 확률을 없애고, 다수의 AGV가 멈춤 없이 경로에 투입될 수 있는 연산 속도와 안전성을 증명했습니다.## 📂 산출물
- **Simulation Code**: `agv_simul.c`
- **Paper**: 졸업논문 (AGV 경로 계획 알고리즘 비교 및 최적화)
- **Executable**: `agv_simul.exe`

## 5. 💡 배운 점 및 개선 방향 (Lessons Learned)
- **언어 선택의 한계와 고차원 제어에 대한 고찰**: 전자공학도로서 로우레벨 제어와 MCU 최적화를 염두에 두고 C언어로 알고리즘과 시뮬레이터를 모두 설계했습니다. 하지만 다중 에이전트 환경이나 복잡한 경로 탐색 같은 고수준의 알고리즘을 제어해본 결과, 객체지향이 더 강력한 C++ 계열이나 연구 효율이 높은 Python이 더 적합했을 것이란 점을 깨달았습니다.
- **확장성**: 추후 로봇 제어 시스템에서 ROS 환경 구축이나 SLAM 알고리즘 연동까지 프로젝트를 확장하려면, C++이나 Python과 같은 상위 수준의 인터페이스 언어 도입이 뼈대가 되어야 함을 현업 관점에서 크게 배우는 계기가 되었습니다.
