# Verification Summary

## C Smoke Firmware

Purpose: prove C code can be compiled, linked, converted to `.mem`, loaded into ROM, and executed by the custom RV32I core.

Observed result:

```text
SOC_C_SMOKE_PASS cycle=106 retired=51 pc=0x0000015c gpio=0x00c6
sram0=0xc0de0001 sram1=0x11112222 sram2=0x00000000 sram3=0xc0def00d
```

Meaning:

- C startup worked.
- `.data` copy worked.
- `.bss` clear worked.
- GPIO MMIO write worked.
- SRAM write worked.

## UART Loader Simulation

Purpose: prove PC-style UART packet can be received by ROM loader, written into SRAM, and executed from SRAM.

Observed result:

```text
SOC_UART_LOADER_PASS cycle=1610041 retired=405384
pc=0x20001158 gpio=0x00a5
sram0=0xa5500001 sram1=0x20001000 sram2=0xabcd1234 sram3=0x00000000
```

Meaning:

- UART receive path worked.
- Loader packet parser worked.
- SRAM write path worked.
- IBus SRAM executable fetch path worked.
- RAM app jumped and executed.

## UART Loader Bitstream

Observed result:

```text
Bitgen Completed Successfully
UART_LOADER_IMPL_TIMING WNS_NS=2.100 REQUIREMENT_NS=20.000 ACHIEVED_PERIOD_NS=17.900 FMAX_EST_MHZ=55.866
```

Meaning:

- Loader design routes successfully.
- Timing meets the 50 MHz SoC clock target.

## Preserved / Not Modified During Loader Work

The UART loader work intentionally avoided modifying core pipeline forwarding logic:

- `ForwardingUnit.sv`
- `HazardUnit.sv`
- `ExecuteStage.sv`
- `DecodeStage.sv`
- `Rv32Core.sv`
