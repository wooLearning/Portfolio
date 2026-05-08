# SPI/I2C Loopback UVM Verification Project

`sb_minimal_top` 하나를 대상으로, 단일 보드 내부의 SPI/I2C loopback 동작을 UVM으로 검증한 프로젝트입니다.  
외부 장치 모델에 의존하지 않고도 하나의 DUT 안에서 SPI와 I2C 경로를 end-to-end로 검증할 수 있도록 구성했고, 발표와 문서화 관점에서는 `sequence -> driver -> DUT -> monitor -> scoreboard -> coverage` 흐름이 가장 선명하게 드러나도록 정리했습니다.

## 프로젝트 개요

- 검증 대상: `260420_SPI_I2C_UVM_Verification_우상욱_code/src/sb_minimal_top.sv`
- 구조: SPI register master/slave + I2C register master/slave + 공통 `digit_register_bank`
- 검증 방식: UVM class-based verification
- 정리 기준: `src = RTL`, `tb/uvm_tb = verification`, `uvm_sim = 실행 환경`, `발표자료 = 설명 자료`

## 먼저 볼 자료

- [발표자료 PDF](./발표자료/260420_SPI_I2C_UVM_Verification_우상욱.pdf)
- [동작 영상](./260420_SPI_I2C_UVM_Verification_우상욱_동작영상.mp4)
- [코드 루트](./260420_SPI_I2C_UVM_Verification_우상욱_code)
- [DUT](./260420_SPI_I2C_UVM_Verification_우상욱_code/src/sb_minimal_top.sv)
- [UVM 패키지](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_uvm_pkg.sv)
- [통합 테스트벤치 Top](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/tb_loopback_uvm.sv)

## 소스코드와 자료 위치

| 경로 | 역할 |
| --- | --- |
| [260420_SPI_I2C_UVM_Verification_우상욱_code/src](./260420_SPI_I2C_UVM_Verification_우상욱_code/src) | SPI/I2C RTL과 `sb_minimal_top` |
| [260420_SPI_I2C_UVM_Verification_우상욱_code/tb](./260420_SPI_I2C_UVM_Verification_우상욱_code/tb) | 기본 directed TB |
| [260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb) | sequence, driver, monitor, scoreboard, coverage, test |
| [260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_sim](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_sim) | VCS/UVM 실행용 `Makefile`, `files.f` |
| [발표자료](./발표자료) | 발표 PDF |
| [260420_SPI_I2C_UVM_Verification_우상욱_동작영상.mp4](./260420_SPI_I2C_UVM_Verification_우상욱_동작영상.mp4) | 보드 동작 확인 영상 |

## DUT를 어떻게 해석했는가

이 프로젝트의 핵심은 "서로 다른 두 프로토콜이 하나의 저장소를 공유하는 구조"를 검증하는 데 있습니다.

- SPI 경로: `spi_reg_master -> spi_reg_slave -> digit_register_bank`
- I2C 경로: `i2c_reg_master -> i2c_reg_slave -> digit_register_bank`
- 최종 관측 포인트: `oRxData`, `oDone`, `oAckError`, `oDigits`

즉 protocol handshake 자체만 보는 것이 아니라, 서로 다른 접근 경로가 동일한 register state를 어떻게 갱신하는지 확인하는 구조입니다. 이 점 때문에 `singleboard` loopback은 외부 counterpart model 설명 없이도 DUT 내부 데이터 흐름과 UVM 검증 전략을 바로 보여주기 좋은 대표 예제입니다.

## UVM 검증 구조

주요 UVM 파일은 아래와 같습니다.

- [loopback_uvm_interface.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_uvm_interface.sv)
- [loopback_uvm_pkg.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_uvm_pkg.sv)
- [tb_loopback_uvm.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/tb_loopback_uvm.sv)
- [loopback_sequence.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_sequence.sv)
- [loopback_driver.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_driver.sv)
- [loopback_monitor.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_monitor.sv)
- [loopback_scoreboard.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_scoreboard.sv)
- [loopback_coverage.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_coverage.sv)
- [loopback_test.sv](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_tb/loopback_test.sv)

검증 흐름은 다음과 같습니다.

1. `loopback_base_sequence`가 transaction을 생성하면서 `reg_model[4]`와 `current_spi_mode`를 기준으로 expected 결과도 함께 계산합니다.
2. `loopback_driver`가 DUT 입력 핀을 직접 구동하고, `compare_en`이 켜진 item은 `exp_ap`로 scoreboard에 전달합니다.
3. `loopback_monitor`는 `done` 상승 에지를 transaction 완료 시점으로 보고, 두 클럭 뒤 결과를 읽어 actual item으로 복원합니다.
4. `loopback_scoreboard`는 expected/actual FIFO 비교로 protocol, read/write, SPI mode, register, `digits`, `ack_error`, 필요 시 `rx_data`를 확인합니다.
5. `loopback_coverage`는 protocol, read/write, SPI mode, reg0~reg3, overwrite, protocol switch, reset 직후 첫 transfer, data class와 주요 cross coverage를 샘플링합니다.

## 테스트 시나리오

기본 실행 테스트는 `loopback_run_test`이며, 내부적으로 `loopback_comprehensive_sequence`를 통해 아래 흐름을 순차 실행합니다.

1. `full`
2. `random`
3. `negative`
4. `reset_recovery`

관련 클래스와 역할은 다음과 같습니다.

- `loopback_smoke_sequence`: 가장 기본적인 SPI/I2C write/read 동작 확인
- `loopback_full_sequence`: SPI mode 0~3, reg0~reg3, overwrite, I2C readback까지 포함한 directed 검증
- `loopback_random_sequence`: protocol과 접근 순서를 랜덤하게 흔들어 model/scoreboard 일관성 확인
- `loopback_negative_sequence`: overwrite, protocol switch, in-flight reset abort 같은 예외 상황 검증
- `loopback_reset_sequence`: reset 이후 DUT와 model이 다시 정상 상태로 복구되는지 확인
- `loopback_comprehensive_sequence`: 위 시나리오를 하나로 묶어 stateful 흐름으로 실행
- `loopback_run_test`: 기본 실행용 UVM test

이 구조의 포인트는 sequence가 단순 stimulus generator가 아니라 expected model의 출발점까지 함께 담당한다는 점입니다. 덕분에 scoreboard는 비교와 ordering에 집중할 수 있고, reset abort 같은 corner case도 시나리오 관점에서 다루기 쉬워집니다.

## 대표 결과

발표자료 기준으로 확인되는 대표 결과는 다음과 같습니다.

| 항목 | 내용 |
| --- | --- |
| Integrated scenario flow | `full -> random -> negative -> reset_recovery` |
| Transaction mix by phase | `full=28`, `random=64`, `negative=7`, `reset_recovery=4` |
| Coverage | 주요 coverpoint/cross 항목 `100%` 달성 |
| Coverage note | `ack_error=1`은 singleboard loopback 구조상 unreachable이라 `ignore_bins` 처리 |

## 폴더 구조

```text
SPI_I2C_UVM/
├─ 260420_SPI_I2C_UVM_Verification_우상욱_code/
│  ├─ src/                     # SPI/I2C RTL, sb_minimal_top
│  ├─ tb/                      # 기본 testbench
│  ├─ uvm_tb/                  # UVM 환경
│  └─ uvm_sim/                 # VCS/UVM 실행 스크립트
├─ 발표자료/
│  └─ 260420_SPI_I2C_UVM_Verification_우상욱.pdf
├─ 260420_SPI_I2C_UVM_Verification_우상욱_동작영상.mp4
├─ 260420_SPI_I2C_UVM_Verification_우상욱_code.zip
└─ README.md
```

## 실행 방법

필수 환경:

- Synopsys VCS
- UVM 1.2
- Verdi

기본 실행:

```bash
cd 260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_sim
make run
```

seed 지정 실행:

```bash
cd 260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_sim
make run SEED=31
```

다중 seed regression:

```bash
cd 260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_sim
make regress_random
```

정리(clean):

```bash
cd 260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_sim
make clean
```

기본 설정은 [uvm_sim/Makefile](./260420_SPI_I2C_UVM_Verification_우상욱_code/uvm_sim/Makefile)에 정리되어 있으며, 기본 top은 `tb_loopback_uvm`, 기본 test는 `loopback_run_test`입니다.

## 메모

- 이 프로젝트는 singleboard loopback을 통해 외부 모델 없이도 SPI/I2C end-to-end 검증 흐름을 보여주는 데 강점이 있습니다.
- 발표자료는 singleboard bring-up, UVM 구조, coverage 전략을 설명하는 용도로 함께 보면 좋고, 실제 검증 구조는 `uvm_tb/`와 `uvm_sim/Makefile`에서 바로 확인할 수 있습니다.
