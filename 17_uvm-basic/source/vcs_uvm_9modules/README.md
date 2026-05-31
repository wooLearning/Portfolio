# UVM Verification Portfolio

This workspace is organized as nine independently reviewable UVM verification examples. The folder order is intentional: basic RTL/UVM blocks first, then communication protocol blocks split by role.

## Module Index

| No. | Module | Main Flow | Notes |
| --- | --- | --- | --- |
| 01 | `01_adder` | Makefile/VCS style baseline | Scoreboard-focused combinational checker |
| 02 | `02_ram` | Makefile/VCS style baseline | Interface and DUT SVA included |
| 03 | `03_fifo` | Makefile/VCS style baseline | Queue/reference-model style checking |
| 04 | `04_uart_rx` | Vivado-compatible flow | RX scenarios, assertions, coverage, evidence |
| 05 | `05_uart_tx` | Vivado-compatible flow | TX scenarios, assertions, coverage, evidence |
| 06 | `06_spi_master` | Vivado-compatible flow | SPI master mode checks |
| 07 | `07_spi_slave` | Vivado-compatible flow | SPI slave response checks |
| 08 | `08_i2c_master` | Vivado-compatible flow | I2C master read/write checks |
| 09 | `09_i2c_slave` | Vivado-compatible flow | I2C slave address/data checks |

## Standard Folder Shape

Each module uses the same top-level shape:

```text
rtl/
tb/
sim/
  makefile/
  vivado/
docs/
  diagrams/
  evidence/
  report.md
```

## Shared Material

- `common/scripts/`: copied helper scripts from the original projects
- `common/docs/`: shared UVM diagrams and common Basic diagrams
- `common/docs/guides/`: local UVM/RTL style notes, BFM verification plan, and VCS/Verdi guides
- `common/reference/`: local UVM and SystemVerilog PDF references
- `common/rtl/`: reusable helper RTL such as `clk_div`
- `common/style_reference/`: diagram style references
- `docs/portfolio/`: integrated portfolio-level reports
- `tmp/`: old intermediate layouts, duplicate reports, and source material kept for traceability

## Notes

- Basic modules follow the Makefile/VCS-style structure as the baseline.
- Communication modules keep Vivado-compatible simulation folders because the imported `uvm_ttt` flow was built around Vivado/XSim.
- Original external source folders were not deleted. After this workspace is reviewed, they can be removed manually if this organized copy is accepted.
