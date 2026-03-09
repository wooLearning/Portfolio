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

## 🚀 Trouble Shooting & Future Work
- **Zero Padding**: 현재 128비트 배수 크기의 데이터 입력을 가정하여 구현되었으나, 추후 128비트에 맞지 않는 Byte 수가 들어올 경우를 대비해 **Endian에 맞는 Zero padding 기능**을 보완할 계획입니다.
- **Direction 제어**: 현재는 암호화(Encryption) 과정만 가능하지만, Direction 변수/플래그를 추가하여 **복호화(Decryption) 모드**도 단일 하드웨어에서 수행하도록 확장할 예정입니다.
- **PPA 최적화**: 단일 AES Core 구조를 **Multi-Block 처리 방식**으로 개선하여 암호화 속도(Throughput)를 높이고, 사용하지 않는 블록의 전력을 차단하는 **Dynamic Clock Gating** 기법을 도입하여 Power 효율을 극대화할 것입니다.

## 📂 Artifacts
- RTL Source Code (`AES/`)
- Simulation Testbenches
- Internship Final Report
