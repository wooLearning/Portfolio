# Undergraduate Internship (APB-AES)
> HW AES-128 with APB Interface

## 📅 Project Info
- **Period**: 2024.12.23 ~ 2025.01.15
- **Role**: Hardware Design Intern
- **Stack**: `Verilog-HDL` `APB Protocol` `AES-128`

## 📝 Summary
APB(Advanced Peripheral Bus) 인터페이스를 갖춘 **AES-128 암호화 하드웨어 IP**를 설계한 인턴십 프로젝트입니다.  
32-bit APB 버스로 데이터를 받아 128-bit 블록으로 변환(Packing)하고, AES 코어 연산 후 결과를 메모리에 저장하며 인터럽트를 발생하는 전체 SoC 구조를 구현했습니다.

## 💡 Key Modules
- **Cp_ApbIfBlk**: APB Slave Interface 및 레지스터 맵핑.
- **Cp_WrDtConv / RdDtConv**: Data Width Conversion (32b ↔ 128b) 및 Endian 처리.
- **AesCore**: AES-128 암호화 로직 코어.
- **Verification**: `TbTop_CpTop.v` 등 시뮬레이션 테스트벤치.

## 📂 Artifacts
- RTL Source Code (`AES/`)
- Simulation Testbenches
- Internship Final Report
