# Microprocessor Application: ARM Image Conversion Optimization

A team project focused on implementing and optimizing image conversion kernels using C and ARM assembly with Keil MDK.

## 1. Portfolio Snapshot
- Category: Major project (Microprocessor Application)
- Period: **2025.04.24 to 2025.06.08**
- Date reference: root experience CSV
- Team report: `Report_7 team` document set

## 2. Project Scope
Input format: 32-bit RGBA image data

Implemented kernels:
- red pixel count (`R >= 128`)
- RGB negative conversion
- 16-bit grayscale conversion (`3R + 6G + B`)

## 3. Optimization Flow
1. baseline C implementation
2. ARM assembly implementation
3. memory relocation
4. ARM code-level optimization
   - block load/store (`LDMIA/STMIA`)
   - loop unrolling
   - bitwise instruction optimization

## 4. Measured Results (from report)
- Count Red: C `2784 us`, ASM `1728 us`, optimized ASM `660.66 us`
- Convert Gray: C `4225 us`, ASM `4032 us`, optimized ASM `2833 us`
- Convert Reverse: C `6336 us`, ASM `5760 us`, optimized ASM `558.62 us`

## 5. Main Evidence
- project overview PDF
- full team report PDF and DOCX
- source files under `ma_project_dj__0524/source files`

## 6. Tech Stack
- Language: `C`, `ARM assembly`
- Tool: `Keil MDK`
- Topics: low-level optimization, memory layout, performance analysis
