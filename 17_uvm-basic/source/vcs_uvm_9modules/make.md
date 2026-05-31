# UVM_TEST Make 사용 정리

이 프로젝트는 `T:\UVM_TEST`가 원격 Linux의 `/home/hedu17/UVM_TEST`에 붙어 있는 구조다. VCS, Verdi, URG는 Windows 로컬이 아니라 원격 Linux 쪽에 설치되어 있으므로 VNC 터미널 또는 SSH를 통해 remote shell에서 실행한다.

## VNC 터미널에서 시작

현재 VNC 화면의 터미널에서 아래처럼 시작하면 된다.

```sh
cd ~/UVM_TEST
csh
source ~/.cshrc
make list
```

프롬프트가 이미 `csh`이면 `csh`는 생략해도 된다.

```csh
cd ~/UVM_TEST
source ~/.cshrc
make list
```

`~/.cshrc`가 Synopsys tool 환경을 잡는다. 여기서 `vcs`, `verdi`, `urg`가 바로 떠야 정상이다.

## 가장 많이 쓰는 명령

```csh
make list
make module-help MODULE=04_uart_rx
make coverage MODULE=04_uart_rx SEQ=all
make verdi_all MODULE=04_uart_rx SEQ=all
make clean MODULE=04_uart_rx
```

Basic 3개는 `SEQ` 옵션이 없다.

```csh
make coverage MODULE=01_adder
make coverage MODULE=02_ram
make coverage MODULE=03_fifo
```

통신 6개는 `SEQ`를 쓸 수 있다.

```csh
make run MODULE=05_uart_tx SEQ=smoke
make coverage MODULE=06_spi_master SEQ=all
make verdi_all MODULE=09_i2c_slave SEQ=byte_sweep
```

## Module 목록

| MODULE | 설명 | SEQ 사용 |
| --- | --- | --- |
| `01_adder` | adder UVM TB | 없음 |
| `02_ram` | RAM UVM TB | 없음 |
| `03_fifo` | FIFO UVM TB | 없음 |
| `04_uart_rx` | UART RX UVM TB | 있음 |
| `05_uart_tx` | UART TX UVM TB | 있음 |
| `06_spi_master` | SPI master UVM TB | 있음 |
| `07_spi_slave` | SPI slave UVM TB | 있음 |
| `08_i2c_master` | I2C master UVM TB | 있음 |
| `09_i2c_slave` | I2C slave UVM TB | 있음 |

## Target 목록

루트 `~/UVM_TEST`에서 쓰는 target이다.

| Target | 예시 | 의미 |
| --- | --- | --- |
| `help` | `make help` | 루트 Makefile 도움말 |
| `list` | `make list` | module 목록 출력 |
| `reports` | `make reports` | module별 report 파일 경로 출력 |
| `module-help` | `make module-help MODULE=04_uart_rx` | 해당 module의 Makefile 도움말 |
| `check-module` | `make check-module MODULE=04_uart_rx` | module 이름 유효성 체크 |
| `compile` | `make compile MODULE=01_adder` | VCS compile |
| `build` | `make build MODULE=04_uart_rx` | VCS compile, `compile`과 같은 용도 |
| `run` | `make run MODULE=04_uart_rx SEQ=smoke` | compile 후 simulation |
| `coverage` | `make coverage MODULE=04_uart_rx SEQ=all` | compile + simulation + URG report |
| `urg` | `make urg MODULE=04_uart_rx` | 기존 `simv.vdb`로 URG report 생성 |
| `wave` | `make wave MODULE=04_uart_rx SEQ=all` | run 후 Verdi waveform 실행 |
| `verdi` | `make verdi MODULE=04_uart_rx SEQ=all` | `wave` alias |
| `verdi_cov` | `make verdi_cov MODULE=04_uart_rx SEQ=all` | coverage 후 Verdi coverage GUI 실행 |
| `verdi_all` | `make verdi_all MODULE=04_uart_rx SEQ=all` | coverage 후 waveform + coverage를 Verdi로 실행 |
| `clean` | `make clean MODULE=04_uart_rx` | simulation 산출물 삭제 |

## SEQ 옵션

`04_uart_rx`:

```csh
make coverage MODULE=04_uart_rx SEQ=smoke
make coverage MODULE=04_uart_rx SEQ=directed
make coverage MODULE=04_uart_rx SEQ=error
make coverage MODULE=04_uart_rx SEQ=reset
make coverage MODULE=04_uart_rx SEQ=timeout
make coverage MODULE=04_uart_rx SEQ=jitter
make coverage MODULE=04_uart_rx SEQ=corner
make coverage MODULE=04_uart_rx SEQ=byte_sweep
make coverage MODULE=04_uart_rx SEQ=full_random
make coverage MODULE=04_uart_rx SEQ=all
```

`05_uart_tx`:

```csh
make coverage MODULE=05_uart_tx SEQ=smoke
make coverage MODULE=05_uart_tx SEQ=directed
make coverage MODULE=05_uart_tx SEQ=busy
make coverage MODULE=05_uart_tx SEQ=reset
make coverage MODULE=05_uart_tx SEQ=timeout
make coverage MODULE=05_uart_tx SEQ=jitter
make coverage MODULE=05_uart_tx SEQ=corner
make coverage MODULE=05_uart_tx SEQ=byte_sweep
make coverage MODULE=05_uart_tx SEQ=full_random
make coverage MODULE=05_uart_tx SEQ=all
```

`06_spi_master`:

```csh
make coverage MODULE=06_spi_master SEQ=smoke
make coverage MODULE=06_spi_master SEQ=directed
make coverage MODULE=06_spi_master SEQ=mode
make coverage MODULE=06_spi_master SEQ=reset
make coverage MODULE=06_spi_master SEQ=jitter
make coverage MODULE=06_spi_master SEQ=corner
make coverage MODULE=06_spi_master SEQ=byte_sweep
make coverage MODULE=06_spi_master SEQ=full_random
make coverage MODULE=06_spi_master SEQ=all
```

`07_spi_slave`:

```csh
make coverage MODULE=07_spi_slave SEQ=smoke
make coverage MODULE=07_spi_slave SEQ=directed
make coverage MODULE=07_spi_slave SEQ=mode
make coverage MODULE=07_spi_slave SEQ=abort
make coverage MODULE=07_spi_slave SEQ=reset
make coverage MODULE=07_spi_slave SEQ=jitter
make coverage MODULE=07_spi_slave SEQ=corner
make coverage MODULE=07_spi_slave SEQ=byte_sweep
make coverage MODULE=07_spi_slave SEQ=full_random
make coverage MODULE=07_spi_slave SEQ=all
```

`08_i2c_master`:

```csh
make coverage MODULE=08_i2c_master SEQ=smoke
make coverage MODULE=08_i2c_master SEQ=directed
make coverage MODULE=08_i2c_master SEQ=error
make coverage MODULE=08_i2c_master SEQ=reset
make coverage MODULE=08_i2c_master SEQ=jitter
make coverage MODULE=08_i2c_master SEQ=corner
make coverage MODULE=08_i2c_master SEQ=byte_sweep
make coverage MODULE=08_i2c_master SEQ=full_random
make coverage MODULE=08_i2c_master SEQ=all
```

`09_i2c_slave`:

```csh
make coverage MODULE=09_i2c_slave SEQ=smoke
make coverage MODULE=09_i2c_slave SEQ=directed
make coverage MODULE=09_i2c_slave SEQ=error
make coverage MODULE=09_i2c_slave SEQ=reset
make coverage MODULE=09_i2c_slave SEQ=jitter
make coverage MODULE=09_i2c_slave SEQ=corner
make coverage MODULE=09_i2c_slave SEQ=byte_sweep
make coverage MODULE=09_i2c_slave SEQ=full_random
make coverage MODULE=09_i2c_slave SEQ=all
```

`SEQ=all`은 directed, error/reset/jitter/corner/byte_sweep 등을 묶어 functional coverage를 채우는 용도다. `SEQ=full_random`은 random 전용 sequence라 `all` 안에는 기본 포함되어 있지 않다.

## Random count 조절

`full_random`의 개수는 `RUN_ARGS`로 직접 넘긴다.

```csh
make run MODULE=04_uart_rx SEQ=full_random RUN_ARGS="+UART_RX_SEQ=full_random +UART_RX_RANDOM_COUNT=1024"
make run MODULE=05_uart_tx SEQ=full_random RUN_ARGS="+UART_TX_SEQ=full_random +UART_TX_RANDOM_COUNT=1024"
make run MODULE=06_spi_master SEQ=full_random RUN_ARGS="+SPI_MASTER_SEQ=full_random +SPI_MASTER_RANDOM_COUNT=1024"
make run MODULE=07_spi_slave SEQ=full_random RUN_ARGS="+SPI_SLAVE_SEQ=full_random +SPI_SLAVE_RANDOM_COUNT=1024"
make run MODULE=08_i2c_master SEQ=full_random RUN_ARGS="+I2C_MASTER_SEQ=full_random +I2C_MASTER_RANDOM_COUNT=1024"
make run MODULE=09_i2c_slave SEQ=full_random RUN_ARGS="+I2C_SLAVE_SEQ=full_random +I2C_SLAVE_RANDOM_COUNT=1024"
```

## Verdi 실행

VNC 화면에서 Verdi GUI를 보려면 `DISPLAY`가 `:17`이어야 한다.

```csh
setenv DISPLAY :17
make verdi_all MODULE=01_adder
make verdi_all MODULE=04_uart_rx SEQ=all
```

이미 coverage/run 산출물이 있고 Verdi만 다시 열고 싶으면 module의 `tb` 폴더에서 직접 열 수도 있다.

```csh
cd ~/UVM_TEST/04_uart_rx/tb
source ~/.cshrc
setenv DISPLAY :17
verdi -full64 -dbdir simv.daidir -ssf novas.fsdb -top tb_uart_rx -cov -covdir simv.vdb &
```

Top 이름:

| MODULE | TOP |
| --- | --- |
| `01_adder` | `tb_adder` |
| `02_ram` | `tb_ram` |
| `03_fifo` | `tb_fifo` |
| `04_uart_rx` | `tb_uart_rx` |
| `05_uart_tx` | `tb_uart_tx` |
| `06_spi_master` | `tb_spi_master` |
| `07_spi_slave` | `tb_spi_slave` |
| `08_i2c_master` | `tb_i2c_master` |
| `09_i2c_slave` | `tb_i2c_slave` |

Verdi에서 마우스 커서가 안 움직이면 VNC cursor 상태가 꼬인 경우가 있다.

```csh
setenv DISPLAY :17
xsetroot -cursor_name left_ptr
```

## Windows PowerShell에서 실행

Windows에서 직접 `make`를 치면 `vcs`를 못 찾아 실패할 수 있다. Windows에서는 wrapper를 써서 remote Linux에서 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\common\scripts\remote_make_uvm.ps1 -Dir . -Target list
powershell -ExecutionPolicy Bypass -File .\common\scripts\remote_make_uvm.ps1 -Dir . -Target coverage -MakeArgs MODULE=04_uart_rx,SEQ=all
powershell -ExecutionPolicy Bypass -File .\common\scripts\remote_make_uvm.ps1 -Dir . -Target clean -MakeArgs MODULE=04_uart_rx
```

wrapper 기본값:

| 옵션 | 기본값 | 의미 |
| --- | --- | --- |
| `-RemoteHost` | `remote-target` | SSH config alias |
| `-RemoteRoot` | `/home/hedu17/UVM_TEST` | remote project root |
| `-Dir` | `.` | remote root 기준 실행 위치 |
| `-Target` | `help` | make target |
| `-MakeArgs` | 없음 | `MODULE=...`, `SEQ=...` 같은 make 변수 |

`-MakeArgs`는 쉼표로 여러 개를 넘기는 형태가 가장 편하다.

```powershell
-MakeArgs MODULE=06_spi_master,SEQ=all
```

## Make 변수 override

필요할 때 command line에서 바꿀 수 있는 주요 변수다.

| 변수 | 기본값 | 용도 |
| --- | --- | --- |
| `MODULE` | `01_adder` | 루트 Makefile에서 선택할 module |
| `SEQ` | `smoke` 또는 TB 기본값 | 04~09 sequence 선택 |
| `VCS` | `vcs` | VCS executable override |
| `VERDI` | `verdi` | Verdi executable override |
| `URG` | `urg` | URG executable override |
| `COV_METRICS` | `line+cond+fsm+tgl+branch+assert` | VCS coverage metric |
| `COV_DIR` | `simv.vdb` | coverage database directory |
| `RUN_ARGS` | `+<SEQ_ARG>=$(SEQ)` | simulation plusargs override |
| `TOP` | module별 top | top module override, 보통 건드리지 않음 |
| `FILELIST` | `files.f` | 04~09 filelist override |

예시:

```csh
make coverage MODULE=04_uart_rx SEQ=all COV_DIR=simv_uart_rx.vdb
make run MODULE=06_spi_master RUN_ARGS="+SPI_MASTER_SEQ=full_random +SPI_MASTER_RANDOM_COUNT=2048"
make coverage MODULE=09_i2c_slave COV_METRICS=line+cond+branch+assert
```

## 산출물

각 module의 `tb` 폴더에 생성된다.

| 파일/폴더 | 의미 |
| --- | --- |
| `simv` | VCS simulation binary |
| `simv.daidir` | Verdi KDB |
| `simv.vdb` | VCS coverage database |
| `urgReport/dashboard.html` | URG HTML coverage report |
| `novas.fsdb` | Verdi waveform |
| `build.log` | compile log |
| `run.log` | simulation log |
| `novas_dump.log` | FSDB dump log |

## 전체 9개를 순서대로 돌리기

```csh
cd ~/UVM_TEST
source ~/.cshrc

make coverage MODULE=01_adder
make coverage MODULE=02_ram
make coverage MODULE=03_fifo
make coverage MODULE=04_uart_rx SEQ=all
make coverage MODULE=05_uart_tx SEQ=all
make coverage MODULE=06_spi_master SEQ=all
make coverage MODULE=07_spi_slave SEQ=all
make coverage MODULE=08_i2c_master SEQ=all
make coverage MODULE=09_i2c_slave SEQ=all
```

## 자주 나는 문제

### Windows에서 `CreateProcess(NULL, vcs ...) failed`

Windows local shell에서 실행해서 그렇다. VNC terminal 또는 remote wrapper를 사용한다.

### `vcs: command not found`

원격 shell에서 Synopsys 환경을 안 올린 상태다.

```csh
source ~/.cshrc
which vcs
which verdi
which urg
```

### Verdi 창이 안 뜸

`DISPLAY`를 확인한다.

```csh
setenv DISPLAY :17
echo $DISPLAY
make verdi_all MODULE=04_uart_rx SEQ=all
```

### Verdi는 떴는데 waveform이 비어 있음

해당 module의 `tb` 폴더에 `novas.fsdb`가 있는지 확인한다.

```csh
ls -lh ~/UVM_TEST/04_uart_rx/tb/novas.fsdb
```

없으면 `coverage` 또는 `run`을 먼저 돌린다.

```csh
make coverage MODULE=04_uart_rx SEQ=all
```

### 예전 결과가 섞이는 느낌

`clean` 후 다시 돌린다.

```csh
make clean MODULE=04_uart_rx
make coverage MODULE=04_uart_rx SEQ=all
```

## 현재 검증된 상태

2026-05-31 기준으로 9개 module 모두 remote VCS에서 실행 확인했다.

- `UVM_ERROR=0`
- `UVM_FATAL=0`
- `urgReport/dashboard.html` 생성
- `simv.daidir` 생성
- `simv.vdb` 생성
- `novas.fsdb` 생성

자세한 결과 요약은 `docs/portfolio/vcs_verdi_run_summary_2026-05-31.md`를 보면 된다.
