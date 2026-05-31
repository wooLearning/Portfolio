# UVM URG HTML Reports

Synopsys VCS/URG로 생성한 UVM 검증 결과 HTML 묶음입니다.

## 구성

- `01_adder` ~ `09_i2c_slave`: 각 모듈별 URG report 전체 복사본
- `index.html`: 포트폴리오/GitHub Pages용 링크 모음
- 각 모듈에서 주로 볼 페이지
  - `dashboard.html`: 전체 report 진입 화면
  - `groups.html`: covergroup 단위 coverage summary
  - `grp0.html`: coverpoint/bin hit 상세
  - `asserts.html`: assertion attempt, success, failure 확인

## 추천 확인 순서

1. 통신 모듈 대표 결과: `04_uart_rx`, `06_spi_master`, `08_i2c_master`
2. 기본 검증 구조 확인: `01_adder`, `02_ram`, `03_fifo`
3. Assertion 확인: 각 모듈의 `asserts.html`
4. Coverage bin 확인: 각 모듈의 `grp0.html`

## GitHub Pages 참고

URG 원본은 CSS/JS 파일명이 `.urg.css`, `.jquery.js`처럼 점으로 시작합니다. GitHub Pages에서 누락될 수 있어서, 이 폴더에서는 같은 파일을 일반 이름으로 복사하고 HTML 링크도 `css/urg.css`, `js/jquery.js` 형태로 수정했습니다.

