# FPGA UART Image Transfer 실행 가이드북

## 1. 결론

기본 테스트는 Python 파일 하나만 실행하면 된다.

GUI 실행:

```powershell
.\run_gui.bat
```

터미널 대화형 실행:

```powershell
.\run_transfer.bat
```

또는 직접 실행:

```powershell
python .\src\transfer_compare.py --tx-port COM5 --rx-port COM6 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L --raw
```

이 한 프로그램이 아래 작업을 모두 수행한다.

```text
PC
  -> TX COM 포트
  -> master FPGA UART
  -> master FPGA SPI
  -> slave FPGA SPI
  -> slave FPGA UART
  -> RX COM 포트
  -> PC
  -> 원본/수신 이미지 비교
```

## 2. FPGA 두 대 연결 시 실행 구조

PC에 USB-UART가 2개 잡힌다고 보면 된다.

```text
PC COM5  -> master FPGA UART RX  이미지 송신용
PC COM6  <- slave FPGA UART TX   이미지 수신용
```

이때 Python은 하나만 실행한다.

```powershell
python .\src\transfer_compare.py --tx-port COM5 --rx-port COM6 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L --raw
```

`--tx-port`는 master FPGA에 보내는 포트다.

`--rx-port`는 slave FPGA에서 받는 포트다.

COM 포트 번호 자체는 자동 감지할 수 있지만, 어떤 포트가 master 쪽이고 어떤 포트가 slave 쪽인지는 보드 배선 기준이라 사용자가 선택해야 한다.

GUI에서는 아래처럼 선택한다.

```text
Master TX Port = PC -> master FPGA UART RX
Slave RX Port  = slave FPGA UART TX -> PC
```

## 2-1. GUI 실행

실행:

```powershell
.\run_gui.bat
```

GUI 기능:

```text
COM 포트 자동 검색
Master TX Port 선택
Slave RX Port 선택
baud rate 입력
L/RGB 모드 선택
raw mode 선택
이미지 파일 선택
Run 버튼으로 송신/수신/비교 실행
통신 상태 표시
터미널 출력 표시
PASS/FAIL 표시
slave에서 받은 이미지 PNG 저장
slave에서 받은 payload TXT 저장
원본/수신 diff PNG 저장
JSON 로그 저장
```

GUI에서 `Refresh Ports`를 누르면 현재 연결된 COM 포트를 다시 검색한다.

GUI의 터미널 창에는 `transfer_compare.py` 실행 로그가 그대로 표시된다.

## 3. COM 포트 확인

보드와 USB-UART를 연결한 뒤 실행:

```powershell
python .\src\send_image.py --list-ports
```

예상 출력 예:

```text
COM5: USB Serial Port (...)
COM6: USB Serial Port (...)
```

장치 관리자에서도 COM 번호를 같이 확인하는 것이 좋다.

## 4. 가장 추천하는 실행 순서

1. FPGA 두 대 전원 연결
2. PC에 USB-UART 두 개 연결
3. master FPGA UART RX에 PC TX 라인 연결
4. slave FPGA UART TX에 PC RX 라인 연결
5. 두 FPGA 사이 SPI 연결
6. COM 포트 확인
7. raw mode로 먼저 테스트

실행:

```powershell
cd C:\Users\user\Desktop\MAIN_ing\10_Projects\RISC_AXI\python_comport
.\run_transfer.bat
```

대화형 입력 예:

```text
TX COM port connected to master FPGA UART RX: COM5
RX COM port connected to slave FPGA UART TX: COM6
Baud rate [115200]: 115200
Pixel mode (L or RGB) [RGB]: RGB
Resize width [64]: 64
Resize height [64]: 64
Use raw pixel-only mode [Y/n]: Y
Input image path [...\image\rainbow64x64_rgb888.png]:
Received output image path [...\outputs\received_*.png]:
```

## 5. raw mode와 framed mode

### raw mode

FPGA 쪽에서 가장 구현하기 쉽다.

```text
payload only
pixel0, pixel1, pixel2, ...
```

grayscale `L` 모드:

```text
1 pixel = 1 byte
```

RGB 모드:

```text
1 pixel = 3 bytes = R, G, B
```

FPGA RTL이 아직 헤더를 처리하지 않는다면 raw mode를 사용한다.

```powershell
python .\src\transfer_compare.py --tx-port COM5 --rx-port COM6 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L --raw
```

### framed mode

Python 기본 프레임 프로토콜이다.

```text
18-byte header + payload
```

헤더 구조:

```text
magic       4 bytes  "IMGF"
version     1 byte   1
channels    1 byte   1 or 3
width       2 bytes
height      2 bytes
payload_len 4 bytes
crc32       4 bytes
payload     N bytes
```

FPGA에서 헤더와 CRC까지 처리할 준비가 되면 `--raw`를 빼고 실행한다.

```powershell
python .\src\transfer_compare.py --tx-port COM5 --rx-port COM6 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L
```

## 6. 파일별 기능 정리

### run_transfer.bat

대화형 실행용 배치 파일이다.

```powershell
.\run_transfer.bat
```

COM 포트, baud rate, 이미지 경로를 직접 입력받고 내부에서 `transfer_compare.py`를 실행한다.

### src/transfer_compare.py

메인 실행 파일이다.

기능:

```text
1. 원본 이미지 로드
2. 픽셀 byte payload 생성
3. RX COM 포트 먼저 열기
4. TX COM 포트로 master FPGA에 이미지 전송
5. RX COM 포트에서 slave FPGA 출력 수신
6. 수신 이미지를 PNG로 저장
7. 원본과 수신 payload 비교
8. diff 이미지 저장
9. 결과 로그 JSON 저장
```

실전 테스트는 이 파일을 쓰면 된다.

### src/send_image.py

송신 전용 파일이다.

기능:

```text
PC -> master FPGA UART
```

분리 디버깅할 때 사용한다.

```powershell
python .\src\send_image.py --port COM5 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L --raw
```

### src/receive_image.py

수신 전용 파일이다.

기능:

```text
slave FPGA UART -> PC
```

분리 디버깅할 때 사용한다.

```powershell
python .\src\receive_image.py --port COM6 --baud 115200 --out .\outputs\received.png --expected .\image\gray64x64_8bit_png.png --raw --width 64 --height 64 --channels 1
```

### src/protocol.py

공통 로직이다.

기능:

```text
이미지 로드
이미지 저장
raw payload 생성
framed packet 생성
header parsing
CRC32 검사
byte 단위 비교
pixel 단위 mismatch 계산
diff 이미지 생성
JSON 로그 저장
```

### src/make_test_image.py

테스트 이미지 생성용 파일이다.

```powershell
python .\src\make_test_image.py --out .\image\gray64x64_8bit_png.png --width 64 --height 64 --mode L
python .\src\make_test_image.py --out .\outputs\test_rgb.png --width 64 --height 64 --mode RGB
```

## 7. 비교 결과에서 보는 값

실행 후 터미널에 이런 값이 나온다.

```text
Compare: PASS or FAIL
Byte mismatches
Pixel mismatches
Max abs error
First mismatches
```

의미:

```text
Byte mismatches  = 틀린 바이트 개수
Pixel mismatches = 틀린 픽셀 개수
Max abs error    = 가장 크게 틀린 픽셀값 차이
First mismatches = 처음 틀린 위치 x, y, channel, expected, actual
```

예:

```text
byte=103 pixel=103 (x=39, y=1, ch=0) expected=152 actual=151
```

이 뜻은 `(x=39, y=1)` 위치의 grayscale 픽셀값이 원래 `152`여야 하는데 `151`로 들어왔다는 뜻이다.

## 8. 생성되는 결과물

모든 결과물은 이 폴더 내부에 저장된다.

```text
runs/sender_outputs/
  received_*.png
  received_*_diff.png
  received_*_rx.txt

logs/sender/
  transfer_*.json
  send_*.json
  receive_*.json
```

`received_*.png`는 slave FPGA에서 돌아온 이미지다.

`*_diff.png`는 원본과 수신 이미지 차이다.

`*_rx.txt`는 slave FPGA에서 받아온 payload를 텍스트로 풀어쓴 파일이다.

`logs/sender/*.json`은 테스트 조건과 비교 결과 기록이다.

## 9. 처음 테스트할 때 추천 설정

처음에는 작은 grayscale 이미지가 좋다.

```text
mode: L
size: 64x64
payload: 4096 bytes
raw mode: ON
baud: 115200
```

실행:

```powershell
python .\src\transfer_compare.py --tx-port COM5 --rx-port COM6 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L --raw
```

이게 PASS가 나오면 그 다음에 RGB 또는 더 큰 이미지로 올린다.

## 10. 문제 생길 때 체크 순서

### COM 포트가 안 보이는 경우

```powershell
python .\src\send_image.py --list-ports
```

장치 관리자에서 USB-UART 드라이버와 COM 번호를 확인한다.

### 수신 timeout

가능성이 높은 원인:

```text
slave FPGA UART TX가 PC RX로 안 들어옴
baud rate 불일치
slave FPGA가 아직 데이터를 출력하지 않음
SPI 연결 문제
reset/enable 순서 문제
```

### mismatch가 많이 나는 경우

가능성이 높은 원인:

```text
UART baud 오차
byte 순서 밀림
SPI bit order 문제
FIFO overflow/underflow
이미지 크기 불일치
RGB/L 모드 불일치
```

### 첫 byte부터 틀리는 경우

```text
TX/RX 시작 타이밍
reset 타이밍
raw/framed 모드 불일치
FPGA가 header를 payload로 처리함
```

FPGA가 raw payload만 기대하면 반드시 `--raw`를 붙인다.

## 11. 분리 실행은 언제 쓰나

일반 테스트는 `transfer_compare.py` 하나로 충분하다.

분리 실행은 아래 상황에서만 쓴다.

```text
master FPGA UART 입력만 단독 확인
slave FPGA UART 출력만 단독 확인
TX/RX 타이밍을 사람이 직접 제어해야 하는 경우
PC 두 대로 나눠서 테스트하는 경우
```

분리 실행 시에는 터미널 2개를 사용한다.

먼저 수신:

```powershell
python .\src\receive_image.py --port COM6 --baud 115200 --out .\outputs\received.png --expected .\image\gray64x64_8bit_png.png --raw --width 64 --height 64 --channels 1
```

그 다음 송신:

```powershell
python .\src\send_image.py --port COM5 --baud 115200 --image .\image\gray64x64_8bit_png.png --mode L --raw
```

## 12. 현재 구현 상태

구현 완료:

```text
COM 포트 목록 확인
이미지 송신
이미지 수신
송수신 통합 실행
raw mode
framed mode
CRC32 framed packet
원본/수신 byte 비교
pixel mismatch 위치 출력
diff 이미지 저장
JSON 로그 저장
테스트 이미지 생성
대화형 실행 bat
```

아직 하드웨어 연결 후 확인 필요:

```text
실제 FPGA 2대 UART/SPI 경유 테스트
보드 baud rate 안정성 확인
FPGA raw/framed 프로토콜 최종 확정
필요 시 ACK/READY handshake 추가
```
