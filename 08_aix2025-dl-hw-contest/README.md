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

## 🛠 Trouble Shooting & Learnings
- **구조적 한계 체감 및 PPA 최적화**: 프로젝트 초반에는 FPGA 자원(Resource) 사용량을 무리하게 최소화하려는 방향으로 설계를 진행했으나, 오히려 성능 제약과 잦은 구조 변경으로 인해 병목이 심화되었습니다. 이 과정에서 PPA(Power, Performance, Area) 간의 트레이드오프 한계를 깊이 체감했습니다.
- **자원 활용 가이드라인 선회**: 한계를 인식한 후, FPGA에 가용한 모든 자원을 적극적으로 활용하는 방향으로 설계를 선회했습니다. 특히 곱셈 연산 로직을 재배치하고 Global BRAM 등을 공격적으로 할당하여 병렬 처리 및 대역폭 성능 한계를 극복하려 시도했습니다.
- **성찰**: 비록 시간적인 제약으로 인해 의도했던 완벽한 최종 성능치를 끝까지 확보하지 못해 큰 아쉬움이 남았으나, 제한된 일정 속에서 하드웨어 구조를 유연하게 튜닝하고 실패를 견뎌내며 최적의 자원 사용 전략을 찾아가는 소중한 실무적 경험이 되었습니다.

## 📂 Artifacts
- `Source/1_Code/`: Quantization (C), RTL Simulation, Vivado Project
- `AIX2025_전자전시회.mp4`: 데모 영상
