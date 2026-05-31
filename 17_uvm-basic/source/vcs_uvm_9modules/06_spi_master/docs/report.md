# 06 SPI Master UVM Summary

## Scope

- DUT: SPI master
- Source: `rtl/`
- Testbench: `tb/`
- Vivado-compatible flow: `sim/vivado/`

## Scenario

- Smoke transfer tests
- CPOL/CPHA mode checks
- Corner data-pattern tests
- Byte sweep tests
- Full-random MOSI/MISO transaction tests

## Assertion

- `done` is a one-cycle pulse.
- `done` must not assert during reset.
- `done` implies the transfer is no longer busy.
- Chip-select returns high after idle/done.
- SCLK returns to its configured idle level when chip-select is inactive.

## Coverage

- TX data coverage
- MISO data coverage
- CPOL and CPHA coverage
- CPOL-by-CPHA cross coverage
- Result, tick, jitter, and reset coverage

## Result

- Status: PASS
- Tests: 275 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- No dedicated SPI PNG existed in the source set.
- Use `../../common/docs/uvm_selected_diagrams/` as the shared UVM class/sequence style reference until the SPI-specific figure is redrawn.
