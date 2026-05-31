# 04 UART RX UVM Summary

## Scope

- DUT: UART receiver with baud tick generator
- Source: `rtl/`
- Testbench: `tb/`
- Vivado-compatible flow: `sim/vivado/`

## Scenario

- Directed receive-byte tests
- Frame-error and false-start checks
- Reset-in-frame and timeout checks
- Jittered tick tests
- Byte sweep and full-random serial input tests

## Assertion

- `valid` and `frame_error` must not assert together.
- Reset blocks output pulses.
- `valid` is a one-cycle pulse.
- `frame_error` is a one-cycle pulse.
- False-start windows must not produce a receive result.

## Coverage

- Received data-pattern coverage
- Good-frame and frame-error result coverage
- Reset phase coverage
- Tick mode and jitter mode coverage

## Result

- Status: PASS
- Tests: 292 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- `diagrams/diagram_uart_rx_class.png`
- `diagrams/diagram_uart_rx_sequence.png`
- `diagrams/diagram_uart_rx_tx_flow.png`
