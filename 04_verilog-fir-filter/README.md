# Verilog-HDL 기반 79-tap FIR Filter 설계
> Kaiser window 기반 79-tap FIR filter를 Verilog-HDL로 구현하고, coefficient update와 filtering 동작을 지원하는 synthesizable datapath를 설계한 전공 팀 프로젝트입니다.

## Project Info

| 항목 | 내용 |
|---|---|
| 기간 | `2024.11` |
| 유형 | 전공 팀 프로젝트 / Verilog-HDL 기반 FIR Filter 설계 |
| 역할 | Delay chain, multiplier/accumulator datapath, coefficient RAM 연동 구조 설계 및 검증 |
| 언어/도구 | `Verilog-HDL` `ModelSim` `Vivado` |
| Core Keywords | `79-tap FIR` `Coefficient Folding` `Delay Chain` `4-Parallel MAC` `SRAM Coefficient Storage` |

## Summary

79-tap FIR Filter를 Verilog-HDL로 구현하고, coefficient update 모드와 filtering 모드를 분리해 제어하는 RTL 구조를 설계했습니다. FIR coefficient가 대칭이라는 점을 활용해 전체 79개 tap을 모두 저장하고 곱하는 대신, 40개 coefficient만 저장한 뒤 `x[0] + x[78]`처럼 대칭 sample을 먼저 더해 곱셈에 사용하는 coefficient folding 구조를 적용했습니다.

처음 Verilog-HDL을 배우며 진행한 프로젝트였지만, 단순 조합회로가 아니라 SRAM, delay chain, multiplier, accumulator, controller가 clock에 맞춰 함께 동작하는 datapath를 구현하고 waveform으로 검증했다는 점에서 RTL 설계 흐름을 익히는 기반이 되었습니다.

## Architecture

전체 top은 [FirTop.v](./HW_based_FIR/Src/FirTop.v)이며, 주요 구성은 다음과 같습니다.

- [controller.v](./HW_based_FIR/Src/controller.v): coefficient update와 filtering 연산 sequence를 제어합니다.
- [SpSram.v](./HW_based_FIR/Src/SpSram.v): coefficient 저장용 single-port SRAM입니다.
- [delayChain.v](./HW_based_FIR/Src/delayChain.v): 79-depth sample delay line을 구성합니다.
- [Multiplier.v](./HW_based_FIR/Src/Multiplier.v): coefficient와 symmetric sample sum을 곱합니다.
- [Accumulator.v](./HW_based_FIR/Src/Accumulator.v): partial sum을 누적합니다.
- [Sum.v](./HW_based_FIR/Src/Sum.v): 4개의 parallel MAC 결과를 최종 합산합니다.

```text
iFirIn
  -> 79-depth Delay Chain
  -> Symmetric Sample Add
  -> 4-Parallel Multiplier/Accumulator
  -> Sum
  -> oFirOut
```

## Datapath Strategy

### 1. Symmetric Coefficient Folding

79-tap FIR는 일반적으로 79개의 delayed sample과 79개의 coefficient 곱이 필요합니다. 이 프로젝트에서는 대칭 coefficient를 활용해 `h[k] == h[78-k]`인 항을 묶고, 먼저 sample을 더한 뒤 하나의 coefficient와 곱했습니다. 그 결과 coefficient 저장 개수를 40개로 줄이고 multiplier 입력 구조도 단순화했습니다.

### 2. Coefficient RAM 분할

RTL에서는 coefficient 40개를 10-depth SRAM 4개로 나누어 관리했습니다. [FirTop.v](./HW_based_FIR/Src/FirTop.v) 안에서 `SpSram0 ~ SpSram3`를 instantiation하고, controller가 RAM 선택과 address를 제어합니다. 이 구조는 한 번에 여러 coefficient를 병렬로 읽어 4-parallel MAC 구조와 맞물리도록 구성한 것입니다.

### 3. 4-Parallel MAC

`Multiplier`와 `Accumulator`를 4개 lane으로 구성해 40개 folded coefficient를 순차적으로 처리합니다. controller는 `p_StMul`, `p_StAdd`, `p_EdMul`, `p_EdAdd`, `p_Sum` 상태를 거치며 곱셈, 누산, 최종 합산 타이밍을 맞춥니다.

### 4. Update / Filtering Mode 분리

coefficient update 시에는 SRAM write path를 사용하고, filtering 시에는 delay chain의 sample과 SRAM coefficient를 읽어 MAC 연산을 수행합니다. 이 분리 덕분에 filter coefficient를 외부에서 바꾸는 구조와 실제 filtering datapath를 한 top 안에서 다룰 수 있었습니다.

## Verification

검증은 [tb_FirTop.v](./HW_based_FIR/tb/tb_FirTop.v)를 통해 진행했습니다.

- coefficient update sequence 확인
- 79-depth delay chain이 clock마다 sample을 전달하는지 확인
- folded sample pair와 coefficient 곱셈 결과 확인
- 4개 MAC lane의 누산 및 최종 sum 확인
- ModelSim waveform 기반 filtering output 확인
- Vivado synthesis를 통해 synthesizable RTL 여부 확인

PDF 포트폴리오에서는 `Peak coeff: 32000`, `-32000`, `96000`, `-96000` 등 coefficient 조합별 simulation 결과를 정리했습니다.

## Trouble Shooting

처음에는 testbench를 직접 작성하고 waveform으로 내부 state와 datapath를 동시에 보는 과정이 가장 어려웠습니다. 특히 coefficient RAM write timing, delay chain sample index, accumulator clear/update timing이 어긋나면 최종 출력만 봐서는 원인을 찾기 어려웠습니다. 이를 해결하기 위해 controller state, RAM address, multiplier input, accumulator output을 waveform에 함께 올려 각 clock에서 데이터가 어디에 있는지 확인했습니다.

이 과정을 통해 RTL 설계에서는 "수식이 맞는가"만큼이나 "clock boundary에서 data/control이 같은 beat에 만나는가"가 중요하다는 점을 배웠습니다.

## ETRI Portfolio Focus

- RTL 설계 관점: synthesizable datapath, controller FSM, SRAM 연동
- DSP 관점: 79-tap FIR 구조와 symmetric coefficient folding 적용
- 검증 관점: testbench와 waveform 기반 기능 확인
- 성장 관점: 이후 FPGA 영상처리 convolution, AXI/APB IP 설계로 이어지는 초기 RTL 기반 프로젝트

## Artifacts

- [Top RTL](./HW_based_FIR/Src/FirTop.v)
- [Controller](./HW_based_FIR/Src/controller.v)
- [Delay Chain](./HW_based_FIR/Src/delayChain.v)
- [Multiplier](./HW_based_FIR/Src/Multiplier.v)
- [Accumulator](./HW_based_FIR/Src/Accumulator.v)
- [Coefficient SRAM](./HW_based_FIR/Src/SpSram.v)
- [Testbench](./HW_based_FIR/tb/tb_FirTop.v)
- [Final Report PDF](./HW_based_FIR.pdf)
- [Presentation PPTX](./HW_based_FIR.pptx)

## Wrap-Up

이 프로젝트는 규모가 큰 SoC 설계는 아니지만, RTL datapath를 clock 단위로 구성하고 검증하는 감각을 익힌 출발점입니다. 특히 coefficient folding, SRAM, delay chain, MAC, controller를 하나의 filter로 묶으며 "알고리즘을 hardware 구조로 바꾸는 과정"을 직접 경험했습니다.
