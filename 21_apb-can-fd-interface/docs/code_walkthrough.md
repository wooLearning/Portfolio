# 코드 읽는 순서와 동작 설명

`apb_can_bridge.sv`의 입출력·하위 인스턴스 → `can_tx_ctrl.sv`의 FSM → `frame_fifo.sv`의 저장 동작 순서로 읽으면 된다. 이 프로젝트는 **APB로 CAN 프레임을 등록·조회하는 연결부**이며, CAN bus bit 생성·중재는 외부 core 역할이다.

## 1. 전체 흐름

```text
CPU APB write → TX staging → TX_PUSH → TX FIFO
  → TX FSM이 valid 출력 → core ready로 수락·pop → done 대기 → 완료 IRQ

core의 RX complete frame → RX FIFO → CPU가 데이터 읽기 → RX_POP
```

한 frame은 `{ID 11bit, BRS 1bit, FD 1bit, DLC 4bit, payload 512bit}` = 529bit다. APB는 한 번에 32bit를 전달하고 FIFO는 완성 프레임을 한 entry로 관리한다.

## 2. APB 접근 — apb_can_bridge.sv

```systemverilog
assign wApbAccess = iPsel && iPenable;
assign wApbWrite  = wApbAccess && iPwrite && !wApbError;
assign oPready   = 1'b1;
assign oPslverr  = wApbAccess && wApbError;
```

SETUP에서는 레지스터를 바꾸지 않는다. ACCESS에서 오류 없는 write일 때만 `wApbWrite`가 1이 되고 상승 에지에 저장한다. `oPready=1`이라 추가 wait cycle이 없다. 잘못된 주소·접근 방향·full 등은 `wApbError`로 종료하며 데이터는 변경하지 않는다.

읽기 데이터와 오류는 주소 decode `always_comb`에서 계산한다. 먼저 기본값을 지정하므로 선택되지 않은 경로에서도 latch가 생기지 않는다.

## 3. TX staging — 데이터를 다 쓴 뒤 등록

`rTxId`, `rTxCtrl`, `rTxData`는 CPU가 작성 중인 프레임이다. 데이터를 16번에 나눠 쓰는 중에는 core에 전달되지 않는다.

| 신호 | 의미 |
|---|---|
| `rTxWordWritten` | 이번 프레임에 작성한 word의 16bit 마스크 |
| `wTxLengthBytes` | DLC를 실제 byte 수로 변환한 값. DLC=9 → 12byte |
| `wTxRequiredWords` | payload 길이에 필요한 word 마스크 |
| `wTxWordsOk` | 필요한 word가 모두 작성됐는지 검사 |
| `wTxPayload` | 길이 밖 바이트를 0으로 만든 payload |
| `wTxPush` | 형식·작성 완료·공간을 확인한 FIFO 등록 요청 |

7byte 송신이면 DATA[0]과 [1]을 쓴다. 두 번째 word는 하위 3byte만 유효하고 최상위 byte는 PUSH 때 0으로 바뀐다. PUSH 성공 후 작성 마스크를 지워 이전 payload가 실수로 재사용되는 것을 막는다. ID/CTRL은 유지된다.

PUSH가 실패하면 staging도 유지된다. full 때문에 실패했다면 공간이 생긴 뒤 PUSH만 재시도할 수 있다. 미작성 word 때문에 실패했다면 해당 word부터 채워야 한다.

## 4. TX FSM — can_tx_ctrl.sv

1. **Block1**: 상승 에지마다 `rCurState <= wNxtState`. reset이면 IDLE.
2. **Block2**: 현재 상태와 FIFO empty / core ready / done으로 다음 상태 계산.
3. **Block3**: valid / pop / complete / busy 계산. payload 저장은 APB 모듈 담당.

| 상태 | 출력 / 의미 | 전이 |
|---|---|---|
| `TX_IDLE` | valid=0, 프레임 대기 | FIFO nonempty → SEND |
| `TX_SEND` | valid=1, core에 요청 | ready=1 → 수락·pop |
| `TX_WAIT_DONE` | valid=0, 처리 완료 대기 | done=1 → 완료 이벤트, IDLE |

SEND에서 ready=0이면 FIFO를 pop하지 않으므로 frame과 valid가 유지된다. 수락 에지에 core가 frame을 저장해야 하며, 이후 wrapper 출력 데이터는 다음 head 또는 0으로 바뀔 수 있다.

ready 없이 SEND에 들어온 done은 무시한다. ready와 done이 같은 에지에 오면 WAIT_DONE 없이 완료한다. done과 error가 함께 높으면 TX error, error가 낮으면 success를 기록한다.

FIFO는 등록 순서를 유지하며 CAN ID로 재정렬하지 않는다. 노드 간 중재와 protocol retry는 외부 CAN core가 처리한다. wrapper에는 completion timeout이나 자동 재등록이 없다.

## 5. FIFO / RX — frame_fifo.sv

`rMem`은 frame array, `rWrPtr`/`rRdPtr`은 쓰기·읽기 위치, `rCount`는 저장 개수다. reset은 pointer/count만 초기화한다. empty에서는 `oData=0`이므로 과거 memory 내용이 유효 데이터로 노출되지 않는다.

```systemverilog
assign wPopFire   = iPop && !oEmpty;
assign oPushReady = !oFull || wPopFire;
assign wPushFire  = iPush && oPushReady;
```

full이어도 같은 에지에 유효 POP이 있으면 PUSH를 허용한다. count는 유지되고 head가 다음 프레임으로 넘어간다. depth=1도 기존 데이터를 소비하고 새 데이터를 남긴다. pointer가 DEPTH-1에서 0으로 돌아가므로 depth=3,5도 동작한다.

RX는 core가 검증된 complete frame을 1클럭 valid pulse로 전달하는 계약이다. APB 읽기는 비파괴이며 RX_POP만 head를 제거한다. full이고 POP이 없으면 새 frame을 버리고 overflow를 기록한다. empty에서 POP 명령과 수신이 겹치면 POP은 오류지만 새 frame은 저장된다.

## 6. 인터럽트

`wIrqStatus = {rIrqSticky, !wRxEmpty}`다. bit0 RX available은 level, bit1 TX success / bit2 TX error / bit3 RX overflow는 sticky다. `rIrqEnable`은 출력 mask이며 mask가 꺼져 있어도 이벤트는 저장된다.

```systemverilog
rIrqSticky <= (rIrqSticky & ~wIrqClear) | wIrqEvents;
```

SW가 clear하는 에지에 새 이벤트가 오면 마지막 OR로 이벤트가 남는다. 여러 완료는 bit 하나로 합쳐지므로 완료 횟수 카운터로 사용할 수 없다.

## 7. 테스트벤치와 파형 읽기

`tb_apb_can_bridge.sv`에는 APB master task, 독립 예상 frame 배열, TX scoreboard가 있다. core 수락 에지에서 ID/flags/DLC/512bit payload 전체를 비교하고, stall 중 valid와 frame의 안정성을 매 클럭 검사한다.

`can_core_model.sv`는 수락 후 몇 클럭 뒤 done/error를 반환하는 모델이다. 실제 CAN bit rate나 중재 모델이 아니다. RX는 별도로 주입하므로 단순 loopback에서 같은 버그가 가려지는 것을 피한다.

`tb_frame_fifo.sv`는 reference queue와 비교한다. 깊이 1/3/4/8에서 각각 2,000 step을 확인한다. 두 시뮬레이터에서 동일한 입력열을 쓰도록 xorshift PRNG를 사용한다.

처음 볼 파형: `iPsel`, `iPenable`, `iPaddr`, `oPslverr`, `oCanTxValid`, `iCanTxReady`, `dut.u_tx_ctrl.rCurState`, `iCanTxDone`, `dut.wTxCount`, `dut.wRxCount`. `python scripts/run_xsim.py --smoke` 실행 후 `results/xsim/`에 WDB/VCD가 생성된다.
