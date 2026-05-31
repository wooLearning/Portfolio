# 08 I2C Master UVM Summary

## Scope

- DUT: I2C master
- Source: `rtl/`
- Testbench: `tb/`
- Vivado-compatible flow: `sim/vivado/`

## Scenario

- Smoke transaction tests
- Directed read/write checks
- ACK/NACK and error-path checks
- Reset and jittered tick tests
- Byte sweep and full-random transaction tests

## Assertion

- `done` is a one-cycle pulse.
- `done` must not assert during reset.
- `done` implies the transfer is no longer busy.
- Bus lines must return to released idle state after completion.

## Coverage

- Read/write direction coverage
- Address coverage
- Data coverage
- ACK/NACK result coverage
- Tick, jitter, and reset coverage

## Result

- Status: PASS
- Tests: 529 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- No dedicated I2C PNG existed in the source set.
- Use `../../common/docs/uvm_selected_diagrams/` as the shared UVM class/sequence style reference until the I2C-specific figure is redrawn.
