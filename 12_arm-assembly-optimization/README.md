# ARM Assembly Optimization
> Microprocessor Application: Image Processing Optimization

## 📅 프로젝트 정보
- **기간**: 2025.04 ~ 2025.06
- **과목**: 마이크로프로세서 응용 (Microprocessor Application)
- **플랫폼**: ARM Cortex-M based System (Keil MDK)
- **기술 스택**: `C` `ARM Assembly` `Optimization`

## 📝 개요
32-bit RGBA 이미지를 처리하는 핵심 커널(Pixel Count, Grayscale, Negative)을 **ARM Assembly**로 직접 구현하고 최적화했습니다.  
C언어로 구현된 초기 버전 대비 성능을 극대화하기 위해 레지스터 캐싱, 루프 언롤링, LDM/STM 명령어 활용 등의 기법을 적용했습니다.

## 💡 주요 최적화 내용 (Optimization)
1.  **Register Caching**:
    - 메모리 접근(Load/Store)을 최소화하기 위해 연산에 필요한 데이터를 레지스터에 상주시켜 처리.
2.  **Block Data Transfer**:
    - `LDMIA` (Load Multiple Increment After) / `STMIA` 명령어를 사용하여 여러 레지스터를 한 번에 전송, 버스 효율 극대화.
3.  **Loop Unrolling**:
    - 루프 오버헤드(분기문, 조건 검사)를 줄이기 위해 루프 내부를 펼쳐서 병렬성 증대 및 파이프라인 효율 향상.

## 📊 성능 개선 결과 (Performance)
Keil Simulator를 통해 Cycle Count를 측정한 결과, C 코드 대비 **최대 11배** 성능 향상을 달성했습니다.

| Kernel Function     | C Implementation | Optimized Assembly | Speedup   |
| ------------------- | ---------------- | ------------------ | --------- |
| **Red Pixel Count** | `2,784 us`       | **`660 us`**       | **4.2x**  |
| **Grayscale Conv**  | `4,225 us`       | **`2,833 us`**     | **1.5x**  |
| **Negative Filter** | `6,336 us`       | **`558 us`**       | **11.3x** |

## 📂 산출물
- **Source Code**: `source/`
- **Docs**: 최적화 보고서 및 발표 자료
