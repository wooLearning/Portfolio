# 09 I2C Slave UVM Summary

## Scope

- DUT: I2C slave
- Source: `rtl/`
- Testbench: `tb/`
- Vivado-compatible flow: `sim/vivado/`

## Scenario

- Smoke transaction tests
- Directed address-hit and address-miss checks
- Read/write data checks
- Reset and jittered tick tests
- Byte sweep and full-random transaction tests

## Assertion

- `rx_valid` is a one-cycle pulse.
- `txn_done` is a one-cycle pulse.
- Output pulses must not assert during reset.
- `rx_valid` is only expected for accepted write transactions.

## Coverage

- Read/write direction coverage
- Address-hit and address-miss coverage
- Data coverage
- Result coverage
- Tick, jitter, and reset coverage

## Result

- Status: PASS
- Tests: 528 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- No dedicated I2C PNG existed in the source set.
- Use `../../common/docs/uvm_selected_diagrams/` as the shared UVM class/sequence style reference until the I2C-specific figure is redrawn.
