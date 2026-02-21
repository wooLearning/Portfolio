# AIX 2025 딥러닝 하드웨어 설계 경진대회
> 2025 Deep Learning Hardware Design Contest

## 📅 Project Info
- **Period**: 2025.02 ~ 2025.06
- **Award**: **장려상 (Encouragement Prize)**
- **Stack**: `Verilog-HDL` `FPGA` `AXI` `C`

## 📝 Summary
CNN 이미지 인식 모델을 **FPGA 하드웨어로 가속**하는 설계를 수행했습니다.  
C 언어로 구현된 모델을 Verilog-HDL로 변환하여 설계하고, FPGA의 자원(BRAM, DSP) 제약 내에서 Global Buffer 최적화와 Sliding Window 방식을 적용하여 추론 성능을 확보했습니다.

## 💡 Key Features
- **CNN Accelerator**: Conv, Pooling, FC Layer 하드웨어 구현.
- **Quantization**: FP32 모델을 INT8로 양자화하여 메모리/연산 효율 증대 (mAP 78.03%).
- **System Integration**: AXI4 인터페이스를 통한 PL-PS 데이터 전송 및 DMA 연동.
- **Optimization**: DSP Slice 공유 및 Global BRAM 버퍼링 전략 적용.

## 📂 Artifacts
- `1_Code/`: Quantization (C), RTL Simulation, Vivado Project
- `AIX2025_전자전시회.mp4`: 데모 영상
