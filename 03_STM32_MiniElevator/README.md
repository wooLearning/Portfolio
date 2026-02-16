# STM32 Mini Elevator Controller

An embedded control project that simulates a 3-floor elevator on STM32 Nucleo, including hall/car button handling, motor stepping, and floor display.

## 1. Project Overview
- Platform: `STM32 Nucleo`
- Goal: implement practical elevator logic with request prioritization
- Supporting materials: project PDF/PPT in this folder

Implemented features:
- hall calls (`UP` / `DOWN`),
- car floor requests,
- step motor drive,
- 7-segment floor display,
- LED status indication.

## 2. Code Versions
- `elevator_origin.c`: initial version
- `elevator_good.c`: intermediate improvement version
- `elevator_final.c`: refined scheduling and edge-case handling

## 3. Control Logic (Final Version)
State variables:
- `currentFloor`, `targetFloor`, `direction`, `totalSteps`
- request queues: `upButton[]`, `downButton[]`, `fButton[]`

Core functions:
- `input_button()`
- `button_check()`
- `led_check()`
- `go_floor()`
- `update_currentFloor()`
- `display_floor()`

## 4. Scheduling Policy
The final logic follows a SCAN-like elevator policy.
- while moving up: prioritize up requests + in-car requests,
- while moving down: prioritize down requests + in-car requests,
- while idle: select nearest pending request.

Example behavior:
- if the car is moving from floor 1 to floor 3,
  - a floor-2 `UP` call can be served on the way up,
  - a floor-2 `DOWN` call is deferred until the down trip.

## 5. Hardware Control Notes
- motor outputs: `IN1`, `IN2`, `IN3`, `IN4`
- key constants:
  - `MAXFLOOR = 3`
  - `STEP = 135`
  - `SPEEDINIT = 20`
  - `DECREASE = 2`

## 6. Tech Stack
- MCU: `STM32`
- Language: `C`
- Devices: step motor, buttons, LEDs, 7-segment

## 7. Artifacts
- source: `elevator_origin.c`, `elevator_good.c`, `elevator_final.c`
- docs: project PDF and PPT
