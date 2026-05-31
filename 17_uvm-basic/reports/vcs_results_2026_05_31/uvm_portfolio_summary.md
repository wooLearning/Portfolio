# SystemVerilog UVM 기반 RTL 검증 환경 구성

## 프로젝트 목표

기초 RTL module과 통신 protocol RTL을 대상으로 UVM testbench를 구성하고, scenario, assertion, scoreboard, functional coverage가 연결되는 검증 흐름을 정리하는 것이 목표였습니다. Basic 프로젝트는 VCS/Verdi 및 Makefile 기반 실행 구조를 기준으로 두고, 통신 protocol 프로젝트는 라이선스 상황을 고려해 Vivado/XSim에서도 재현 가능한 형태로 별도 정리했습니다.

## 프로젝트 양식

| 항목 | 내용 |
| --- | --- |
| 유형 | 개인 실습 프로젝트 / SystemVerilog UVM 검증 환경 구성 |
| 진행 기간 | 2026.05 |
| 사용 언어·도구 | SystemVerilog, UVM 1.2, VCS, Verdi, Vivado/XSim |
| 검증 대상 | Basic: Adder, RAM, FIFO / Communication: UART, SPI, I2C |
| 핵심 구성 | sequence, driver, monitor, scoreboard, functional coverage, SVA/assertion |

## 프로젝트 개요

Basic 파트에서는 Adder, synchronous single-port RAM, synchronous FIFO를 대상으로 공통 UVM component 구조를 구성했습니다. 각 block은 `rtl`, `tb`, `Makefile`을 갖고 있으며, 상위 `projects/basic/Makefile`에서 `BLOCK=adder|ram|fifo` 형태로 실행할 수 있게 정리했습니다.

Communication 파트에서는 UART, SPI, I2C를 protocol 단위로 묶고, 각 protocol 내부를 `rtl`, `tb`, `sim/vivado`로 정리했습니다. UART는 RX/TX, SPI와 I2C는 master/slave bench를 분리했으며, Vivado/XSim용 sequence argument file은 source와 섞이지 않도록 `sim/vivado`에 따로 보관했습니다.

## 핵심 구조

![UVM UART class top](../diagrams/uvm/diagram_uvm_uart_class_top.png)

공통 UVM 구조는 `test -> env -> agent -> sequencer/driver/monitor -> scoreboard/coverage`로 구성했습니다. Driver는 sequence item을 pin-level 동작으로 변환하고, monitor는 DUT 출력과 bus event를 transaction으로 복원합니다. Scoreboard는 expected model과 observed transaction을 비교하고, coverage subscriber는 scenario와 data bin을 sample합니다.

![UVM UART RX/TX sequence](../diagrams/uvm/diagram_uvm_uart_rx_tx_sequence.png)

Sequence diagram에서는 scenario가 sequence item으로 생성되고, driver가 interface를 통해 DUT를 구동한 뒤 monitor가 observed transaction을 scoreboard와 coverage로 전달하는 흐름을 정리했습니다. RX/TX 모두 expected path와 observed path를 분리해 scoreboard 비교 기준을 명확히 했습니다.

## Basic 검증 항목

| DUT | 주요 시나리오 | 어설션 / SVA | 커버리지 |
| --- | --- | --- | --- |
| Adder | zero, max, carry, random 산술 입력 | 별도 SVA보다는 scoreboard golden sum 비교 중심 | `iA`, `iB`, carry, `iA x iB` cross |
| RAM | write/read, same-address readback, reset, idle | control/address X check, reset control low, address stable, idle read-data stable, write 후 next-read data check | command, address, write data, read data, command x address |
| FIFO | idle, write, read, simultaneous wr/rd, full/empty boundary, random | empty/count match, full/count match, command X check | command, full, empty, count, command x count |

Basic 파트는 UVM 구조 학습과 VCS/Verdi 실행 기준을 잡는 역할입니다. RAM과 FIFO는 단순 scoreboard 비교만 두지 않고, interface-level rule과 상태 flag rule을 assertion으로 보강했습니다.

## Communication 검증 항목

| Protocol / Bench | 주요 시나리오 | 어설션 / SVA | 커버리지 |
| --- | --- | --- | --- |
| UART RX | directed, error, reset, timeout, jitter, corner, byte_sweep, full_random, all | valid/frame_error 동시 발생 금지, reset 중 pulse 금지, valid/frame_error one-cycle pulse, false start 후 no result | data pattern, frame result, reset phase, tick mode, jitter mode |
| UART TX | directed, reset, timeout, jitter, corner, byte_sweep, full_random, all | done one-cycle pulse, reset 중 done 금지, ready/busy complement, idle TX high | data pattern, busy handshake, result, reset phase, tick mode, jitter mode |
| SPI Master | smoke, corner, byte_sweep, full_random, all | done one-cycle, reset 중 done 금지, done 시 busy low, idle CS/SCLK rule | TX data, MISO data, CPOL, CPHA, result, tick/jitter/reset, CPOL x CPHA |
| SPI Slave | smoke, corner, byte_sweep, full_random, all | CS high 시 MISO output release, RX valid one-cycle, reset 중 RX valid 금지 | MOSI data, TX data, CPOL, CPHA, result, tick/jitter/reset, CPOL x CPHA |
| I2C Master | smoke, directed, error, reset, jitter, byte_sweep, full_random, all | done one-cycle, reset 중 done 금지, done 시 busy low, idle bus release | read/write direction, address, data, result, tick/jitter/reset |
| I2C Slave | smoke, directed, error, reset, jitter, byte_sweep, full_random, all | RX valid one-cycle, transaction done one-cycle, reset 중 pulse 금지, read transaction에서 RX valid 금지 | read/write direction, address hit, data, result, tick/jitter/reset |

Communication 파트는 단순 smoke test에서 끝내지 않고, 각 bench별로 byte sweep과 full random을 추가해 data space를 넓게 확인했습니다. Protocol별 assertion은 reset, one-cycle pulse, idle 상태, status flag처럼 waveform에서 놓치기 쉬운 rule을 잡는 데 사용했습니다.

## 검증 결과 요약

| Bench | All scenario | Scoreboard pass | Scoreboard fail | UVM_ERROR | UVM_FATAL | Functional coverage |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| UART RX | PASS | 292 | 0 | 0 | 0 | 100% |
| UART TX | PASS | 296 | 0 | 0 | 0 | 100% |
| SPI MASTER | PASS | 275 | 0 | 0 | 0 | 100% |
| SPI SLAVE | PASS | 274 | 0 | 0 | 0 | 100% |
| I2C MASTER | PASS | 529 | 0 | 0 | 0 | 100% |
| I2C SLAVE | PASS | 528 | 0 | 0 | 0 | 100% |

추가로 각 communication bench에서 `byte_sweep`과 `full_random` sequence를 실행했습니다. UART와 SPI는 8-bit payload 0x00~0xFF 전수 확인을 수행했고, I2C master/slave는 write/read data 조합을 포함해 512 transaction 수준으로 확인했습니다.

## 담당 분야 / 역할

RTL source와 UVM testbench 구조를 정리하고, block별 sequence item, sequence, driver, monitor, scoreboard, coverage component를 구성했습니다. Basic 파트에서는 VCS/Verdi 실행 기준을 Makefile로 정리했고, Communication 파트에서는 Vivado/XSim에서도 실행 가능한 `files.f`와 sequence argument file을 보존했습니다.

## 문제 해결 포인트

VCS 라이선스 문제로 모든 검증을 동일 simulator에서 진행하기 어려웠기 때문에, Basic은 VCS/Verdi 기준 구조를 유지하고 Communication은 Vivado/XSim 기준으로 분리했습니다. 이 과정에서 source와 simulator 산출물이 섞이지 않도록 `projects`, `docs`, `artifacts`를 나누었고, Vivado 실행 관련 파일은 `sim/vivado`로 분리했습니다.

Protocol 검증에서는 단순 pass/fail보다 scenario, assertion, coverage가 함께 보이도록 구조를 정리했습니다. Scenario는 어떤 입력을 넣었는지, assertion은 어떤 protocol rule을 즉시 감시했는지, coverage는 어떤 기능 공간을 실제로 hit했는지를 보여주는 기준으로 사용했습니다.

## 결과물

| 구분 | 위치 |
| --- | --- |
| Basic source | `projects/basic` |
| Communication source | `projects/communication` |
| UVM diagrams | `docs/diagrams/uvm` |
| Communication result CSV/PNG | `docs/reports/communication/uvm_results` |
| Vivado/XSim evidence logs | `artifacts/communication` |

최종적으로 Basic 3개 module과 Communication 3개 protocol을 하나의 UVM 검증 포트폴리오 묶음으로 정리했습니다. Basic은 Makefile 기반 실행 구조를 기준으로 삼고, Communication은 Vivado/XSim 검증 evidence와 scenario/coverage 결과가 보이도록 구성했습니다.
