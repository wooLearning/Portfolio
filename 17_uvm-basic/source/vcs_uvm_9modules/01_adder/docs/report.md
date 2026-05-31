# 01 Adder UVM Summary

## Scope

- DUT: 8-bit combinational adder
- Source: `rtl/`
- Testbench: `tb/`
- Baseline flow: `sim/makefile/Makefile`

## Scenario

- Smoke and directed corner tests for zero, carry, and maximum operand cases
- Full byte sweep over representative operand combinations
- Random stimulus for general input-space confidence

## Assertion

- Explicit SVA is not implemented for this block.
- The main checker is the UVM scoreboard: `expected = iA + iB`, then compare against DUT output.
- For this module, a future assertion target would be output-known and combinational-response stability after valid stimulus sampling.

## Coverage

- Operand coverage for `iA` and `iB`
- Carry/result range coverage
- Cross coverage between operand regions

## Result

- Status: PASS
- Tests: 778 pass / 0 fail
- Functional coverage: 100%

## Diagrams

- `diagrams/diagram_adder_class_map.svg`
- `diagrams/diagram_adder_uvm_timing.svg`
