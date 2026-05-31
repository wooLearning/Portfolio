# VCS/Verdi 실행 증적 정리

## 1. 확인 목적

포트폴리오에 단순 코드만 올리는 것이 아니라, Synopsys VCS/Verdi 기반으로 컴파일, 시뮬레이션, coverage, waveform 확인을 시도했다는 증적을 남기기 위한 문서이다.

현재 세션에서는 license server와 GUI display 문제로 최종 `simv`, `novas.fsdb`, `simv.vdb`, `urgReport`를 새로 생성하지는 못했다. 대신 실제 실행 시도 로그와 환경 진단 로그를 `docs/tool_runs/`에 보관했다.

## 2. Tool Version

| Tool | 확인 결과 | 로그 |
| --- | --- | --- |
| VCS | `W-2024.09-SP1_Full64` | `tool_runs/vcs_version.txt` |
| Verdi | `W-2024.09-SP2` | `tool_runs/verdi_version.txt` |
| URG | `W-2024.09-SP1` 실행 확인, coverage license 없음 | `tool_runs/adder_urg_existing.txt` |

## 3. 실행 명령

세 testbench 모두 coverage option이 들어가도록 Makefile을 정리했다.

```sh
cd basic/adder/tb && make run
cd basic/ram/tb   && make run
cd basic/fifo/tb  && make run
```

dry-run으로 확인한 실제 VCS 명령은 `tool_runs/make_dry_run_all.txt`에 저장했다.

각 testbench의 VCS compile/run은 다음 산출물을 목표로 한다.

| 산출물 | 의미 |
| --- | --- |
| `simv` | VCS compiled simulator |
| `novas.fsdb` | Verdi waveform database |
| `simv.vdb` | VCS coverage database |
| `urgReport/` | URG HTML coverage report |

## 4. 실제 실행 시도 결과

Adder testbench에서 실제 `make clean run`을 실행했다.

```sh
cd basic/adder/tb
make clean
make run
```

결과는 VCS license server 접속 실패로 compile 단계에서 중단되었다.

```text
Cannot connect to the license server.
Failed to obtain license ...
make: *** [Makefile:28: compile] Error 255
```

실행 로그는 `tool_runs/adder_vcs_run.txt`에 저장했다.

## 5. License/Display 진단

환경 진단 결과는 `tool_runs/license_display_check.txt`에 저장했다.

| 항목 | 결과 |
| --- | --- |
| `SNPSLMD_LICENSE_FILE` | `27020@222.234.38.90` |
| license server TCP check | `TCP_FAIL` |
| `lmutil lmstat` | `Cannot connect to license server system` |
| `DISPLAY` | empty |

정리하면, 현재 문제는 단순 compile error가 아니라 license server port 접속 실패이다. 또한 `DISPLAY`가 비어 있어 Verdi GUI 캡처도 현재 terminal 세션에서는 불가능하다.

## 6. 기존 산출물 확인

원본 작업 폴더 `04_ram/tb/adder`에는 이전 실행으로 생성된 산출물이 남아 있었다.

| 파일 | 의미 |
| --- | --- |
| `04_ram/tb/adder/simv` | 기존 VCS compiled simulator |
| `04_ram/tb/adder/novas.fsdb` | 기존 Verdi waveform database |
| `04_ram/tb/adder/simv.vdb/` | 기존 VCS coverage database |

파일 목록은 `tool_runs/artifact_inventory.txt`에 저장했다. 다만 이번 세션에서 URG HTML report를 새로 만들려고 했을 때는 coverage license가 없어 실패했다.

## 7. 정상 환경에서 캡처할 화면

license server와 display가 정상화되면 아래 화면을 캡처해서 포트폴리오 README 또는 보고서에 추가하면 좋다.

| 캡처 | 명령 | 캡처 포인트 |
| --- | --- | --- |
| VCS compile/run terminal | `make run` | `UVM_ERROR : 0`, coverage DB 생성, FSDB 생성 |
| Verdi waveform | `make verdi` | `iA/iB/oY`, `iCs/iWea/iAddr/oRData`, `iWrEn/iRdEn/oCount/oFull/oEmpty` |
| Verdi coverage GUI | `make verdi_cov` | line/cond/tgl/branch/assert coverage summary |
| URG HTML report | `make urg` | dashboard summary, module별 coverage |

한 번에 실행하려면 다음 스크립트를 사용할 수 있다.

```sh
cd basic
bash scripts/run_vcs_verdi_checks.sh
```

실행 결과는 `docs/tool_runs/` 아래에 block별 `*_vcs_run.txt`, `*_urg.txt`, `*_run_summary.txt`로 저장된다.

## 8. 포트폴리오에 쓸 수 있는 문장

현재 환경 기준으로는 다음처럼 적는 것이 정확하다.

> VCS/Verdi W-2024.09 계열 환경에서 실행되도록 Makefile과 dump/coverage option을 구성했다. 현재 원격 세션에서는 Synopsys license server TCP 접속 실패 및 DISPLAY 미설정으로 신규 compile/run과 GUI 캡처는 완료하지 못했으나, VCS/Verdi version 확인, 실제 VCS run 시도 로그, license/display 진단 로그를 함께 남겼다.

license가 정상화된 뒤에는 다음처럼 업데이트할 수 있다.

> Adder/RAM/FIFO testbench를 VCS로 compile/run하고, FSDB waveform과 VCS coverage DB를 생성했다. Verdi에서 waveform을 확인하고 URG로 coverage HTML report를 생성해 검증 결과를 정리했다.
