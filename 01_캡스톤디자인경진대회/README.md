# 제11회 숭실 캡스톤디자인 경진대회 (ET31)
> 11th Soongsil Capstone Design Competition

## 📅 Project Info
- **Period**: 2021
- **Category**: Capstone Design (Encouragement Prize)
- **Stack**: `Raspberry Pi` `Python` `OpenCV` `AMG88xx`

## 📝 Summary
코로나19 대응을 위한 **라즈베리파이 기반 비접촉 출입 제어 시스템**입니다.  
열감지 센서(AMG88xx)와 카메라(Face/Mask Detection)를 활용하여 마스크 착용 및 정상 체온 여부를 판별하고, 서보 모터로 출입문을 제어합니다.  
CCTV 및 열화상 데이터를 소켓 통신으로 PC에 전송하여 실시간 모니터링이 가능합니다.

## 💡 Key Features
- **Dual Sensing**: 마스크 착용 감지(MobileNetV2) + 체온 측정(AMG8833).
- **Auto Control**: 조건 충족 시 서보 모터 구동 (출입 허용).
- **Remote Monitoring**: TCP Socket을 통한 PC 관제 (CCTV/Heatmap).

## 📂 Artifacts
- `Source/`: Python source code (`mask_thermal.py`, `socketpc.py`, etc.)
- `시연영상/`: Demo Video
