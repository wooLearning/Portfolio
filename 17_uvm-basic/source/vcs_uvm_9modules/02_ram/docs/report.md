# 02 RAM UVM Summary

## Scope

- DUT: single-port RAM
- Source: `rtl/`
- Testbench: `tb/`
- Baseline flow: `sim/makefile/Makefile`

## Scenario

- Reset and idle behavior checks
- Directed write/read checks for first, middle, and last addresses
- Byte-pattern write/read sweeps
- Random address/data command sequences

## Assertion

- Interface SVA checks active transactions for known command/address/data values.
- Reset assertion checks output behavior while reset is active.
- Address-stability assertion catches address changes during an accepted transaction.
- DUT-side SVA checks control knownness, idle read-data stability, and write-then-readback behavior.

## Coverage

- Command coverage for read/write/idle regions
- Address and data coverage
- Read-data coverage
- Command-by-address cross coverage

## Result

- Status: PASS
- Tests: 792 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- `diagrams/diagram_ram_class_map.svg`
- `diagrams/diagram_ram_uvm_timing.svg`
