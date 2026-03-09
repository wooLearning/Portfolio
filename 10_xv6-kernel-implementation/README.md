# Operating Systems (xv6)
> xv6 Kernel Modification & Extension

## 📅 Project Info
- **Period**: 2025.03 ~ 2025.06
- **Category**: Major Project (Operating Systems)
- **Stack**: `C` `xv6` `Kernel`

## 📝 Summary
교육용 운영체제인 **xv6 커널**을 수정하여 스케줄러, 메모리 할당자, 동기화 요소를 직접 구현했습니다.  
기본적인 Round Robin 스케줄러를 **MLFQ(Multi-Level Feedback Queue)**로 개선하고, 효율적인 메모리 관리를 위해 **Slab Allocator**를 추가했으며, 프로세스 간 동기화를 위한 **Semaphore**를 개발했습니다.

## 💡 Assignment Tracks
1.  **Syscall Extension**: `getnice`, `setnice` 등 시스템 콜 추가 및 우선순위 제어.
2.  **Scheduling**: MLFQ(Multi-Level Feedback Queue) 스케줄러 구현 및 테스트 (`test_mlfq`).
3.  **Memory**: Slab Allocator (`slab.c`) 구현으로 커널 메모리 할당 최적화.
4.  **Synchronization**: Semaphore 기반의 동기화 메커니즘 및 Producer-Consumer 패턴 구현.

## 🛠 Learnings & Insights
- **하드웨어와 소프트웨어의 교두보 이해**: 단순한 애플리케이션(Application) 레벨의 프로그래밍을 넘어, 하드웨어와 맞닿아 있는 운영체제(System Software)의 전반적인 구조를 학습하는 계기가 되었습니다.
- **로우 레벨 자원 관리 철학 습득**: 메모리 할당, 스케줄링 로직(MLFQ 등) 변경, 그리고 프로세스 간 Context Switching 및 동기화 기법을 직접 수정해 보며, 한정적 자원을 안정적으로 통제하는 아키텍처적 사고방식의 중요성을 크게 깨달았습니다.

## 📂 Artifacts
- Modified xv6 Source Code
- Test Programs (`test_mlfq`, `test_nice`, etc.)
- Track-specific Reports
