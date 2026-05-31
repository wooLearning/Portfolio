# 05 UART TX UVM Summary

## Scope

- DUT: UART transmitter with baud tick generator
- Source: `rtl/`
- Testbench: `tb/`
- Vivado-compatible flow: `sim/vivado/`

## Scenario

- Directed transmit-byte tests
- Reset during transmit checks
- Timeout checks
- Jittered tick tests
- Byte sweep and full-random transmit tests

## Assertion

- `done` is a one-cycle pulse.
- `done` must not assert during reset.
- `ready` and busy state must stay complementary.
- TX line must remain idle high outside active frames.

## Coverage

- Transmit data-pattern coverage
- Busy/ready handshake coverage
- Completion-result coverage
- Reset phase coverage
- Tick mode and jitter mode coverage

## Result

- Status: PASS
- Tests: 296 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- `diagrams/diagram_uart_tx_class.png`
- `diagrams/diagram_uart_tx_sequence.png`
- `diagrams/diagram_uart_rx_tx_flow.png`
