# Basic RTL/UVM Portfolio

Adder, RAM, FIFO 기본 RTL과 UVM 검증환경을 정리한 포트폴리오용 실습 묶음입니다.

## 구성

- `adder/rtl/adder.sv`, `adder/tb`: parameterized combinational adder와 UVM testbench
- `ram/rtl/ram.sv`, `ram/tb`: synchronous single-port RAM과 UVM testbench, scoreboard, functional coverage, SVA
- `fifo/rtl/sync_fifo.sv`, `fifo/tb`: synchronous FIFO와 UVM testbench, scoreboard, functional coverage, interface SVA
- `docs/diagrams`: 별도 SVG 구조도/타이밍 다이어그램 초안

## 실행 방법

`basic` 디렉터리에서 Makefile로 실행합니다.

```sh
make run BLOCK=adder
make run BLOCK=ram
make run BLOCK=fifo
```

자주 쓰는 명령은 아래처럼 줄여서 실행할 수 있습니다.

```sh
make adder          # adder compile + simulation
make ram            # ram compile + simulation
make fifo           # fifo compile + simulation
make run-all        # adder, ram, fifo 순서대로 실행
make clean          # 전체 시뮬레이션 산출물 삭제
```

VCS/Verdi 관련 target도 같은 방식으로 사용합니다.

```sh
make compile BLOCK=adder    # VCS compile only
make lint BLOCK=ram         # vlogan compile check
make wave BLOCK=fifo        # simulation 후 simv.daidir design DB와 novas.fsdb 파형을 Verdi로 열기
make verdi BLOCK=fifo       # wave와 동일
make coverage BLOCK=adder   # simulation 후 simv.vdb + urgReport 생성
make verdi_cov BLOCK=adder  # coverage 생성 후 Verdi coverage view만 실행
make verdi_all BLOCK=adder  # coverage 생성 후 waveform + coverage를 함께 Verdi로 열기
make urg BLOCK=adder        # 기존 simv.vdb에서 URG report만 생성
make clean-block BLOCK=adder # 특정 블록 산출물만 삭제
```

`run`을 실행하면 testbench의 `$fsdbDumpfile("novas.fsdb")` 설정에 따라 파형 파일이 생성됩니다. `make verdi BLOCK=<name>`은 VCS `-kdb`로 생성된 `simv.daidir` design DB와 `novas.fsdb` 파형을 함께 열도록 구성되어 있습니다. coverage는 VCS `-cm line+cond+fsm+tgl+branch+assert` 옵션으로 `simv.vdb`에 저장되고, `make coverage BLOCK=<name>`을 실행하면 `urgReport` HTML 리포트까지 생성됩니다.

각 블록 내부의 `tb/Makefile`을 직접 실행해도 됩니다.

```sh
cd adder && make run
cd ram && make verdi
cd fifo && make clean
```

`tb` 디렉터리 안에서 직접 실행해도 같은 target을 사용할 수 있습니다.

```sh
cd adder/tb && make run
cd adder/tb && make verdi
```

VCS/UVM 1.2 환경을 기준으로 작성했습니다. 시뮬레이션 산출물은 `.gitignore`로 제외했습니다.

## Verdi 실행 메시지 해석

`make verdi BLOCK=adder` 실행 시 아래 메시지는 보통 치명적이지 않습니다.

```text
Fontconfig warning: ... unknown element "reset-dirs"
*WARN* Cannot open .../novas.conf for read access.
guiConfFile (write)= .../novas.conf
```

- `Fontconfig warning`: Linux font 설정 경고입니다. Verdi 실행 자체와는 별개입니다.
- `novas.conf` warning: 기존 Verdi GUI 설정 파일이 없다는 뜻입니다. 최초 실행이면 정상이고, Verdi가 현재 작업 디렉터리에 새 `novas.conf`를 쓸 수 있습니다.

아래 메시지가 실제로 확인해야 할 부분입니다.

```text
*WARN* Verdi-Elite (Verdi) license is not available. Try to check out Verdi-Apex (Verdi-Ultra) license.
```

Verdi GUI license feature를 먼저 `Verdi-Elite`로 시도하고, 없으면 `Verdi-Apex` fallback을 시도한다는 의미입니다. 이 메시지만으로는 실패가 아닐 수 있습니다. 실제로 GUI가 종료되면 아래처럼 license 또는 display 에러가 뒤에 이어지는지 확인합니다.

```text
invalidDisplay::xtInitialize::XtToolkitError::Can't open display:
```

이 경우는 Verdi 문제가 아니라 현재 shell에 GUI display가 없다는 뜻입니다. 원격 접속이면 X forwarding 또는 VNC/GUI 세션에서 실행해야 합니다.

현재 shell에서 다음을 확인합니다.

```sh
which vcs
which verdi
echo "$DISPLAY"
echo "$SNPSLMD_LICENSE_FILE"
echo "$LM_LICENSE_FILE"
lmutil lmstat -a -c "$SNPSLMD_LICENSE_FILE" | grep -E "Verdi|Apex|Elite|VCS"
```

파형 파일 자체는 `make run BLOCK=adder` 성공 후 `adder/tb/novas.fsdb`에 생성됩니다. Verdi GUI가 display 문제로 열리지 않아도 VCS 실행과 FSDB 생성이 완료되었는지는 `novas.fsdb`, `simv.vdb`, simulation log 존재 여부로 먼저 확인할 수 있습니다. coverage HTML은 GUI 없이도 `make urg BLOCK=adder` 또는 `make coverage BLOCK=adder`로 `adder/tb/urgReport`에 생성됩니다.

## 코드 점검 반영

- RTL/TB/문서만 남기고 기존 시뮬레이션 산출물은 제외했습니다.
- RAM/FIFO Makefile 경로와 top/package 파일명을 정리했습니다.
- RAM testbench의 누락된 sequence item과 SVA 파일 연결을 보강했습니다.
- adder directed test를 추가해 zero/max/carry 케이스를 먼저 확인하도록 했습니다.

자세한 설명은 `docs/basic_report_ko.md`를 참고하면 됩니다.

VCS/Verdi 실행 시도 로그와 license/display 진단은 `docs/tool_evidence_ko.md`에 정리했습니다.
