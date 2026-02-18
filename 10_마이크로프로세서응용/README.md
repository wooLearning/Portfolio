# Microprocessor Application (ARM)
> ARM Image Conversion Optimization

## 📅 Project Info
- **Period**: 2025.04 ~ 2025.06
- **Device**: ARM Cortex-M based System
- **Stack**: `C` `ARM Assembly` `Keil MDK`

## 📝 Summary
32-bit RGBA 이미지를 처리하는 커널(Pixel Count, Grayscale, Negative)을 **ARM Assembly**로 최적화하여 구현했습니다.  
초기 C 구현 대비 성능을 높이기 위해 **Block Load/Store (`LDMIA`/`STMIA`)**, **Loop Unrolling** 등의 기법을 적용하였으며, Keil MDK를 통해 사이클 단위 성능을 측정/검증했습니다.

## 💡 Optimization Results
- **Optimization Strategy**: 메모리 접근 최소화(Register caching) 및 파이프라인 효율화.
- **Performance**:
    - Red Pixel Count: `2784 us` (C) → `660 us` (Opt-ASM)
    - Grayscale: `4225 us` (C) → `2833 us` (Opt-ASM)
    - Negative: `6336 us` (C) → `558 us` (Opt-ASM)

## 📂 Artifacts
- Source Code (`ma_project/source files`)
- Team Report and Presentation
