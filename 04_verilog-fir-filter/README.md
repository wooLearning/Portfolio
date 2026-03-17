# Digital System Design (FIR Filter)
> Hardware FIR Filter with Kaiser Window

## 📅 Project Info
- **Period**: 2024.11
- **Target**: `DSD HW Project`
- **Stack**: `Verilog-HDL` `ModelSim` `Vivado`

## 📝 Summary
Kaiser Window를 적용한 **79-tap FIR Filter**를 하드웨어로 설계하고 검증한 프로젝트입니다.  
Coefficient Update 모드와 Filtering 모드를 분리하여 FSM 기반으로 제어하며, 대칭 구조(Symmetric structure)를 활용한 Coefficient Folding 기법으로 메모리와 연산 자원을 최적화했습니다.

## 💡 Technical Highlights
- **Architecture**: 4-Parallel Multiplier/Accumulator + SRAM(Coefficient Storage).
- **Optimization**: Coefficient Folding으로 곱셈기 사용량 절감.
- **Verification**: ModelSim을 통한 RTL 시뮬레이션 및 Vivado 합성 검증.

## 📂 Artifacts
- RTL Sources (`HW_based_FIR/Src/`) & Testbench (`HW_based_FIR/tb/`)
- Final Report & Presentation
