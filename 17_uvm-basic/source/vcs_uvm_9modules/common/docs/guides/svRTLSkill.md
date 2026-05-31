# SystemVerilog RTL Skill

## Format

- Default indentation: 2 spaces
- Do not write `end else begin`
- Write `else` on the next line after `end`

## Naming

- Input port: `i` + PascalCase
- Output port: `o` + PascalCase
- Register/sequential signal: `r` + PascalCase
- Wire/combinational signal: `w` + PascalCase
- Function/task name: `snake_case`
- Parameter/localparam: uppercase with `_`

## FSM

- Use 3-block FSM style
- `rCurState`: current state
- `rNxtState`: next state
- Block 1: `always_ff` for state register only
- Block 2: `always_comb` for next-state logic only
- Block 3: `always_comb` for output logic only
- Keep datapath registers in separate logic
- Use `typedef enum logic [...]` for state type
- Start next-state logic with `rNxtState = rCurState;`
- Include `default` in `case`

## Notes

- Use uppercase for state names
- Name each state so its role is clear
