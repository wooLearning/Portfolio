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

## 📂 Artifacts
- Modified xv6 Source Code
- Test Programs (`test_mlfq`, `test_nice`, etc.)
- Track-specific Reports
