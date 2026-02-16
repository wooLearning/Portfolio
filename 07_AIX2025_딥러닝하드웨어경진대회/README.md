# 2025 Deep Learning Hardware 설계 경진대회 장려상
# 2025 Deep Learning Hardware Design Contest (Encouragement Prize)

## 1. 수상 정보 | Award Information
- 수상명 / Award: `2025 Deep Learning Hardware 설계 경진대회 장려상`
- 수여기관 / Institution: `서울대학교 차세대 반도체 사업단`
- 수상연도 / Year: `2025`
- 수행기간 / Project period: `2025.02 ~ 2025.06`

## 2. 한국어 요약 | Korean Summary
C로 구현된 CNN 이미지 인식 모델을 하드웨어로 가속하는 것을 목표로 했습니다.  
주어진 파라미터와 데이터셋을 기반으로 Verilog-HDL CNN 구조를 설계했고, 제한된 FPGA 자원에서 동작하도록 검증했습니다.  
Global BRAM 활용, Window logic 구성, AXI Protocol 연동 등 디지털 하드웨어 설계 방법을 적용했습니다.

## 3. English Summary
The project aimed to accelerate a C-based CNN image-recognition model in hardware.  
Using given parameters and data, a Verilog-HDL CNN architecture was designed and verified to run under limited FPGA resources.  
Key design work included Global BRAM planning, window logic organization, and AXI protocol based integration.

## 4. 핵심 목표 | Technical Goals
- FP32 inference flow quantization to INT8
- Verilog-HDL accelerator design for CNN layers
- FPGA verification under resource constraints

## 5. 구현 포인트 | Design Highlights
- Layer-dependent weight handling:
  - layer 0/2/4: ROM-stored weights
  - deeper layers: DMA-fed weights
- DSP optimization: one DSP for two 8-bit by 8-bit operations
- BRAM allocation strategy for feature maps/weights/bias
- 발표자료 기준 정량 결과: `mAP 78.03%` 수준

## 6. 저장소 구성 | Repository Contents
- `1_Code/1_Quantization`: quantization C code
- `1_Code/2_RTL_Simulation`: RTL simulation and testbench
- `1_Code/3_FPGA_Implementation`: FPGA implementation
- top-level presentation deck and demo video

## 7. 기술 스택 | Tech Stack
- Language/HDL: `C`, `Verilog-HDL`
- Platform: `FPGA`
- Topics: quantization, DMA, DSP/BRAM optimization, AXI protocol
