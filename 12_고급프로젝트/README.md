# Ultra96 Real-Time Video Filter HW/SW Co-Design

An FPGA acceleration project that performs real-time camera filtering and LCD output by offloading 3x3 convolution operations to programmable logic.

## 1. Project Overview
- Platform: `Ultra96 v2 (Zynq UltraScale+ MPSoC)`
- Goal: improve frame throughput by moving repetitive pixel math from PS to PL
- Reference: final project report PDF in this folder

## 2. Architecture
### PS (software)
- mode selection via UART
- kernel control via AXI4-Lite registers (`iReg0~iReg3`)
- camera initialization over SCCB/I2C-like interface

Modes:
- `mode 0`: Sharpen
- `mode 1`: Strong Sharpen
- `mode 2`: Bypass
- `mode 3`: user-defined 3x3 kernel

### PL (hardware data path)
1. `camera_to_ram.v`
2. `in_buf_ctrl.v`
3. `Window3x3_RGB888.v`
4. `Conv3x3_RGB888.v`
5. `RGB888ToRGB565.v`
6. `LcdCtrl_RGB565.v`

## 3. Key Engineering Work
- buffering and frame-drop control to reduce pipeline bottlenecks,
- parallelized and pipelined 3x3 compute path,
- module-level and integrated verification with golden data checks,
- synthesis and implementation analysis in Vivado.

## 4. Results
Report summary:
- real-time camera-to-LCD processing verified,
- final throughput around `81.97 FPS`,
- approximately `9.93x` improvement versus baseline structure.

## 5. Tech Stack
- RTL: `Verilog`
- Driver: `C`
- Tools: `Xilinx Vivado`
- Interfaces: `AXI4-Lite`, `UART`, `SCCB`, `TFT-LCD`

## 6. Artifacts
- report PDF/DOCX,
- demo MP4,
- RTL in `RTL/`,
- driver code in `CdriverCode/`,
- testbench and XDC constraints in project folders.
