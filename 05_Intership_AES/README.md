# Undergraduate Research Internship: HW AES-128 with APB Interface

This folder contains internship deliverables for an APB-interfaced AES-128 hardware design.

## 1. Portfolio Snapshot
- Category: Undergraduate research internship
- Program period: **2024.12.23 to 2025.01.15**
- Training hours: **36 hours**
- Date reference: root resume PDF and root experience CSV

Report revision history shows major updates during **2025.01.07 to 2025.01.15**.

## 2. Design Goal
- accept 32-bit APB writes and pack into 128-bit plaintext blocks,
- run AES-128 encryption core,
- store encrypted output to buffer memory,
- notify completion by interrupt path.

## 3. RTL Highlights
Main modules:
- `Cp_Top.v`
- `Cp_ApbIfBlk.v`
- `Cp_Ctrl.v`
- `Cp_WrDtConv.v` and `Cp_RdDtConv.v`
- `Cp_BufWrap.v`
- `SpSram_128x128.v`

Verification files:
- `Tb_AesCore.v`
- `TbTop_CpTop.v`
- `TbTop_VariousCase.v`

The report documents register map, endian conversion path, FSM control flow, and timing diagrams.

## 4. Main Evidence
- final report PDF and DOCX in `final report` folder
- RTL and testbench source trees under `AES/`

## 5. Tech Stack
- HDL: `Verilog-HDL`
- Bus protocol: `APB`
- Verification: simulation testbenches
