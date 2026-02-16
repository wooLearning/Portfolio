# 제11회 숭실 캡스톤디자인 경진대회 장려상 (ET31)
# 11th Soongsil Capstone Design Competition (Encouragement Prize, ET31)

## 1. 수상 정보 | Award Information
- 수상명 / Award: `제11회 숭실 캡스톤디자인 경진대회 장려상`
- 수여기관 / Institution: `숭실대학교 공학교육혁신센터`
- 수상연도 / Year: `2021`
- 프로젝트 요약 / Project topic: 코로나19 대응 자동 출입 제어 장치 (열감지 + 얼굴/마스크 인식 + CCTV)

## 2. 한국어 요약 | Korean Summary
라즈베리파이 기반 비접촉 출입 제어 시스템을 구현했습니다.  
주요 기능은 열감지(AMG88xx), 얼굴 및 마스크 인식, 자동문 제어, PC 모니터링(CCTV/열화상)이며, 교내 캡스톤 경진대회에서 장려상을 수상했습니다.

## 3. English Summary
This project built a Raspberry Pi based contactless access-control system for COVID-19 response.  
Core features include thermal sensing (AMG88xx), face/mask recognition, automatic door control, and PC-side CCTV/thermal monitoring. The project won an Encouragement Prize in the 11th Soongsil Capstone Design Competition.

## 4. 시스템 구성 | System Architecture
- Raspberry Pi #1: mask camera + thermal sensor + servo door control
- Raspberry Pi #2: CCTV camera
- PC: receives thermal/CCTV streams over socket
- Motor PWM: `GPIO 18`, `50Hz`

## 5. 구현 파일 | Implementation Files
- `mask_thermal.py`: 통합 제어 (mask/thermal/motor)
- `thermal_cam.py`: 열화상 중심 제어 경로
- `socketpc.py`: PC 수신 및 시각화
- `motor.py`: 서보 모터 테스트
- `server.py`, `client.py`: 통신 테스트

## 6. 동작 흐름 | Runtime Flow
1. 얼굴/마스크 상태 판별
2. 8x8 열화상 센서 데이터 획득
3. TCP로 PC 전송
4. 정책에 따라 출입문 개폐

## 7. 기술 스택 | Tech Stack
- Platform: `Raspberry Pi`
- Language: `Python`
- Vision: `OpenCV`, `TensorFlow/Keras (MobileNetV2-based)`
- Sensor: `AMG88xx`
- IO/Control: `RPi.GPIO`, `I2C`, `TCP socket`

## 8. 산출물 | Artifacts
- Source code: `Source/*.py`
- Images: `Source/*.jpg`, `Source/*.png`
- Demo video: `demo video` 폴더의 MP4
