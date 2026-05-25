# UVM Basic Lab Handoff

## 바로 열 파일
- HTML 보고서: `uvm_basic_lab_report_v2.html`
- PDF 보고서: `uvm_basic_lab_report_v2.pdf`

## HTML 이미지 경로
HTML은 상대경로를 사용한다.
다른 컴퓨터로 옮길 때는 `handoff` 폴더 전체를 그대로 복사하면 이미지가 깨지지 않는다.

필수 상대경로:
- `basic/docs/diagrams/*.svg`
- `capture/adder/*.png`
- `capture/ram/*.png`
- `capture/fifo/*.png`

## 소스코드
소스코드는 `source_code/basic` 아래에 정리했다.

구성:
- `source_code/basic/adder`
- `source_code/basic/ram`
- `source_code/basic/fifo`
- `source_code/basic/scripts`
- `source_code/basic/Makefile`
- `source_code/basic/README.md`

## 핵심 산출물
- Adder/RAM/FIFO UVM 실습 보고서 HTML
- 16:9 PDF 보고서
- 보고서용 SVG 다이어그램
- Verdi/UVM 결과 캡처 이미지
- RTL 및 UVM testbench source

## 참고
`MANIFEST.txt`에 handoff 폴더에 포함된 전체 파일 목록을 저장했다.
