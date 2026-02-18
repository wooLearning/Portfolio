# Undergraduate Internship (AXI2APB)
> AXI4 to APB Bridge Design

## 📅 Project Info
- **Period**: 2026.01
- **Role**: Hardware Design Intern (Winter)
- **Stack**: `SystemVerilog` `AMBA AXI4` `APB`

## 📝 Summary
고속 버스인 **AXI4**와 저속 주변장치 버스인 **APB**를 연결하는 **Bridge IP**를 설계했습니다.  
AXI의 Burst 트랜잭션을 APB의 단일 전송(Single Transfer)으로 변환하는 FSM을 구현하고, PREADY 핸드쉐이킹 및 에러 처리를 포함하여 안정적인 버스 프로토콜 변환을 검증했습니다.

## 💡 Key Features
- **Protocol Bridge**: AXI4 Slave ↔ APB Master 변환 로직.
- **Burst Handling**: Sequential Burst를 개별 APB 트랜잭션으로 분할 처리.
- **Slave Decoding**: PSEL 디코딩을 통한 다중 슬레이브(4-Slave) 제어.

## 📂 Artifacts
- RTL Source Code (`Prj_Axi_Top.v`, `Axi2Apb.v`)
- HDD Report (Design Spec & Waveform Analysis)
