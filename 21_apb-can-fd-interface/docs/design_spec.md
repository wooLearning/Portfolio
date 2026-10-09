# APB–CAN FD 연결부 설계 명세 v1.0

## 1. 경계와 가정

```text
CPU/APB master
  ↕ 32-bit APB3
APB registers → TX staging → TX FIFO → TX FSM → CAN core adapter
APB registers ← RX FIFO ← validated frame event ← CAN core adapter
                                                  ↕
                                       외부 CAN protocol IP
                                                  ↕ TXD/RXD
                                       외부 차동 transceiver
                                                  ↕ CAN_H/CAN_L
```

이 프로젝트의 top은 `apb_can_bridge`이다. 특정 상용/오픈소스 IP의 native interface를 그대로 구현한 것은 아니다. 아래 frame-level 계약을 정의했으며, 실제 IP 통합 시 adapter가 해당 IP의 message RAM / register / streaming interface와 매핑해야 한다. IP에 이미 FIFO/RAM이 있다면 중복 저장 비용을 다시 검토한다.

- 단일 `iPclk` 도메인. TB는 50 MHz를 사용한다. 서로 다른 CAN core 클록을 연결하려면 별도 CDC가 필요하다.
- `iPresetN`: active-low asynchronous assertion. 시스템에서 reset 해제를 동기화하고 adapter/core도 함께 reset해야 한다.
- APB3 12비트 byte address / 32비트 data. 정렬된 32비트 접근만 지원한다. APB4의 `PSTRB`는 없다.
- `PREADY=1`; 성공한 `PSEL && PENABLE && PWRITE`의 상승 에지에만 write side effect가 발생한다.
- `PSLVERR`는 ACCESS에서만 유효하다. 오류 전송은 완료되지만 쓰기 side effect는 없다.
- 지원 프레임: 11비트 ID, data frame, Classic CAN 0~8바이트 / CAN FD 0~64바이트(DLC mapping).
- extended ID, remote frame, arbitration, CRC, bit stuffing, nominal/data bit timing, ACK, error confinement, bus-off는 외부 CAN core 담당이다.
- 500 kbps / 2 Mbps 등의 실제 CAN 속도는 이 wrapper의 설정 항목이 아니다. 파형의 지연은 handshake 검증용이며 CAN bit time이 아니다.

## 2. 프레임과 저장 구조

각 FIFO entry는 529비트이다: `{ID[10:0], BRS, FD, DLC[3:0], DATA[511:0]}`. `DATA[7:0]`이 payload byte 0이고 APB의 첫 word 하위 바이트에 해당한다. 이 배치는 CAN wire bit order와 별개이며 protocol core가 직렬화한다.

| DLC | 0~8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|---|---|
| bytes | DLC와 동일 | 12 | 16 | 20 | 24 | 32 | 48 | 64 |

TX 기본 4프레임, RX 기본 8프레임. payload 저장량은 768바이트이고 메타데이터까지 FIFO 합계 6,348비트이다. TX staging은 frame 529비트와 written mask 16비트를 추가로 사용한다. 현재 구현은 작은 register FIFO이며 BRAM/SRAM macro 적용을 검증하지 않았다.

`frame_fifo`는 first-word-visible 구조이다. empty일 때 `oData=0`. full에서 유효한 pop과 push가 겹치면 기존 head를 소비하고 새 frame을 저장한다. empty에서 push와 pop이 겹치면 pop은 무시하고 새 데이터가 1개 남는다. pointer는 DEPTH-1에서 명시적으로 wrap하므로 depth=1과 비 2의 거듭제곱도 지원한다. 지원 depth 범위는 1~255이다.

TX depth는 **대기 프레임 수**이고, core가 수락한 1개의 in-flight frame은 포함하지 않는다. FIFO 수락 순서를 유지하며 queued ID를 비교해 재정렬하지 않는다. CAN 버스의 노드 간 중재는 protocol core가 수행한다.

## 3. 레지스터 맵

| 주소 | 이름 | 접근 | 정의 |
|---|---|---|---|
| `0x000` | VERSION | RO | `0x00010000` |
| `0x004` | STATUS | RO | 아래 bit map |
| `0x008` | IRQ_ENABLE | RW | `[3:0]` interrupt mask, reset 0 |
| `0x00C` | IRQ_STATUS | RO / W1C | bit 0은 level, bit 3:1은 sticky W1C |
| `0x010` | TX_ID | RW | `[10:0]` standard ID, reset 0 |
| `0x014` | TX_CTRL | RW | `[3:0] DLC`, `[4] FD`, `[5] BRS`, reset 0 |
| `0x018` | TX_PUSH | WO | 정확히 `1`을 쓰면 staging frame 등록 |
| `0x01C` | RX_POP | WO | 정확히 `1`을 쓰면 RX head 제거 |
| `0x020` | RX_ID | RO | RX head의 ID |
| `0x024` | RX_CTRL | RO | RX head의 DLC / FD / BRS |
| `0x040~0x07C` | TX_DATA[0:15] | RW | 주소 `0x040+4*n`, 최대 16word staging |
| `0x080~0x0BC` | RX_DATA[0:15] | RO | 주소 `0x080+4*n`, head payload 읽기 |

STATUS: bit0 TX full, bit1 TX empty, bit2 RX full, bit3 RX empty, bit4 TX FSM busy; `[15:8]` TX queued count, `[23:16]` RX count. 나머지는 0. busy는 state가 IDLE이 아닌 상태를 뜻하므로 프레임 등록 직후 1클럭 동안 count>0, busy=0일 수 있다. TX empty도 완료를 뜻하지 않는다. 완료는 IRQ_STATUS로 판단한다.

IRQ_STATUS / IRQ_ENABLE: bit0 RX available, bit1 TX success, bit2 TX error, bit3 RX overflow. `oIrq=|(IRQ_STATUS & IRQ_ENABLE)`. Mask는 이벤트 저장을 막지 않는다. bit0에 1을 써도 수신 프레임이 남으면 유지된다. bit3:1은 1을 쓰면 clear되지만, 같은 에지의 새 이벤트가 우선한다. 여러 이벤트는 sticky bit 하나로 합쳐지므로 완료 횟수 카운터로 사용할 수 없다.

오류 조건은 다음과 같다.

- unaligned / unmapped 접근, RO 쓰기, WO 읽기.
- ID/CTRL/IRQ 레지스터 reserved bit에 1을 쓰는 경우.
- TX_PUSH 또는 RX_POP에 1 이외의 값을 쓰는 경우.
- full TX에 PUSH. 단, 같은 에지에 core가 head를 수락하면 PUSH 가능.
- 잘못된 TX format: FD=0인데 DLC>8 또는 BRS=1.
- TX 길이에 필요한 payload word가 이번 staging에서 모두 쓰이지 않은 PUSH.
- RX empty 상태의 ID / CTRL / DATA 읽기 또는 POP.

## 4. TX 절차와 FSM

1. TX_ID, TX_CTRL에 메타데이터를 쓴다.
2. TX_DATA[0]부터 `ceil(payload_bytes/4)`개 word를 쓴다. 마지막 word의 유효 길이 이후 바이트는 PUSH 때 0으로 채운다.
3. TX_PUSH=1을 쓴다. 성공하면 written mask를 clear하고 FIFO에 완성된 frame을 복사한다. 실패하면 staging은 유지되므로 조건 해결 후 재시도할 수 있다.
4. CPU는 다음 프레임을 staging할 수 있다. 이미 queued / valid인 frame 내용은 바뀌지 않는다.
5. core가 valid/ready로 frame을 수락하면 FIFO head를 pop한다. completion까지 새 요청을 내지 않는다.

| 현재 상태 | 조건 | 다음 상태 / 동작 |
|---|---|---|
| IDLE | FIFO nonempty | SEND |
| IDLE | FIFO empty | IDLE |
| SEND | ready=0 | SEND, valid와 frame 유지 |
| SEND | ready=1, done=0 | WAIT_DONE, head pop |
| SEND | ready=1, done=1 | IDLE, head pop 및 완료 이벤트 |
| WAIT_DONE | done=0 | WAIT_DONE |
| WAIT_DONE | done=1 | IDLE, success/error 이벤트 |
| 모든 상태 | reset asserted | IDLE, FIFO와 제어 상태 초기화 |

`oCanTxValid && iCanTxReady`인 상승 에지에 core adapter가 모든 frame 필드를 저장해야 한다. 수락 후 output frame 값은 다음 FIFO head를 가리킬 수 있다. `iCanTxDone`는 accepted request마다 정확히 1회 pulse여야 하며 `iCanTxError`는 그때만 유효하다. 수락 당일 completion도 지원한다. IDLE이나 ready가 낮은 SEND의 done은 무시한다. late duplicate completion을 구분할 request ID는 없다.

TX 오류 발생 시 이 wrapper는 이벤트를 보고하고 해당 요청을 마친다. CAN protocol-level retry는 core 담당이다. wrapper에는 자동 재등록, completion timeout, core abort 기능이 없다. core가 완료하지 않으면 WAIT_DONE을 유지한다. 회복은 시스템 정책 및 함께 수행하는 reset으로 처리한다.

## 5. RX 절차

core adapter는 CRC 등 검증을 통과한 지원 형식의 complete frame을 `iCanRxValid` 1클럭 pulse와 함께 제공한다. valid가 연속 여러 클럭 높으면 각 클럭을 별도 frame으로 처리하므로 같은 frame에 대해 valid를 유지하면 안 된다. 이 이벤트에는 ready/backpressure가 없다.

- 여유 공간 있음: enqueue.
- full + 같은 에지 유효 POP: 기존 head 제거 후 신규 frame 저장, overflow 없음.
- full + POP 없음: 새 frame 전체 폐기, overflow sticky 설정.
- empty + POP 명령 + 새 frame 도착: POP은 오류, 도착 frame은 저장되어 count=1.

SW는 RX_ID/CTRL/DATA를 읽고 마지막에 RX_POP=1을 쓴다. 모든 읽기는 non-destructive이며 head가 유지된다. 하나의 SW consumer가 이 순서를 독점해야 한다. ISR과 thread가 동시에 POP하는 경우의 동기화는 SW 책임이다. RX의 길이 외 데이터는 adapter 제공값을 보관하므로 SW는 DLC로 지정한 바이트만 사용한다.

## 6. 최소 SW 예제

아래는 FD+BRS, DLC=8의 frame 한 개를 등록하는 순서이다. 실제 CPU 드라이버는 APB error response 처리와 MMIO ordering을 플랫폼에 맞춰 추가해야 한다.

```c
// Byte offsets from the peripheral base address.
write32(BASE + 0x010, 0x123);       // standard CAN ID
write32(BASE + 0x014, 0x38);        // BRS=1, FD=1, DLC=8
write32(BASE + 0x040, 0x44332211);  // payload bytes 11 22 33 44
write32(BASE + 0x044, 0x88776655);  // payload bytes 55 66 77 88
// Poll TX full (STATUS bit0), then commit. Handle a rejected write if needed.
write32(BASE + 0x018, 1);
```

## 7. 검증 범위 / 참고자료

검증 시나리오는 [설계 보고서](report.md)에 정리했다. 파형은 XSim의 신호 전이를 WaveDrom으로 다시 그린 것이다. 기본 시나리오는 `python scripts/run_xsim.py --smoke`로 재현한다.

- [Arm AMBA APB Protocol Specification](https://documentation-service.arm.com/static/63fe2c1356ea36189d4e79f3) — APB transfer / error response 기준.
- [CiA CAN FD basic idea](https://can-cia.org/can-knowledge/can-fd-the-basic-idea) — CAN FD payload / bit rate 설명.
- [TI TCAN1042 datasheet](https://www.ti.com/lit/ds/symlink/tcan1042v-q1.pdf) — controller와 차동 transceiver 경계.

이 프로젝트의 사용자 레지스터 및 frame adapter 인터페이스는 자체 정의다. 위 문서가 이 인터페이스를 표준화하거나 프로젝트 적합성을 보증하는 것은 아니다. ISO 26262, scan/MBIST/ATPG, fault coverage는 검증하지 않았다.
