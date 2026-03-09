# Undergraduate Internship (APB-AES)
> HW AES-128 with APB Interface

## 📅 Project Info
- **Period**: 2024.12.23 ~ 2025.01.15
- **Role**: Hardware Design Intern
- **Stack**: `Verilog-HDL` `APB Protocol` `AES-128`

## 📝 Summary
APB(Advanced Peripheral Bus) 인터페이스를 갖춘 **AES-128 암호화 하드웨어 IP**를 설계한 인턴십 프로젝트입니다.  
32-bit APB 버스로 데이터를 받아 128-bit 블록으로 변환(Packing)하고, AES 코어 연산 후 결과를 메모리에 저장하며 인터럽트를 발생하는 전체 SoC 구조를 구현했습니다.

## 💡 System Architecture & Key Modules
AES 하드웨어는 Big Endian을 기준으로 암호화가 진행되므로, Software에서 받은 Little Endian 데이터를 변환하고 32-bit 데이터를 128-bit로 확장하여 처리합니다.

1. **Main Controller (`Cp_Ctrl`)**:
   - 데이터 흐름 제어의 핵심을 담당하는 모듈.
   - APB에서 데이터를 읽어 `InBuf`에 저장하고, 저장 완료 시 암호화를 시작하여 `OutBuf`에 결과가 쓰이도록 각 모듈(`Buf`, `AesCore` 등)의 Enable 신호를 제어합니다.
2. **APB Slave Interface (`Cp_ApbIfBlk`)**:
   - 32-bit APB 버스를 통해 레지스터 블록에 접근하고 통신하는 인터페이스 역할.
3. **Data Format Conversion (`Cp_WrDtConv / Cp_RdDtConv`)**:
   - 32-bit 데이터를 4번의 Read 동작을 통해 128-bit 블록으로 패킹(Packing)하고, Endian 변환(Little ↔ Big)을 수행합니다.
4. **AES Core (`AesCore`)**:
   - **AES-128** 기반 암호화 블록. 내부 구조를 최적화하여 1개의 Round 컴포넌트만 설계한 후, Control Block에서 발생하는 Flag 신호를 통해 `Pre-Round`, 9번의 전체 `Round`, 마지막 3개 단계의 `Round`를 하나의 하드웨어 자원으로 재사용하며 연산합니다. 각 Round별로 12 Clock이 소요됩니다.
5. **Memory Buffers (`InBuf / OutBuf`)**:
   - `SP SRAM` 단위로 설계되어 128-bit 폭의 데이터를 입출력합니다. 최대로 지원하는 패킷 사이즈는 2kBytes입니다.
   - 암호화가 완료되어 `OutBuf`에 모든 데이터가 쓰이면 `wLastDtFlag`를 출력해 APB 인터페이스에서 인터럽트(Interrupt)를 발생시킵니다.
## 🚀 Trouble Shooting & Future Work
- **Zero Padding**: 현재 128비트 배수 크기의 데이터 입력을 가정하여 구현되었으나, 추후 128비트에 맞지 않는 Byte 수가 들어올 경우를 대비해 **Endian에 맞는 Zero padding 기능**을 보완할 계획입니다.
- **Direction 제어**: 현재는 암호화(Encryption) 과정만 가능하지만, Direction 변수/플래그를 추가하여 **복호화(Decryption) 모드**도 단일 하드웨어에서 수행하도록 확장할 예정입니다.
- **PPA 최적화**: 단일 AES Core 구조를 **Multi-Block 처리 방식**으로 개선하여 암호화 속도(Throughput)를 높이고, 사용하지 않는 블록의 전력을 차단하는 **Dynamic Clock Gating** 기법을 도입하여 Power 효율을 극대화할 것입니다.

## 📂 Artifacts
- RTL Source Code (`AES/`)
- Simulation Testbenches
- Internship Final Report
