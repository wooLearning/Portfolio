# AGV Refactoring Simulator
> C++20 simulation engine with Electron desktop UI

## 📅 프로젝트 정보
- **기간**: 2026.03
- **형태**: 시뮬레이터 아키텍처 리팩토링 / 데스크톱 앱화
- **기술 스택**: `C++20` `CMake` `Electron` `Vanilla JS` `IPC` `GoogleTest`
- **외부 저장소**: [BUJH99/AGV_REFACTORING](https://github.com/BUJH99/AGV_REFACTORING)

## 📝 개요
AGV(무인 운반차) 경로 계획 시뮬레이터를 **C++ 엔진 + Electron UI** 구조로 재정리한 프로젝트입니다.
웹 서버를 두는 방식이 아니라, 로컬 시뮬레이션 엔진을 child process로 실행하고 Electron이 이를 제어하는 구조로 설계해 데스크톱 시뮬레이터로 발전시켰습니다.

## 💡 핵심 포인트
1. **엔진과 UI의 분리**
   - 핵심 시뮬레이션 로직은 C++20 엔진에 두고, Electron은 렌더링과 사용자 상호작용만 담당하도록 분리했습니다.
2. **HTTP 대신 stdio IPC**
   - `contextBridge` 기반 preload 계층과 JSON Lines over stdio 통신을 사용해 renderer가 백엔드 상태를 안전하게 조회/제어하도록 구성했습니다.
3. **시뮬레이션 운영 기능 강화**
   - 맵/시나리오 모드, planner 전략(`default`, `astar`, `dstar`), metrics, structured log, debug snapshot을 포함해 실험과 분석이 가능한 구조로 확장했습니다.
4. **실행 및 검증 흐름 정리**
   - one-click launcher, CMake 기반 빌드, GoogleTest/CTest 검증 흐름을 포함해 개발-실행-회귀 확인 사이클을 다듬었습니다.

## 🧩 포트폴리오 관점
- 기존 AGV 알고리즘 프로젝트를 **아키텍처 관점에서 다시 설계한 확장 작업**으로 볼 수 있습니다.
- 알고리즘 구현 자체를 넘어서, 엔진/렌더러/IPC 경계를 명확히 나누고 데스크톱 도구로 운영 가능한 형태로 개선한 점이 핵심입니다.

## 🔗 바로가기
- **[원본 GitHub 저장소 보기](https://github.com/BUJH99/AGV_REFACTORING)**

## 📌 참고
- 이 페이지는 포트폴리오용 요약입니다.
- 상세한 렌더 구조, planner 설명, IPC 계약, 테스트 구성은 외부 저장소 `README`와 소스 코드에서 확인할 수 있습니다.
