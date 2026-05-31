# VCS/Verdi 실행 결과 및 UVM 검증 요약

작성일: 2026-05-31  
작업 위치: `T:\UVM_TEST` = remote `/home/hedu17/UVM_TEST`  
실행 방식: Windows PowerShell -> SSH `remote-target` -> remote `csh -fc "source ~/.cshrc; make ..."`  
GUI 기준: TigerVNC `kccisynop2:17`, remote `DISPLAY=:17`

## 결론

9개 예제 모두 remote Linux 환경에서 VCS compile, simulation, URG coverage 생성을 완료했다.

- VCS: `/tools/synopsys/vcs/W-2024.09-SP1/bin/vcs`
- URG: `/tools/synopsys/vcs/W-2024.09-SP1/bin/urg`
- Verdi: `/tools/synopsys/verdi/W-2024.09-SP2/bin/verdi`
- UVM: `-ntb_opts uvm-1.2`
- 공통 coverage metric: `line+cond+fsm+tgl+branch+assert`
- 모든 모듈: `UVM_ERROR=0`, `UVM_FATAL=0`
- 모든 모듈: `simv.daidir`, `simv.vdb`, `urgReport/dashboard.html`, `novas.fsdb` 생성 확인

처음 Windows PowerShell에서 직접 `make`를 실행했을 때의 `CreateProcess(NULL, vcs ...) failed`는 Makefile 문법 문제가 아니라 Windows 쪽 PATH/실행 위치 문제였다. 이 저장소는 `T:`가 remote `/home/hedu17`에 붙어 있으므로, 실제 Synopsys tool 실행은 remote shell에서 해야 한다.

## Make 사용법

Windows에서 바로 쓰는 권장 wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File .\common\scripts\remote_make_uvm.ps1 -Dir . -Target list
powershell -ExecutionPolicy Bypass -File .\common\scripts\remote_make_uvm.ps1 -Dir . -Target coverage -MakeArgs MODULE=04_uart_rx,SEQ=all
powershell -ExecutionPolicy Bypass -File .\common\scripts\remote_make_uvm.ps1 -Dir . -Target clean -MakeArgs MODULE=04_uart_rx
```

VNC의 remote terminal에서 직접 칠 때:

```csh
cd ~/UVM_TEST
source ~/.cshrc
make list
make coverage MODULE=04_uart_rx SEQ=all
make clean MODULE=04_uart_rx
```

모듈별 tb 폴더에서 직접 칠 때:

```csh
cd ~/UVM_TEST/04_uart_rx/tb
source ~/.cshrc
make coverage SEQ=all
make verdi_all SEQ=all
```

주요 target:

| Target | 의미 |
| --- | --- |
| `list` | 9개 module 이름 출력 |
| `module-help MODULE=...` | 해당 module Makefile help |
| `run MODULE=... SEQ=...` | compile 후 simulation |
| `coverage MODULE=... SEQ=...` | compile + simulation + URG |
| `verdi_all MODULE=... SEQ=...` | coverage 후 Verdi waveform/coverage GUI 실행 |
| `clean MODULE=...` | 산출물 삭제 |

## 실행 결과

최종 로그 위치: `docs/portfolio/uvm_results/vcs_runs_2026-05-31`

| Module | Run | Scoreboard / 결과 | Functional group | URG total score | UVM |
| --- | --- | --- | ---: | ---: | --- |
| 01_adder | PASS | 산술 compare pass, fail 없음 | 100.00% | 40.67% | 0E/0F |
| 02_ram | PASS | RAM write/read compare pass, fail 없음 | 100.00% | 46.12% | 0E/0F |
| 03_fifo | PASS | FIFO order/depth compare pass, fail 없음 | 100.00% | 50.76% | 0E/0F |
| 04_uart_rx | PASS | `Scoreboard pass=292 fail=0` | 100.00% | 63.30% | 0E/0F |
| 05_uart_tx | PASS | `Scoreboard pass=296 fail=0` | 100.00% | 60.57% | 0E/0F |
| 06_spi_master | PASS | `Scoreboard pass=275 fail=0` | 100.00% | 59.44% | 0E/0F |
| 07_spi_slave | PASS | `Scoreboard pass=274 fail=0` | 100.00% | 60.74% | 0E/0F |
| 08_i2c_master | PASS | `Scoreboard pass=529 fail=0` | 100.00% | 61.61% | 0E/0F |
| 09_i2c_slave | PASS | `Scoreboard pass=528 fail=0` | 100.00% | 60.46% | 0E/0F |

참고: URG total score는 RTL/UVM package/assert/toggle 등 전체 instrumented database 기준이라 functional group coverage 100%와 다르게 낮게 보인다. 검증 목표 커버리지는 각 TB의 covergroup 기준으로 모두 100%이다.

## Scenario / Sequence

| Module | 주요 시나리오 |
| --- | --- |
| 01_adder | zero/misc/max directed 조합과 random operand 조합. `iA+iB` golden sum으로 즉시 비교. |
| 02_ram | first/middle/last address write-read, 전체 address sweep, random write/read, reset/idle. |
| 03_fifo | idle, read-on-empty, write, simultaneous write/read, fill-to-full, drain-to-empty, random stream. |
| 04_uart_rx | smoke, directed byte pattern, frame error, false start, reset at idle/start/data/stop, timeout, jitter, corner, byte sweep. |
| 05_uart_tx | smoke, directed byte pattern, busy attempt, reset at idle/start/data/stop, timeout, jitter, corner, byte sweep. |
| 06_spi_master | smoke, directed pattern, CPOL/CPHA mode sweep, reset abort, jitter, corner, byte sweep. |
| 07_spi_slave | smoke, directed pattern, CPOL/CPHA mode sweep, CS abort, reset abort, jitter, corner, byte sweep. |
| 08_i2c_master | smoke, directed read/write, ACK/NACK error, reset abort, jittered tick, corner, byte sweep. |
| 09_i2c_slave | smoke, address hit/miss, read/write data, reset abort, jittered tick, corner, byte sweep. |

## Assertion 중심

| Module | Assertion / 체크 관점 |
| --- | --- |
| 01_adder | 별도 SVA보다 scoreboard golden model 중심. 조합 산술 결과를 transaction 단위로 비교. |
| 02_ram | selected 상태의 control/address knownness, idle read-data stability, write 후 같은 address readback. |
| 03_fifo | empty/count zero 일치, full/count depth 일치, active command unknown 방지. |
| 04_uart_rx | `oRxValid`와 `oFrameError` 동시 금지, reset 중 result pulse 금지, valid/error one-cycle pulse, false-start no-result. |
| 05_uart_tx | `oTxDone` one-cycle pulse, reset 중 done 금지, ready/busy complement, idle TX high. |
| 06_spi_master | done one-cycle, reset 중 done 금지, done 시 busy low, idle/done 후 CS high, CS high 시 SCLK idle level. |
| 07_spi_slave | CS high 시 MISO OE release, `oRxValid` one-cycle, reset 중 rx_valid 금지. |
| 08_i2c_master | done one-cycle, reset 중 done 금지, done 시 busy low, idle bus released. |
| 09_i2c_slave | `oRxValid` one-cycle, `oTxnDone` one-cycle, reset 중 pulse 금지, rx_valid는 write transaction에서만 기대. |

## Coverage 중심

| Module | Functional coverpoint |
| --- | --- |
| 01_adder | `iA`, `iB`, carry, `iA x iB` cross. |
| 02_ram | command read/write, address first/last/misc, write/read data, command x address cross. |
| 03_fifo | idle/write/read/wr_rd command, full/empty, count zero/mid/full, command x count cross. |
| 04_uart_rx | data pattern, valid/error/false-start/reset/timeout result, reset phase, tick mode, jitter mode. |
| 05_uart_tx | data pattern, busy handshake, completion/ignored/reset/timeout result, reset phase, tick mode, jitter mode. |
| 06_spi_master | TX data, MISO data, CPOL, CPHA, result, tick, jitter, reset, CPOL x CPHA cross. |
| 07_spi_slave | MOSI data, TX response data, CPOL, CPHA, result, tick, jitter, reset, CPOL x CPHA cross. |
| 08_i2c_master | read/write direction, address, data, ACK/NACK result, tick, jitter, reset. |
| 09_i2c_slave | read/write direction, address hit/miss, data, result, tick, jitter, reset. |

## Driver / Monitor / Scoreboard

Driver는 sequence item을 DUT pin-level stimulus로 변환한다. UART는 serial frame/tick/reset phase를 만들고, SPI는 CPOL/CPHA edge와 MOSI/MISO 흐름을 만든다. I2C는 open-drain style SCL/SDA transaction, ACK/NACK, reset abort window를 구성한다.

Monitor는 DUT 출력 또는 bus event를 transaction으로 복원한다. UART는 frame/result pulse를 관찰하고, SPI는 transfer byte와 done/rx_valid를 관찰한다. I2C는 START/address/data/ACK/STOP 흐름과 DUT status pulse를 transaction으로 만든다.

Scoreboard는 driver가 보낸 expected queue와 monitor가 본 observed item을 비교한다. Basic 3개는 golden model이 단순하고, 통신 6개는 normal path와 reset/timeout/error/abort path를 구분해서 fail/pass 및 no-event window를 판정한다.

## 이번에 고친 실행 이슈

- Windows local `make`가 `vcs`를 못 찾던 문제를 remote wrapper로 해결.
- 04~09 Makefile의 Windows `powershell` 기반 check/clean을 remote Linux용 `test`/`rm -rf`로 변경.
- 04~09에도 `coverage`, `urg`, `verdi`, `verdi_all` target 추가.
- 04/05 UART include path 누락을 `+incdir+./src`로 수정.
- 06~09 `files.f`의 `-d XXX` define을 `+define+XXX`로 변경해 VCS `vcs1 SIGSEGV` 회피.
- 04~09도 Verdi waveform을 바로 열 수 있도록 `+define+FSDB`와 `novas.fsdb` dump block 적용.

## 산출물

각 module의 `tb` 폴더에 다음 산출물이 생성되어 있다.

- `simv`: VCS simulation binary
- `simv.daidir`: Verdi KDB
- `simv.vdb`: VCS coverage database
- `urgReport/dashboard.html`: URG coverage report
- `novas.fsdb`: Verdi waveform
- `build.log`, `run.log` 또는 wrapper coverage log
