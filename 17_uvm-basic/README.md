# UVM RTL Verification Portfolio

SystemVerilog UVM 1.2 기반으로 9개 RTL DUT를 검증한 포트폴리오입니다.  
Adder, RAM, FIFO 같은 기본 DUT부터 UART, SPI, I2C 통신 모듈까지 시나리오, scoreboard, assertion, functional coverage를 구성하고 Synopsys VCS/Verdi/URG 결과를 정리했습니다.

## 검증 대상

| Group | DUT / Bench | 주요 검증 내용 |
|---|---|---|
| Basic | `01_adder` | boundary/random 입력, 산술 결과 비교, carry/overflow coverage |
| Basic | `02_ram` | write/read, same-address readback, reset/idle, data compare |
| Basic | `03_fifo` | ordering, depth/full/empty, simultaneous read/write |
| UART | `04_uart_rx` | frame decode, data pattern, jitter/reset/timeout |
| UART | `05_uart_tx` | TX frame generation, busy/done timing, reset/timeout |
| SPI | `06_spi_master` | CPOL/CPHA mode, MOSI/MISO transfer, busy/reset rule |
| SPI | `07_spi_slave` | CS timing, sampling mode, abort/reset scenario |
| I2C | `08_i2c_master` | address, R/W, ACK/NACK, byte sweep, reset/abort |
| I2C | `09_i2c_slave` | address hit/miss, read/write response, open-drain timing |

## 핵심 결과

- 9개 bench 모두 VCS simulation PASS
- scoreboard fail 0건
- UVM_ERROR / UVM_FATAL 0건
- 각 bench functional coverage 100%
- assertion report에서 주요 protocol rule 통과 및 실패 0건 확인

## 폴더 구조

```text
17_uvm-basic/
├── portfolio_final/
│   ├── portfolio_우상욱_working_base.md
│   ├── portfolio_우상욱_working_base.pdf
│   └── _portfolio_support/used_images/
├── reports/
│   ├── synopsys_urg_html/
│   │   ├── index.html
│   │   ├── 01_adder/
│   │   └── ...
│   └── vcs_results_2026_05_31/
│       ├── vcs_verdi_run_summary_2026-05-31.md
│       ├── make.md
│       └── uvm_results/
├── assets/
│   └── portfolio_figures/uvm/
└── source/
    └── vcs_uvm_9modules/
```

## 바로 볼 파일

| 목적 | 파일 |
|---|---|
| 제출용 통합 포트폴리오 PDF | [`portfolio_final/portfolio_우상욱_working_base.pdf`](./portfolio_final/portfolio_%EC%9A%B0%EC%83%81%EC%9A%B1_working_base.pdf) |
| 제출용 통합 포트폴리오 Markdown | [`portfolio_final/portfolio_우상욱_working_base.md`](./portfolio_final/portfolio_%EC%9A%B0%EC%83%81%EC%9A%B1_working_base.md) |
| Synopsys URG HTML index | [`reports/synopsys_urg_html/index.html`](./reports/synopsys_urg_html/index.html) |
| VCS/Verdi 실행 요약 | [`reports/vcs_results_2026_05_31/vcs_verdi_run_summary_2026-05-31.md`](./reports/vcs_results_2026_05_31/vcs_verdi_run_summary_2026-05-31.md) |
| Make 사용 정리 | [`reports/vcs_results_2026_05_31/make.md`](./reports/vcs_results_2026_05_31/make.md) |
| 최신 소스 묶음 | [`source/vcs_uvm_9modules`](./source/vcs_uvm_9modules) |
| 포트폴리오용 UVM 이미지 | [`assets/portfolio_figures/uvm`](./assets/portfolio_figures/uvm) |

## URG Report 확인 순서

`reports/synopsys_urg_html/index.html`을 열면 9개 모듈별 report 링크를 한 번에 볼 수 있습니다.

각 모듈에서 주로 확인한 페이지는 다음과 같습니다.

- `groups.html`: covergroup 단위 coverage summary
- `grp0.html`: coverpoint/bin hit 상세
- `asserts.html`: assertion 수행/통과/실패 결과
- `dashboard.html`: Synopsys URG report 전체 진입 화면

## 실행 방법

VCS/Verdi 환경이 잡힌 Linux/VNC terminal에서 실행합니다.

```sh
cd source/vcs_uvm_9modules
make run MODULE=04_uart_rx
make coverage MODULE=04_uart_rx
make verdi_all MODULE=04_uart_rx
```

전체 regression은 각 module folder의 `tb/Makefile` 기준으로 실행하며, 자세한 옵션은 [`reports/vcs_results_2026_05_31/make.md`](./reports/vcs_results_2026_05_31/make.md)에 정리했습니다.

## 정리 기준

Git에 올리기 위해 VCS/Verdi 빌드 산출물은 제외했습니다.

- 제외: `csrc`, `simv`, `simv.daidir`, `simv.vdb`, `urgReport`, waveform/log 임시 파일
- 포함: RTL, UVM TB, Makefile, guide 문서, 참고 PDF, URG HTML 복사본, 최종 포트폴리오 PDF/MD

기존 자료는 그대로 두고, 이번 정리본은 `portfolio_final`, `reports/synopsys_urg_html`, `reports/vcs_results_2026_05_31`, `source/vcs_uvm_9modules`, `assets/portfolio_figures/uvm`에 모았습니다.
