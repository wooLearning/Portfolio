# UVM_TEST Workspace

`UVM_Basic` and `uvm_ttt` have been organized here as a clean working copy.

The original folders were left untouched:

- `C:\Users\user\Desktop\MAIN_ing\10_Projects\UVM_Basic`
- `C:\Users\user\Desktop\MAIN_ing\10_Projects\uvm_ttt`

## Layout

```text
projects/
  basic/                 # Makefile + VCS/Verdi baseline
    adder/
    fifo/
    ram/
  communication/         # Vivado/XSim-oriented UART/SPI/I2C copy
    uart/
    spi/
    i2c/

docs/
  diagrams/              # module/protocol-named diagrams
  captures/              # renamed screenshots
  reports/               # final reports and handoff notes

artifacts/
  communication/         # Vivado logs and coverage evidence
```

## Basic Flow

The Basic project keeps the Makefile structure from `UVM_Basic`.

```sh
cd projects/basic
make run BLOCK=adder
make run BLOCK=ram
make run BLOCK=fifo
make run-all
```

## Communication Flow

The communication project is grouped by protocol:

- `projects/communication/uart`: UART RX/TX RTL and UVM TBs
- `projects/communication/spi`: SPI master/slave RTL and UVM TBs
- `projects/communication/i2c`: I2C master/slave RTL and UVM TBs

Each protocol uses:

```text
rtl/
tb/
sim/vivado/
```

Vivado/XSim argument files from `uvm_ttt` are preserved under each protocol's `sim/vivado/<role>` directory.

## Documentation

- Basic diagrams: `docs/diagrams/basic`
- Communication diagrams and style references: `docs/diagrams/communication`, `docs/diagrams/style_reference`
- Basic reports: `docs/reports/basic`
- Communication reports: `docs/reports/communication`
- Vivado/XSim evidence: `artifacts/communication`
