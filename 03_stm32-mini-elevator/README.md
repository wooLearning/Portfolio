# STM32 Mini Elevator Controller

## 📅 Project Info
- **Period**: 2024.08 ~ 2024.11
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

## 🛠 Leadership & Learnings
- **지식 공유 및 프로젝트 리딩**: 하드웨어 제어 및 펌웨어 개발에 익숙하지 않은 후배 팀원들을 리딩하며 프로젝트를 완수했습니다. 일방적으로 개발을 전담하는 대신, 마이크로컨트롤러(MCU) 기초 지식과 임베디드 관련 양질의 강의를 선별하여 제공하고, 각자 소화할 수 있는 단계별 과제를 분배했습니다.
- **성장과 팀워크**: 기술적 리더십을 발휘하여 협업을 구체화했던 값진 경험입니다. 팀원을 교육하고 리딩하며 저 스스로도 부족했던 STM32 주변장치 기술들을 심도 있게 다잡을 수 있었습니다.

## 📂 Artifacts
- Source: `elevator_final.c` (Final version with scheduling)
- Specs: Project PDF/PPT
