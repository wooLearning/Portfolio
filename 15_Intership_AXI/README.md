# Undergraduate Research Internship: AXI to APB Bridge Design

This folder contains an HDD report and RTL sources for an AXI-to-APB bridge architecture.

## 1. Portfolio Snapshot
- Category: Undergraduate research internship (winter track)
- Program label in report title: **2025 winter**
- Report revision period: **2026.01.08 to 2026.01.14**
- Date reference: revision history inside HDD report

## 2. Design Goal
- bridge AXI transactions to APB transactions,
- support burst requests while keeping APB-side control simple,
- manage read and write paths with FSM-based logic.

## 3. RTL Highlights
Core modules:
- `Prj_Axi_Top.v`
- `Axi2Apb.v`
- `ApbSlave.v`
- integrated APB-side support modules under `Cp_*`

Documented behavior:
- burst request handling via sequential APB single transfers,
- APB wait-state support with `PREADY`,
- error response for unsupported address range,
- 4-slave selection via `PSEL` decode and data/ready mux.

Documented limits:
- no out-of-order support,
- no multiple outstanding support,
- no AXI ID-based reordering support.

## 4. Main Evidence
- HDD report in PDF and DOC format
- RTL source and testbench directories

## 5. Tech Stack
- HDL: `Verilog-HDL`
- Bus protocol: `AXI`, `APB`
- Verification: RTL simulation and timing scenario checks
