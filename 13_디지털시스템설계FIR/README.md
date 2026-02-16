# HW-Based FIR Filter with Kaiser Window

A digital system design project implementing a reconfigurable 79-tap FIR filter in RTL, with separated coefficient-update and filtering phases managed by FSM.

## 1. Project Overview
- Goal: implement and verify a hardware FIR architecture
- Reference files: report PDF and presentation PPTX in this folder
- Design targets (from presentation):
  - BW: `400kHz`
  - Sampling: `600kHz`
  - Symbol: `200kHz`

## 2. Architecture
Top module: `FirTop.v`

Main blocks:
- `controller.v`: FSM for update/filter phase control
- `SpSram.v` x4: coefficient memory
- `delayChain.v`: tap delay line for symmetric structure
- `Multiplier.v` x4: multiplication
- `Accumulator.v` x4: partial accumulation
- `Sum.v`: final output aggregation

## 3. Design Highlights
- coefficient folding for reduced compute/memory pressure,
- explicit mode separation with `iCoeffUpdateFlag`,
- deterministic control timing through FSM transitions.

## 4. Verification
- Pre-sim: ModelSim
- Post-sim: Vivado
- Testbench: `tb_FirTop.v`

Validated behavior:
- clock/sample enable sequencing,
- coefficient SRAM write flow,
- output monitoring through `oFirOut`.

## 5. Tech Stack
- HDL: `Verilog`
- Tools: `ModelSim`, `Xilinx Vivado`
- Target part: `xc7a35tftg256-1`

## 6. Artifacts
- report and presentation,
- RTL source in `Src/`,
- testbench in `tb/`.
