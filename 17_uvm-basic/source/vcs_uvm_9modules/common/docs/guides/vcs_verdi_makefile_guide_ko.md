# VCS/Verdi/Makefile 사용 가이드

이 문서는 `basic` 예제의 Makefile을 기준으로 VCS compile/run, Verdi waveform, coverage/URG 실행 방법을 정리한 실습용 가이드이다. 단순 명령어 나열보다 "어떤 target이 어떤 툴을 어떤 옵션으로 호출하는지"를 이해하는 데 초점을 둔다.

## 1. 전체 실행 구조

현재 `basic` 디렉터리는 루트 Makefile이 각 블록의 `tb/Makefile`로 명령을 넘기는 구조이다.

```text
basic/Makefile
  |
  +-- adder/tb/Makefile
  +-- ram/tb/Makefile
  +-- fifo/tb/Makefile
```

루트에서 실행할 때는 `BLOCK` 변수로 대상을 고른다.

```sh
cd basic
make run BLOCK=adder
make run BLOCK=ram
make run BLOCK=fifo
```

각 블록 `tb` 디렉터리로 들어가서 직접 실행해도 된다.

```sh
cd basic/adder/tb
make run
make verdi
make coverage
```

## 2. 루트 Makefile 사용법

루트 Makefile의 핵심 변수는 다음 두 개이다.

| 변수 | 현재 값 | 의미 |
| --- | --- | --- |
| `BLOCK` | `adder` 기본값 | 실행할 블록 선택 |
| `BLOCKS` | `adder ram fifo` | 허용되는 블록 목록 |

`BLOCK`을 생략하면 기본값인 `adder`가 실행된다.

```sh
make run
make run BLOCK=adder
```

위 두 명령은 같은 의미이다.

루트 Makefile의 주요 target은 다음과 같다.

| Target | 예시 | 동작 |
| --- | --- | --- |
| `help` | `make help` | 사용 가능한 target 출력 |
| `list` | `make list` | 사용 가능한 `BLOCK` 목록 출력 |
| `compile` | `make compile BLOCK=ram` | 선택 블록의 VCS compile |
| `lint` | `make lint BLOCK=fifo` | 선택 블록의 `vlogan` syntax check |
| `run` | `make run BLOCK=adder` | compile 후 simulation 실행 |
| `coverage` | `make coverage BLOCK=ram` | simulation 후 URG report 생성 |
| `urg` | `make urg BLOCK=fifo` | 기존 `simv.vdb`에서 URG report만 재생성 |
| `wave` | `make wave BLOCK=adder` | simulation 후 Verdi waveform 실행 |
| `verdi` | `make verdi BLOCK=adder` | `wave` alias |
| `verdi_cov` | `make verdi_cov BLOCK=ram` | coverage 생성 후 Verdi coverage view 실행 |
| `verdi_all` | `make verdi_all BLOCK=fifo` | waveform과 coverage를 함께 Verdi로 열기 |
| `clean-block` | `make clean-block BLOCK=adder` | 선택 블록 산출물 삭제 |
| `run-all` | `make run-all` | adder, ram, fifo 순서대로 simulation |
| `lint-all` | `make lint-all` | 모든 블록 syntax check |
| `compile-all` | `make compile-all` | 모든 블록 compile |
| `clean` | `make clean` | 모든 블록 산출물 삭제 |

단축 target도 있다.

```sh
make adder
make ram
make fifo
```

각각 아래 명령과 같다.

```sh
make run BLOCK=adder
make run BLOCK=ram
make run BLOCK=fifo
```

## 3. 블록별 tb/Makefile 구조

`adder/tb`, `ram/tb`, `fifo/tb`의 Makefile은 거의 같은 구조이다. DUT 파일, top module 이름, testbench 파일 목록만 다르다.

### 3.1 툴 실행 파일 변수

```make
VCS      ?= vcs
VLOGAN   ?= vlogan
SIMV     ?= ./simv
VERDI    ?= verdi
```

| 변수 | 의미 | 바꿔 쓰는 예 |
| --- | --- | --- |
| `VCS` | VCS compile/elaboration 명령 | `make VCS=/tools/synopsys/vcs/bin/vcs run` |
| `VLOGAN` | `vlogan` compile check 명령 | `make VLOGAN=vlogan lint` |
| `SIMV` | simulation 실행 파일 | `make SIMV=./simv run` |
| `VERDI` | Verdi GUI 실행 명령 | `make VERDI=/tools/synopsys/verdi/bin/verdi verdi` |

`?=`는 "외부에서 값이 들어오면 그 값을 쓰고, 없으면 기본값을 쓴다"는 뜻이다. 그래서 Makefile을 고치지 않고도 command line에서 override할 수 있다.

```sh
make run VCS=/tools/synopsys/vcs/W-2024.09-SP1/bin/vcs
make verdi VERDI=/tools/synopsys/verdi/W-2024.09-SP2/bin/verdi
```

### 3.2 UVM과 coverage 변수

```make
UVM_HOME ?= /tools/synopsys/vcs/W-2024.09-SP1/etc/uvm-1.2
UVM_OPTS ?= -ntb_opts uvm-1.2
COV_METRICS ?= line+cond+fsm+tgl+branch+assert
COV_DIR ?= simv.vdb
```

| 변수 | 의미 |
| --- | --- |
| `UVM_HOME` | VCS에 포함된 UVM 1.2 library 위치 |
| `UVM_OPTS` | VCS에 UVM 1.2 사용을 알리는 옵션 |
| `COV_METRICS` | VCS code coverage metric 선택 |
| `COV_DIR` | coverage database 출력 디렉터리 |

coverage metric은 필요에 따라 줄일 수 있다.

```sh
make run COV_METRICS=line+cond
make coverage COV_METRICS=line+cond+tgl
make run COV_DIR=adder_cov.vdb
```

### 3.3 compile option 변수

```make
VLOGAN_FLAGS := -full64 -sverilog -timescale=1ns/1ps
VCS_FLAGS    := -full64 -sverilog $(UVM_OPTS) -debug_access+all -kdb -lca -timescale=1ns/1ps
COV_FLAGS    := -cm $(COV_METRICS) -cm_dir $(COV_DIR)
INCDIRS      := +incdir+$(UVM_HOME) +incdir+$(TB_DIR)
```

| 옵션 | 사용 위치 | 의미 |
| --- | --- | --- |
| `-full64` | `vcs`, `vlogan`, `verdi` | 64-bit mode 사용 |
| `-sverilog` | `vcs`, `vlogan` | SystemVerilog 문법 사용 |
| `-timescale=1ns/1ps` | `vcs`, `vlogan` | 기본 simulation time unit/precision 지정 |
| `-ntb_opts uvm-1.2` | `vcs` | VCS 내장 UVM 1.2 compile/link |
| `-debug_access+all` | `vcs` | Verdi/DVE debug 접근 정보 생성 |
| `-kdb` | `vcs` | Verdi KDB design database 생성 |
| `-lca` | `vcs` | VCS limited customer availability option. 일부 debug/coverage 기능에 필요할 수 있음 |
| `-cm ...` | `vcs`, `simv` | coverage metric 지정 |
| `-cm_dir ...` | `vcs`, `simv`, `urg` | coverage DB 디렉터리 지정 |
| `+incdir+...` | `vcs`, `vlogan` | `include` 파일 검색 경로 추가 |

현재 Makefile은 compile 단계와 run 단계 모두에 `COV_FLAGS`를 넣는다. VCS coverage는 compile 때 instrumentation이 들어가고, run 때 실제 coverage database가 기록된다.

## 4. 자주 추가하는 VCS 옵션

현재 Makefile에 이미 들어간 옵션 외에도, 실습이나 디버깅 상황에서 자주 쓰는 옵션들이 있다. 프로젝트마다 license, VCS version, coding style에 따라 지원 여부가 조금씩 다를 수 있으니 필요한 것만 골라서 붙이는 것이 좋다.

### 4.1 compile/elaboration 옵션

| 옵션 | 예시 | 용도 |
| --- | --- | --- |
| `-f <filelist>` | `vcs -f filelist.f` | source 파일 목록을 별도 파일에서 읽기 |
| `+incdir+<dir>` | `+incdir+./include` | `include` 검색 경로 추가 |
| `+define+<MACRO>` | `+define+SIM` | compile macro 정의 |
| `+define+NAME=VALUE` | `+define+DATA_WIDTH=32` | 값이 있는 macro 정의 |
| `-top <module>` | `-top tb_fifo` | simulation top module 지정 |
| `-o <name>` | `-o simv_fifo` | 생성할 simulator 실행 파일 이름 지정 |
| `-l <log>` | `-l compile.log` | compile log 파일 저장 |
| `-Mdir=<dir>` | `-Mdir=csrc_fifo` | generated compile directory 이름 지정 |
| `-assert svaext` | `-assert svaext` | SVA 관련 compile 설정이 필요할 때 사용 |
| `-debug_access+r` | `-debug_access+r` | read 중심 debug access만 부여 |
| `-debug_access+all` | `-debug_access+all` | full debug access. Verdi debug에 유리하지만 compile/runtime 부담 증가 |

예시:

```sh
vcs -full64 -sverilog -ntb_opts uvm-1.2 \
  -debug_access+all -kdb \
  +define+SIM +incdir+./include \
  -f filelist.f \
  -top tb_my_dut -o simv \
  -l compile.log
```

filelist 예시는 다음과 같다.

```text
+incdir+./include
+incdir+./tb
./tb/my_if.sv
./tb/tb_my_dut_pkg.sv
./tb/tb_my_dut.sv
./rtl/my_dut.sv
```

Makefile에서는 이렇게 연결할 수 있다.

```make
FILELIST ?= filelist.f

compile:
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) -f $(FILELIST) -top $(TOP) -o simv -l compile.log
```

### 4.2 simulation runtime 옵션

| 옵션 | 예시 | 용도 |
| --- | --- | --- |
| `-l <log>` | `./simv -l sim.log` | simulation log 파일 저장 |
| `+UVM_TESTNAME=<test>` | `+UVM_TESTNAME=fifo_test` | UVM test 선택 |
| `+UVM_VERBOSITY=<level>` | `+UVM_VERBOSITY=UVM_HIGH` | UVM message verbosity 조절 |
| `+ntb_random_seed=<seed>` | `+ntb_random_seed=1` | random seed 고정 |
| `+ntb_random_seed_automatic` | `+ntb_random_seed_automatic` | 실행마다 random seed 자동 선택 |
| `-cm <metrics>` | `-cm line+cond+tgl` | runtime coverage 수집 |
| `-cm_dir <dir>` | `-cm_dir simv.vdb` | coverage DB 위치 지정 |

예시:

```sh
./simv +UVM_TESTNAME=fifo_test \
  +UVM_VERBOSITY=UVM_MEDIUM \
  +ntb_random_seed=1234 \
  -cm line+cond+fsm+tgl+branch+assert \
  -cm_dir simv.vdb \
  -l sim.log
```

Makefile에서는 `RUN_OPTS`, `SEED`, `LOG` 변수를 열어두면 편하다.

```make
RUN_OPTS ?=
SEED ?= 1
SIM_LOG ?= sim.log

run: compile
	$(SIMV) $(COV_FLAGS) +ntb_random_seed=$(SEED) $(RUN_OPTS) -l $(SIM_LOG)
```

사용 예시:

```sh
make run SEED=100
make run RUN_OPTS="+UVM_TESTNAME=fifo_test +UVM_VERBOSITY=UVM_HIGH"
make run SIM_LOG=fifo_seed_100.log SEED=100
```

### 4.3 Verdi 옵션

| 옵션 | 예시 | 용도 |
| --- | --- | --- |
| `-ssf <fsdb>` | `-ssf novas.fsdb` | FSDB waveform 파일 열기 |
| `-dbdir <dir>` | `-dbdir simv.daidir` | VCS debug database 지정 |
| `-top <top>` | `-top tb_ram` | top scope 지정 |
| `-cov` | `verdi -cov` | coverage mode 실행 |
| `-covdir <vdb>` | `-covdir simv.vdb` | coverage DB 지정 |
| `-nologo` | `verdi -nologo` | 시작 banner 생략 |

waveform만 직접 열 때:

```sh
verdi -full64 -dbdir simv.daidir -ssf novas.fsdb -top tb_fifo &
```

coverage만 직접 열 때:

```sh
verdi -full64 -cov -covdir simv.vdb &
```

waveform과 coverage를 함께 열 때:

```sh
verdi -full64 -dbdir simv.daidir -ssf novas.fsdb -top tb_fifo -cov -covdir simv.vdb &
```

### 4.4 URG 옵션

| 옵션 | 예시 | 용도 |
| --- | --- | --- |
| `-dir <vdb>` | `-dir simv.vdb` | 입력 coverage DB 지정 |
| `-report <dir>` | `-report urgReport` | HTML report 출력 디렉터리 지정 |
| `-format both` | `-format both` | HTML/text 등 report format 지정이 필요할 때 사용 |

기본 예시:

```sh
urg -dir simv.vdb -report urgReport
```

DB 이름을 다르게 쓴 경우:

```sh
urg -dir fifo_debug.vdb -report fifo_debug_urg
```

## 5. VCS 사용 흐름

### 5.1 syntax/lint check

```sh
cd basic
make lint BLOCK=adder
make lint BLOCK=ram
make lint BLOCK=fifo
```

하위 Makefile에서는 대략 아래 명령이 실행된다.

```sh
vlogan -full64 -sverilog -timescale=1ns/1ps \
  +incdir+/tools/synopsys/vcs/W-2024.09-SP1/etc/uvm-1.2 \
  +incdir+. \
  ./tb_adder_pkg.sv ./tb_adder.sv ../rtl/adder.sv
```

`lint` target은 엄밀한 lint tool은 아니고, `vlogan`으로 문법과 compile 가능 여부를 빠르게 확인하는 용도이다.

### 5.2 compile only

```sh
make compile BLOCK=adder
```

하위 Makefile에서는 대략 아래 형태의 VCS 명령이 실행된다.

```sh
vcs -full64 -sverilog -ntb_opts uvm-1.2 \
  -debug_access+all -kdb -lca -timescale=1ns/1ps \
  -cm line+cond+fsm+tgl+branch+assert -cm_dir simv.vdb \
  +incdir+/tools/synopsys/vcs/W-2024.09-SP1/etc/uvm-1.2 \
  +incdir+. \
  ./adder_if.sv ./tb_adder_pkg.sv ./tb_adder.sv ../rtl/adder.sv \
  -top tb_adder -o simv
```

compile 성공 후 주요 산출물은 다음과 같다.

| 산출물 | 의미 |
| --- | --- |
| `simv` | VCS가 생성한 simulation executable |
| `simv.daidir/` | VCS compile/debug database |
| `csrc/` | generated C/C++ compile 작업 디렉터리 |
| `AN.DB/` | analysis database |

### 5.3 simulation run

```sh
make run BLOCK=adder
```

`run`은 `compile`을 먼저 실행한 뒤 아래 명령을 실행한다.

```sh
./simv -cm line+cond+fsm+tgl+branch+assert -cm_dir simv.vdb
```

simulation 성공 후 확인할 것은 다음과 같다.

| 항목 | 확인 방법 |
| --- | --- |
| UVM 결과 | log에서 `UVM_ERROR : 0`, `UVM_FATAL : 0` 확인 |
| waveform | `novas.fsdb` 생성 확인 |
| coverage DB | `simv.vdb/` 생성 확인 |
| functional coverage | log의 `Functional coverage = ...` 메시지 확인 |

현재 testbench top에는 FSDB dump가 들어 있다.

```systemverilog
initial begin
  $fsdbDumpfile("novas.fsdb");
  $fsdbDumpvars(0, tb_adder);
end
```

RAM/FIFO도 각각 `tb_ram`, `tb_fifo` scope로 `novas.fsdb`를 생성한다.

### 5.4 UVM plusarg 예시

현재 top에서는 `run_test("adder_test")`처럼 test 이름을 직접 넘긴다. 나중에 여러 test를 선택하고 싶으면 top을 아래처럼 바꿀 수 있다.

```systemverilog
initial begin
  run_test();
end
```

그 다음 command line에서 UVM test를 선택한다.

```sh
./simv +UVM_TESTNAME=adder_test
./simv +UVM_TESTNAME=ram_test +UVM_VERBOSITY=UVM_MEDIUM
./simv +UVM_TESTNAME=fifo_test +UVM_VERBOSITY=UVM_HIGH
```

Makefile에 run option 변수를 추가하면 더 편하다.

```make
RUN_OPTS ?=

run: compile
	$(SIMV) $(COV_FLAGS) $(RUN_OPTS)
```

사용 예시는 다음과 같다.

```sh
make run BLOCK=fifo RUN_OPTS="+UVM_TESTNAME=fifo_test +UVM_VERBOSITY=UVM_HIGH"
```

## 6. Coverage와 URG 사용법

### 6.1 coverage 생성

```sh
make coverage BLOCK=adder
```

이 target은 아래 순서로 동작한다.

```text
make run
urg -dir simv.vdb -report urgReport
```

즉, simulation을 다시 돌린 뒤 `simv.vdb`에서 HTML coverage report를 만든다.

### 6.2 기존 DB에서 report만 다시 만들기

이미 `simv.vdb`가 있으면 simulation을 다시 돌리지 않고 URG만 실행할 수 있다.

```sh
make urg BLOCK=adder
```

하위 Makefile 명령은 다음과 같다.

```sh
urg -dir simv.vdb -report urgReport
```

### 6.3 coverage metric 조절 예시

빠르게 line coverage만 보고 싶을 때:

```sh
make coverage BLOCK=adder COV_METRICS=line
```

line/condition/toggle만 보고 싶을 때:

```sh
make coverage BLOCK=ram COV_METRICS=line+cond+tgl
```

assertion coverage까지 포함해서 기본 설정으로 돌릴 때:

```sh
make coverage BLOCK=fifo COV_METRICS=line+cond+fsm+tgl+branch+assert
```

coverage DB 이름을 다르게 저장하고 싶을 때:

```sh
make coverage BLOCK=adder COV_DIR=simv_adder_smoke.vdb
make coverage BLOCK=adder COV_DIR=simv_adder_regression.vdb
```

## 7. Verdi 사용법

### 7.1 waveform 열기

```sh
make verdi BLOCK=adder
```

`verdi`는 `wave` target의 alias이다. 실제 실행 흐름은 다음과 같다.

```text
make run
verdi -full64 -dbdir simv.daidir -ssf novas.fsdb -top tb_adder &
```

옵션 의미는 다음과 같다.

| 옵션 | 의미 |
| --- | --- |
| `-full64` | 64-bit Verdi 실행 |
| `-dbdir simv.daidir` | VCS compile/debug database 지정 |
| `-ssf novas.fsdb` | waveform file 지정 |
| `-top tb_adder` | top scope 지정 |
| `&` | Linux shell에서 background 실행 |

블록별 top 이름은 다음과 같다.

| BLOCK | Verdi top |
| --- | --- |
| `adder` | `tb_adder` |
| `ram` | `tb_ram` |
| `fifo` | `tb_fifo` |

### 7.2 coverage GUI 열기

```sh
make verdi_cov BLOCK=ram
```

실제 실행 흐름은 다음과 같다.

```text
make coverage
verdi -full64 -cov -covdir simv.vdb &
```

옵션 의미는 다음과 같다.

| 옵션 | 의미 |
| --- | --- |
| `-cov` | Verdi coverage mode 실행 |
| `-covdir simv.vdb` | VCS coverage DB 지정 |

### 7.3 waveform과 coverage 같이 열기

```sh
make verdi_all BLOCK=fifo
```

실제 실행 명령은 다음 형태이다.

```sh
verdi -full64 -dbdir simv.daidir -ssf novas.fsdb -top tb_fifo -cov -covdir simv.vdb &
```

### 7.4 Verdi에서 볼 signal 예시

| BLOCK | 먼저 볼 signal |
| --- | --- |
| `adder` | `iA`, `iB`, `oY`, `oY[DATA_WIDTH]` carry bit |
| `ram` | `iClk`, `iRstn`, `iCs`, `iWea`, `iAddr`, `iWData`, `oRData` |
| `fifo` | `iClk`, `iRstn`, `iWrEn`, `iRdEn`, `iWData`, `oRData`, `oCount`, `oFull`, `oEmpty` |

### 7.5 GUI/display 확인

Verdi는 GUI tool이라서 terminal에서 display가 잡혀 있어야 한다.

```sh
echo "$DISPLAY"
which verdi
verdi -version
```

원격 서버에서 `DISPLAY`가 비어 있으면 Verdi GUI가 뜨지 않는다. 이 경우 X forwarding, VNC, NoMachine 같은 GUI 세션에서 실행해야 한다.

license도 확인한다.

```sh
echo "$SNPSLMD_LICENSE_FILE"
echo "$LM_LICENSE_FILE"
lmutil lmstat -a -c "$SNPSLMD_LICENSE_FILE" | grep -E "VCS|Verdi|Apex|Elite|URG|Coverage"
```

## 8. 자주 쓰는 명령 예시

### 8.1 기본 smoke test

```sh
cd basic
make clean-block BLOCK=adder
make lint BLOCK=adder
make run BLOCK=adder
```

### 8.2 세 블록 전체 실행

```sh
cd basic
make clean
make lint-all
make run-all
```

### 8.3 RAM만 coverage report 생성

```sh
cd basic
make coverage BLOCK=ram
```

결과:

```text
basic/ram/tb/simv.vdb/
basic/ram/tb/urgReport/
```

### 8.4 기존 FIFO coverage DB에서 URG만 재생성

```sh
cd basic
make urg BLOCK=fifo
```

### 8.5 Adder waveform만 확인

```sh
cd basic
make verdi BLOCK=adder
```

결과:

```text
basic/adder/tb/novas.fsdb
basic/adder/tb/simv.daidir
```

### 8.6 Verdi coverage view 확인

```sh
cd basic
make verdi_cov BLOCK=fifo
```

### 8.7 VCS/UVM 경로 override

```sh
cd basic
make run BLOCK=adder \
  UVM_HOME=/tools/synopsys/vcs/W-2024.09-SP1/etc/uvm-1.2 \
  UVM_OPTS="-ntb_opts uvm-1.2"
```

### 8.8 coverage metric 줄여서 빠르게 실행

```sh
cd basic
make run BLOCK=ram COV_METRICS=line+cond
```

### 8.9 coverage DB 이름 바꿔서 보관

```sh
cd basic
make coverage BLOCK=fifo COV_DIR=fifo_debug.vdb
```

### 8.10 실제 하위 디렉터리에서 직접 실행

```sh
cd basic/fifo/tb
make clean
make compile
make run
make verdi
```

## 9. 현재 Makefile에 있는 target 의존 관계

하위 `tb/Makefile`의 target 관계는 다음처럼 이해하면 된다.

```text
all      -> compile
run      -> compile -> ./simv
coverage -> run -> urg
wave     -> run -> verdi waveform
verdi    -> wave
verdi_cov -> coverage -> verdi coverage
verdi_all -> coverage -> verdi waveform + coverage
```

주의할 점은 `wave`, `verdi`, `verdi_cov`, `verdi_all`이 모두 simulation 또는 coverage를 다시 실행한다는 점이다. 이미 생성된 `novas.fsdb`만 열고 싶다면 `tb` 디렉터리에서 Verdi를 직접 실행하면 된다.

```sh
cd basic/adder/tb
verdi -full64 -dbdir simv.daidir -ssf novas.fsdb -top tb_adder &
```

이미 생성된 coverage DB만 열고 싶을 때:

```sh
cd basic/adder/tb
verdi -full64 -cov -covdir simv.vdb &
```

## 10. Makefile 예시

### 10.1 가장 작은 VCS Makefile 예시

단일 RTL과 단일 TB만 compile/run 하는 최소 예시이다.

```make
VCS ?= vcs
SIMV ?= ./simv

VCS_FLAGS := -full64 -sverilog -timescale=1ns/1ps

RTL_SRCS := ../rtl/my_dut.sv
TB_SRCS  := ./tb_my_dut.sv

.PHONY: compile run clean

compile:
	$(VCS) $(VCS_FLAGS) $(TB_SRCS) $(RTL_SRCS) -top tb_my_dut -o simv

run: compile
	$(SIMV)

clean:
	rm -rf simv simv.daidir csrc ucli.key *.log
```

### 10.2 UVM + Verdi + coverage Makefile 예시

현재 프로젝트 구조와 가장 비슷한 예시이다.

```make
VCS      ?= vcs
VLOGAN   ?= vlogan
SIMV     ?= ./simv
VERDI    ?= verdi
UVM_HOME ?= /tools/synopsys/vcs/W-2024.09-SP1/etc/uvm-1.2
UVM_OPTS ?= -ntb_opts uvm-1.2

COV_METRICS ?= line+cond+fsm+tgl+branch+assert
COV_DIR     ?= simv.vdb
RUN_OPTS    ?=

RTL_DIR := ../rtl
TB_DIR  := .
TOP     := tb_my_dut

VLOGAN_FLAGS := -full64 -sverilog -timescale=1ns/1ps
VCS_FLAGS    := -full64 -sverilog $(UVM_OPTS) -debug_access+all -kdb -lca -timescale=1ns/1ps
COV_FLAGS    := -cm $(COV_METRICS) -cm_dir $(COV_DIR)
INCDIRS      := +incdir+$(UVM_HOME) +incdir+$(TB_DIR)

RTL_SRCS := $(RTL_DIR)/my_dut.sv
TB_SRCS  := $(TB_DIR)/my_if.sv \
            $(TB_DIR)/tb_my_dut_pkg.sv \
            $(TB_DIR)/tb_my_dut.sv

.PHONY: all compile lint run coverage urg verdi verdi_cov verdi_all clean

all: compile

lint:
	$(VLOGAN) $(VLOGAN_FLAGS) $(INCDIRS) $(UVM_HOME)/uvm_pkg.sv $(TB_SRCS) $(RTL_SRCS)

compile:
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) $(INCDIRS) $(TB_SRCS) $(RTL_SRCS) -top $(TOP) -o simv

run: compile
	$(SIMV) $(COV_FLAGS) $(RUN_OPTS)

coverage: run urg

urg:
	urg -dir $(COV_DIR) -report urgReport

verdi: run
	$(VERDI) -full64 -dbdir simv.daidir -ssf novas.fsdb -top $(TOP) &

verdi_cov: coverage
	$(VERDI) -full64 -cov -covdir $(COV_DIR) &

verdi_all: coverage
	$(VERDI) -full64 -dbdir simv.daidir -ssf novas.fsdb -top $(TOP) -cov -covdir $(COV_DIR) &

clean:
	rm -rf simv simv.daidir csrc ucli.key vc_hdrs.h AN.DB DVEfiles \
	       verdiLog vdCovLog novas.* novas.conf *.fsdb *.log \
	       .*.sch.verilog.xml $(COV_DIR) urgReport
```

사용 예시:

```sh
make run RUN_OPTS="+UVM_TESTNAME=my_smoke_test +UVM_VERBOSITY=UVM_MEDIUM"
make coverage COV_METRICS=line+cond+tgl
make verdi_all COV_DIR=debug_cov.vdb
```

### 10.3 여러 블록을 관리하는 루트 Makefile 예시

`basic/Makefile`처럼 여러 DUT를 한 번에 관리하고 싶을 때 쓸 수 있는 형태이다.

```make
BLOCK ?= adder
BLOCKS := adder ram fifo

.PHONY: help list check-block compile lint run coverage verdi clean clean-all run-all

help:
	@echo "Usage:"
	@echo "  make run BLOCK=adder"
	@echo "  make coverage BLOCK=ram"
	@echo "  make verdi BLOCK=fifo"
	@echo "  make run-all"

list:
	@printf "%s\n" $(BLOCKS)

check-block:
	@if ! printf "%s\n" $(BLOCKS) | grep -qx "$(BLOCK)"; then \
	  echo "Unknown BLOCK='$(BLOCK)'. Use one of: $(BLOCKS)"; \
	  exit 1; \
	fi

compile lint run coverage verdi: check-block
	$(MAKE) -C $(BLOCK)/tb $@

clean: check-block
	$(MAKE) -C $(BLOCK)/tb clean

clean-all:
	@for block in $(BLOCKS); do \
	  $(MAKE) -C $$block/tb clean || exit $$?; \
	done

run-all:
	@for block in $(BLOCKS); do \
	  $(MAKE) run BLOCK=$$block || exit $$?; \
	done
```

## 11. Makefile 작성 팁

새 DUT를 추가할 때는 아래 순서로 진행하면 실수가 적다.

1. `RTL_SRCS`에 DUT RTL 파일을 넣는다.
2. `TB_SRCS`에 interface, package, top 순서로 testbench 파일을 넣는다.
3. `TOP` 또는 `-top`에 testbench top module 이름을 맞춘다.
4. `+incdir+$(TB_DIR)`가 package include 파일 위치를 포함하는지 확인한다.
5. `make lint`로 문법을 먼저 확인한다.
6. `make run`으로 UVM 결과와 `novas.fsdb` 생성을 확인한다.
7. `make coverage`로 `simv.vdb`, `urgReport` 생성을 확인한다.
8. `make verdi` 또는 직접 `verdi -ssf novas.fsdb`로 파형을 확인한다.

자주 나는 문제는 다음과 같다.

| 증상 | 확인할 것 |
| --- | --- |
| `include file not found` | `INCDIRS`에 해당 디렉터리가 있는지 확인 |
| `Top module not found` | `-top` 이름과 실제 top module 이름 일치 여부 |
| `run_test`에서 test를 못 찾음 | package include 순서, `uvm_component_utils`, `+UVM_TESTNAME` 확인 |
| `novas.fsdb`가 없음 | top에 `$fsdbDumpfile`, `$fsdbDumpvars`가 있는지 확인 |
| Verdi GUI가 안 뜸 | `DISPLAY`, Verdi license, GUI 접속 환경 확인 |
| coverage report가 안 만들어짐 | compile/run 양쪽에 `-cm`, `-cm_dir`가 들어갔는지 확인 |

## 12. 포트폴리오에 설명할 때 쓸 수 있는 요약

포트폴리오 문서에는 아래처럼 정리할 수 있다.

```text
VCS 기반 UVM simulation flow를 Makefile로 자동화했다. 루트 Makefile에서 BLOCK 변수를 통해 adder/ram/fifo 검증 대상을 선택하고, 각 블록의 tb/Makefile이 vlogan syntax check, VCS compile, simulation, FSDB waveform dump, VCS coverage DB 생성, URG HTML report, Verdi waveform/coverage GUI 실행을 담당한다.
```

조금 더 짧게 쓰면 다음과 같다.

```text
Makefile targets: lint(vlogan), compile(vcs), run(simv), coverage(URG), verdi(waveform), verdi_cov(coverage GUI), verdi_all(waveform+coverage).
```
