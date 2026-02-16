# 형남과학상 동상: Multi-AGV 주차 경로 계획 및 데드락 해소
# Bronze Prize at Hyeongnam Science Award: Multi-AGV Parking and Deadlock Handling

## 1. 수상 정보 | Award Information
- 수상명 / Award: `형남과학상 동상 (Bronze Prize)`
- 수여기관 / Institution: `숭실대학교 공과대학 (Soongsil University College of Engineering)`
- 수상연도 / Year: `2025`
- 수상 내용 / Summary: AGV 기반 무인 주차장 설계를 주제로 졸업논문 제출 및 PT 발표

## 2. 한국어 요약 | Korean Summary
밀집 주차 환경에서 다수 AGV의 경로 충돌과 교착(Deadlock)을 줄이기 위해 C 기반 시뮬레이터를 설계했습니다.  
기본 경로탐색(`A*`, `D* Lite`)과 하이브리드 전략(`WHCA* + WFG(SCC) + Partial CBS + 우선순위 fallback`)을 비교하며, 고밀도 시나리오에서의 안정적 이동을 목표로 검증했습니다.

## 3. English Summary
This project implements a C-based simulator for multi-AGV parking in dense maps.  
It compares baseline planners (`A*`, `D* Lite`) with a hybrid policy (`WHCA* + WFG(SCC) + Partial CBS + priority fallback`) to reduce conflicts and recover from deadlock in high-contention traffic.

## 4. 구현 핵심 | Key Engineering Points
- 동적 우선순위 정책으로 정체 차량의 진행 기회를 보장
- 점유 충돌 및 회전 충돌을 고려한 안전 이동 규칙 적용
- WFG/SCC 기반 순환 교착 감지 및 해소 로직 구현
- 혼잡 구간에서 지역 협상(local negotiation)과 fallback 동작 설계

## 5. 시뮬레이터 기능 | Simulator Features
- 맵 시나리오: `Map 1` ~ `Map 5`
- 실행 모드: `Custom Mode`, `Real-Time Mode`
- 조작 키: `P`, `S`, `+`, `-`, `[`, `]`, `F`, `C`

## 6. 기술 스택 | Tech Stack
- Language: `C`
- Runtime: `Windows console`
- Algorithms: `A*`, `D* Lite`, `WHCA*`, `CBS`, SCC-based deadlock detection

## 7. 산출물 | Artifacts
- Source: `agv_simul.c`
- Binary: `agv_simul.exe`
- 발표자료(PDF/PPT), 사용자 가이드(PDF)

## 8. 실행 방법 | Build and Run
### Prebuilt 실행
- `agv_simul.exe` 실행

### MSVC 빌드
```bat
cl /O2 /W4 agv_simul.c /link psapi.lib
```

### MinGW 빌드 (선택)
```bash
gcc -O2 -Wall agv_simul.c -o agv_simul.exe -lpsapi
```
