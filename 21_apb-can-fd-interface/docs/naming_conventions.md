# RTL 네이밍·작성 규칙

| 대상 | 규칙 | 실제 예 |
|---|---|---|
| 파일 / 모듈 | 소문자 `snake_case`, 이름 일치 | `apb_can_bridge.sv` |
| 입력 / 출력 | `i` / `o` + PascalCase | `iPaddr`, `oIrq` |
| active-low 입력 | 끝을 대문자 `N` | `iPresetN`, `iRstN` |
| 순차 상태 / 저장값 | `r` + PascalCase | `rCurState`, `rTxData` |
| 다음 상태 | 조합 신호이므로 `w` | `wNxtState` |
| 조합 신호 | `w` + PascalCase | `wTxAccept`, `wRxOverflow` |
| 파라미터 / 상수 | 대문자 `SNAKE_CASE` | `TX_DEPTH`, `FRAME_W`, `ADDR_TX_PUSH` |
| 상태 상수 | 기능 접두사 | `TX_IDLE`, `TX_SEND`, `TX_WAIT_DONE` |
| 인스턴스 | `u_` 접두사 | `u_tx_fifo`, `u_core_model` |
| TB의 DUT 연결 신호 | DUT 포트와 같은 이름 | `.iPaddr(iPaddr)`, `.oIrq(oIrq)` |
| function / task | snake_case | `dlc_bytes`, `enqueue_frame` |
| 반복·검증용 integer | snake_case, `r` 강제하지 않음 | `byte_idx`, `exp_head` |

- 들여쓰기 2칸. `end` 다음 줄에 `else`를 둔다.
- RTL은 `logic`, `always_ff`, `always_comb`, `typedef enum logic`를 사용한다. 순차 블록은 nonblocking, 조합 블록은 blocking 대입을 사용한다.
- 조합 블록은 기본값을 먼저 지정해 latch를 방지한다. 자동 net 생성을 막기 위해 `default_nettype none`을 쓴다.
- 주석은 단순 동작 반복 설명보다 **계약·예외·우선순위**를 설명한다. 예: full에서 동시 POP이 있으면 PUSH 허용, W1C보다 신규 이벤트 우선.
- 코드 주석은 도구 호환성을 위해 짧은 영어를 사용하고, 설계 설명은 한국어 문서로 제공한다.
- `DATA_W`, `COUNT_W`, `PTR_W`는 비트 폭이고, `DEPTH`는 저장 가능한 **프레임 수**이다.
- APB 이름에도 접두사를 적용한다: `iPclk`, `iPsel`, `oPrdata`. task/function 지역 인수는 module port naming 예외다.
- `default_nettype none`과 함께 XSim이 input의 net kind를 명시하도록 요구하므로 **`input wire logic`**를 사용한다. `wire`는 net kind, `logic`은 4-state data type이다.
- 조합 신호는 `logic wX; assign wX = ...;`로 선언한다. `logic wX = ...;`는 초기화라서 같은 동작이 아니다. TB initial value 설정은 별개다.
- FSM은 `can_tx_ctrl.sv`에 분리하고 state register / next state / output의 3블록으로 표시한다. payload 레지스터는 상위 APB 모듈이 소유한다.
- FIFO 메모리 write와 reset되는 pointer/count를 별도 `always_ff`로 나눈다. reset은 count를 초기화하고 저장 배열을 지우지 않는다.
