# 03 FIFO UVM Summary

## Scope

- DUT: synchronous FIFO
- Source: `rtl/`
- Testbench: `tb/`
- Baseline flow: `sim/makefile/Makefile`

## Scenario

- Reset, empty, write-only, read-only, and simultaneous write/read checks
- Fill-to-full and drain-to-empty sequences
- Byte-pattern data sweep
- Random queue operation sequences

## Assertion

- Count-zero implies empty.
- Count-depth implies full.
- Command fields must not become unknown during active checking.

## Coverage

- Command coverage for write/read/idle/mixed operation
- Full and empty status coverage
- FIFO count-depth coverage
- Command-by-count cross coverage

## Result

- Status: PASS
- Tests: 754 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- `diagrams/diagram_fifo_class_map.svg`
- `diagrams/diagram_fifo_uvm_timing.svg`
