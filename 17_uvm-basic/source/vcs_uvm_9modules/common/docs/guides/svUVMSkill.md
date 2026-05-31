# SystemVerilog UVM Skill

## Format

- Default indentation: 2 spaces
- Do not write `end else begin`
- Write `else` on the next line after `end`

## Naming

- Class/type name: PascalCase
- Function/task name: snake_case
- Interface/config handle: clear names like `mVif`, `mCfg`
- Sequence item fields and local variables: follow project style

## UVM Rules

- Keep standard hierarchy: `sequence_item`, `sequence`, `sequencer`, `driver`, `monitor`, `agent`, `env`, `test`
- Use `virtual interface` for DUT interface access
- Share interface/config through `uvm_config_db`
- Get config/interface in `build_phase`
- Connect TLM ports in `connect_phase`
- Drive and sample in `run_phase`
- Keep scoreboard, coverage, and monitor responsibilities separated
- Use `uvm_component_utils` or `uvm_object_utils` correctly
- Use `uvm_fatal` when required config or interface is missing

## Reference Standard

- Base all UVM implementation decisions on `uvm-core-2020.3.1` and `uvm_doc`
- When implementation details are ambiguous, always refer to the standard UVM structure in those folders first
- If `uvm-core-2020.3.1` and `uvm_doc` do not provide enough information, search for additional references before implementing

## Phase Rule

- `build_phase`: create components, get config
- `connect_phase`: connect ports/exports
- `run_phase`: stimulus, driving, monitoring
- `report_phase`: summary if needed

## Sequence Rule

- `sequence_item` holds transaction fields
- `sequence` creates and randomizes items
- `driver` gets items from sequencer and drives DUT
- `monitor` samples DUT and sends transactions through analysis port

## Notes

- Prefer simple and explicit UVM structure
- Keep test intent clear in sequences and test classes
