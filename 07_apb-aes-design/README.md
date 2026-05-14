# APB Interface 기반 AES-128 IP 설계
> AES-128 encryption core에 APB register interface, input/output buffer, control path를 붙여 hardware peripheral IP 형태로 구현한 RTL 설계 프로젝트입니다.

## Project Info

| 항목 | 내용 |
|---|---|
| 기간 | `2024.12.23 ~ 2025.01.15` |
| 유형 | 개인 설계 프로젝트 / APB 기반 AES-128 IP RTL 설계 |
| 역할 | AES RTL, APB interface, buffer/control path 구현 및 testbench 검증 |
| 언어/도구 | `Verilog-HDL` `Xcelium` |
| Protocol / Algorithm | `APB Protocol` `AES-128` |
| Core Keywords | `32-bit APB Register Interface` `128-bit Block Packing` `Memory Map` `Interrupt` `Endian Conversion` |

## Summary

AES-128 block을 RTL로 설계하고 APB interface를 붙여 software에서 제어 가능한 hardware IP 형태로 구현했습니다. APB에서 받은 32-bit write data를 내부 `InBuf`에서 128-bit block으로 packing하고, AES core 연산이 끝난 뒤 `OutBuf`와 interrupt를 통해 software가 완료 상태와 결과를 확인할 수 있도록 구성했습니다.

이 프로젝트는 알고리즘 RTL 하나를 만드는 데서 끝나지 않고, `register interface -> buffer -> AES core -> result buffer -> interrupt`로 이어지는 SoC peripheral 관점의 data/control path를 함께 다뤘다는 점이 핵심입니다.

## Architecture

전체 구조는 [Cp_Top.v](./AES/RTL/Src/Cp_Top.v) 기준으로 다음 블록으로 나뉩니다.

- [Cp_ApbIfBlk.v](./AES/RTL/Src/Cp_ApbIfBlk.v): APB 접근을 해석하고 control/status register, InBuf write, OutBuf read를 연결합니다.
- [Cp_WrDtConv.v](./AES/RTL/Src/Cp_WrDtConv.v): APB 32-bit write data를 128-bit buffer word로 packing합니다.
- [Cp_BufWrap.v](./AES/RTL/Src/Cp_BufWrap.v): 내부 input/output buffer wrapper입니다.
- [Cp_Ctrl.v](./AES/RTL/Src/Cp_Ctrl.v): AES 실행 흐름을 제어하고 InBuf read, AES start, OutBuf write, done/interrupt 흐름을 만듭니다.
- [AesCore.v](./AES/RTL/Src/Aescore/AesCore.v): AES-128 datapath와 round control을 수행합니다.
- [Cp_RdDtConv.v](./AES/RTL/Src/Cp_RdDtConv.v): 128-bit output block을 APB 32-bit read 단위로 분해합니다.

```text
APB Master
  -> Cp_ApbIfBlk
  -> Cp_WrDtConv
  -> InBuf
  -> Cp_Ctrl
  -> AesCore
  -> OutBuf
  -> Cp_RdDtConv
  -> APB Read Data / Interrupt
```

## Data and Control Flow

1. Software가 APB write로 plaintext와 key/control 값을 register map에 기록합니다.
2. `Cp_WrDtConv`가 32-bit word address 하위 bit를 이용해 128-bit buffer의 word select를 만듭니다.
3. `Cp_Ctrl`이 InBuf에서 128-bit block을 읽고 endian 변환 후 AES core에 전달합니다.
4. AES core가 `SubBytes`, `ShiftRows`, `MixColumns`, `KeyExpansion`, `RoundFunc`를 거쳐 ciphertext를 생성합니다.
5. 결과는 OutBuf에 저장되고, 마지막 block 처리 후 done/interrupt 흐름으로 APB 쪽에 완료 상태를 알립니다.
6. Software는 APB read로 OutBuf를 32-bit 단위로 읽습니다.

## Key Implementation Points

### 1. APB Register Interface

APB slave interface는 `PSEL`, `PENABLE`, `PWRITE`, `PADDR`, `PWDATA`를 기준으로 write/read enable을 생성합니다. 입력 buffer 영역과 출력 buffer 영역을 memory map으로 나누어 software 입장에서 일반 peripheral register처럼 접근할 수 있도록 했습니다.

### 2. 32-bit to 128-bit Packing

APB data bus는 32-bit이지만 AES block은 128-bit입니다. 따라서 address 하위 2-bit를 이용해 4개의 32-bit write를 하나의 128-bit block으로 packing했습니다. 이 구조는 bus width와 algorithm block width가 다를 때 필요한 data width conversion 경험으로 이어졌습니다.

### 3. AES Control Path

`Cp_Ctrl`은 `p_Idle`, `p_RdCpInBuf`, `p_WrCpOutBuf` 등 상태를 통해 buffer read, AES start/done, output write 흐름을 제어합니다. 단일 block 연산뿐 아니라 byte size 기준 마지막 data flag를 확인해 전체 처리 완료 시점을 잡습니다.

### 4. Endian Debugging

구현 중 endian 처리 때문에 expected ciphertext와 RTL 결과가 다르게 나오는 문제가 있었습니다. Python 기반 AES reference 값을 golden data로 사용해 testbench에서 비교했고, `Cp_Ctrl`의 byte ordering을 확인하며 수정했습니다. 이 과정에서 알고리즘형 IP는 RTL 구현 자체만큼 신뢰 가능한 reference model과 testbench 비교가 중요하다는 점을 배웠습니다.

## Verification

검증은 AES core 단독 검증과 APB interface를 포함한 top-level 검증으로 나누어 진행했습니다.

- AES-128 golden vector 기반 core output 비교
- APB write로 input/key/control 값 설정
- InBuf/OutBuf read-write path 확인
- AES start/done timing 확인
- 완료 후 interrupt/status 흐름 확인
- 32-bit APB access와 128-bit AES block packing/unpacking 확인

관련 testbench는 [Tb_AesCore.v](./AES/TestBench/TbTop/Tb_AesCore.v), [TbTop_CpTop.v](./AES/TestBench/TbTop/TbTop_CpTop.v), [TbTop_VariousCase.v](./AES/TestBench/TbTop/TbTop_VariousCase.v)에서 확인할 수 있습니다.

## ETRI Portfolio Focus

- RTL 설계 관점: AES datapath, buffer, control FSM, APB slave interface 구현
- SoC 관점: AXI4-to-APB bridge 뒤에 붙을 수 있는 APB peripheral 구조로 정리
- 검증 관점: Python reference/golden data 기반 endian 및 encryption result 검증
- 문제해결 관점: bus width 차이와 byte ordering 문제를 hardware data path에서 해결

## Artifacts

- [Top RTL](./AES/RTL/Src/Cp_Top.v)
- [APB Interface](./AES/RTL/Src/Cp_ApbIfBlk.v)
- [AES Core](./AES/RTL/Src/Aescore/AesCore.v)
- [Control Block](./AES/RTL/Src/Cp_Ctrl.v)
- [Write Data Converter](./AES/RTL/Src/Cp_WrDtConv.v)
- [Read Data Converter](./AES/RTL/Src/Cp_RdDtConv.v)
- [Simulation Testbenches](./AES/TestBench/TbTop)
- [Internship Final Report PDF](./%EC%B5%9C%EC%A2%85%EB%B3%B4%EA%B3%A0%EC%84%9C/HDD_AES-128_2024%EB%85%84%20%ED%95%99%EB%B6%80%EC%83%9D%EC%97%B0%EA%B5%AC%EC%9D%B8%ED%84%B4%20%EA%B3%BC%EC%A0%9C_%EC%B0%A8%EC%84%B8%EB%8C%80%EB%B0%98%EB%8F%84%EC%B2%B4%ED%95%99%EA%B3%BC_%EC%9A%B0%EC%83%81%EC%9A%B1.pdf)

## Future Work

- 128-bit 배수 크기가 아닌 input을 위한 endian-aware zero padding
- encryption/decryption direction bit 추가
- multi-block throughput 개선 및 clock gating 기반 power 최적화
