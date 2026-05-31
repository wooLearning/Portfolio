# 07 SPI Slave UVM Summary

## Scope

- DUT: SPI slave
- Source: `rtl/`
- Testbench: `tb/`
- Vivado-compatible flow: `sim/vivado/`

## Scenario

- Smoke transfer tests
- CPOL/CPHA mode checks
- Corner data-pattern tests
- Byte sweep tests
- Full-random MOSI/TX response tests

## Assertion

- MISO output-enable must be released when chip-select is inactive.
- `rx_valid` is a one-cycle pulse.
- `rx_valid` must not assert during reset.

## Coverage

- MOSI data coverage
- TX response data coverage
- CPOL and CPHA coverage
- CPOL-by-CPHA cross coverage
- Result, tick, jitter, and reset coverage

## Result

- Status: PASS
- Tests: 274 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- No dedicated SPI PNG existed in the source set.
- Use `../../common/docs/uvm_selected_diagrams/` as the shared UVM class/sequence style reference until the SPI-specific figure is redrawn.
