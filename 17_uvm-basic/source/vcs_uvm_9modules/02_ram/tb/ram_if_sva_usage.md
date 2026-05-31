# Interface SVA usage

If you want to start SVA at the `interface` stage, use this split:

1. Keep the base interface in `ram_if.sv`
2. Put simple signal-rule assertions in `ram_if_sva.svh`
3. Include that block inside the interface
4. Keep data-behavior assertions in a separate module like `ram_sva.sv`

For this RAM example:

- `ram_if_sva.svh`
  Good for `X/Z check`, `reset rule`, `simple stability`
- `ram_sva.sv`
  Good for `write -> readback` behavior checks

If you want to try the integrated style directly, see `ram_if.sv`.
