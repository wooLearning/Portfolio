# File Index

## docs

- `docs/PROJECT_SUMMARY_KO.md`: Korean project summary for context transfer.
- `docs/NEW_CHAT_PROMPT_KO.md`: prompt to paste into a new chat when continuing the project.
- `docs/VERIFICATION_SUMMARY.md`: concise verification evidence and pass strings.
- `docs/UART_LOADER_WORKFLOW.md`: UART loader ROM and RAM app workflow.
- `docs/SOC_TOP_RGB_DIAGRAMS.md`: SoC/RGB diagram notes.
- `docs/SW_TRAP_PLIC_VISUAL_GUIDE.md`: trap/PLIC/firmware visual guide.
- `docs/portfolio/`: portfolio and presentation notes.
- `docs/diagrams_svg/`: SVG diagrams.
- `docs/diagrams_drawio/`: drawio editable diagrams.

## HW

- `HW/rtl/src/`: synthesizable RTL source snapshot.
- `HW/tb/`: hand-written SystemVerilog testbenches only; xsim generated output is excluded.
- `HW/constraints/`: board constraint files.
- `HW/constraints/slave/`: slave-side Basys3 constraint files.
- `HW/vivado_tools/`: Vivado Tcl helper scripts for build/program/report/sim flows.
- `HW/rom_images/timing_programs/`: ROM machine-code `.mem` files consumed by RTL.
- `HW/bitstreams/`: selected known-useful `.bit` files.
- `HW/reports/`: selected timing/utilization reports.
- `HW/fpga_auto.yml`: FPGA_AUTO managed project manifest.

## SW

- `SW/firmware_sources/`: `.S` assembly firmware, C startup, C smoke, UART loader, and RAM app sources.
- `SW/build_scripts/`: PowerShell/BAT build and download entry points.
- `SW/linker_scripts/`: ROM and RAM linker scripts.
- `SW/loader_tools/`: Python bin-to-mem, loader packet, sender, and GUI tools.
- `SW/build_outputs_reference/`: selected reference ELF/BIN/MEM/DUMP/MAP/packet outputs.

## image_uart_sender

- `image_uart_sender/src/`: Python image UART send/receive/compare/GUI code.
- `image_uart_sender/images/`: sample images used by the PC-side image transfer tool.
- `image_uart_sender/docs/`: original README/execution guide from the image UART tool.
- `image_uart_sender/run_gui.bat`, `run_transfer.bat`: Windows launchers.
