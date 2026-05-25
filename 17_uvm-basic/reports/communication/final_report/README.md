# Final Report Artifacts

This folder contains the final Korean UVM verification report for `uvm_ttt`.

## Main Files

| File | Purpose |
| --- | --- |
| `uvm_verification_status_report.md` | Markdown source report with embedded image references |
| `uvm_verification_status_report.html` | Browser-readable final report |
| `assets/` | Copied/generated diagrams and result graphs used by the report |

## Figure Set

| Figure | Purpose |
| --- | --- |
| `style3_overall_uvm_structure.png` | Overall UVM verification architecture |
| `style3_basic_uvm_flow.png` | ADDER/FIFO/RAM UVM flow |
| `style_uvm_uart_rx_tx_flow.png` | UART RX/TX flow |
| `style3_spi_uvm_flow.png` | SPI MASTER/SLAVE flow |
| `style3_i2c_uvm_flow.png` | I2C MASTER/SLAVE flow |
| `style3_scoreboard_coverage_flow.png` | Scoreboard and coverage closure flow |
| `uvm_dashboard.png`, `uvm_status_matrix.png`, `basic_pass_matrix.png` | PASS/dashboard figures |

Coverage 100% bar/detail images are kept in `assets/` as evidence copies, but the report now explains coverage selection and closure in text/table form instead of embedding those low-information images.

The new `style3_*.png` diagrams were generated using the diagram-draw skill's style3 UVM documentation direction.
