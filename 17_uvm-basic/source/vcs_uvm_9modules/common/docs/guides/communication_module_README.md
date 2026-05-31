# Communication RTL Core

This folder contains the reusable protocol cores only. Board tops, register-demo
wrappers, APB wrappers, and FIFO-attached wrappers are intentionally kept out so
the modules stay easy to reuse and verify.

## Contents

- `common/clk_div.sv`: generic one-cycle tick divider
- `common/sync_fifo.sv`: parameterized synchronous FIFO
- `i2c/i2c_master.sv`: byte-level I2C master core with open-drain output enables
- `i2c/i2c_slave.sv`: byte-level I2C slave core with open-drain SDA output enable
- `spi/spi_master.sv`: SPI master core with CPOL/CPHA support
- `spi/spi_slave.sv`: SPI slave core with CPOL/CPHA support and `oMisoOe`
- `uart/uart_baud_tick.sv`: selectable 16x baud tick generator
- `uart/uart_tx.sv`: UART transmitter core
- `uart/uart_rx.sv`: UART receiver core

## UART Tick Policy

`uart_tx` and `uart_rx` consume an external `iTick16x` input. This keeps the
cores simple for UVM drivers and monitors.

Use `uart_baud_tick` only when the design needs RTL-generated ticks. Its
`TICK_GEN_MODE` parameter selects the generation method:

- `0`: integer divider
- `1`: phase accumulator

FIFO, APB, or register-map integration should be added later as wrapper modules
around these cores.

`sync_fifo` resets pointers and occupancy count. Its storage array is not reset,
which keeps it friendly to block RAM inference; consumers should use `oEmpty`
and `oCount` rather than treating reset read data as valid.

## Sampling Assumption

I2C and SPI slave cores detect bus edges in the `iClk` domain. Use an `iClk`
fast enough to oversample the external serial clock and keep chip-select/setup
timing away from the first active SPI edge.
