# Communication UVM Project

This directory is the cleaned `uvm_ttt` communication copy. It keeps the Vivado/XSim-oriented source organization while matching the Basic project's `rtl` and `tb` naming style.

## Protocols

```text
uart/
  rtl/
  tb/rx/
  tb/tx/
  sim/vivado/rx/
  sim/vivado/tx/

spi/
  rtl/
  tb/common/
  tb/master/
  tb/slave/
  sim/vivado/master/
  sim/vivado/slave/

i2c/
  rtl/
  tb/common/
  tb/master/
  tb/slave/
  sim/vivado/master/
  sim/vivado/slave/
```

## Vivado/XSim Notes

Run from the target TB directory so `files.f` relative paths resolve correctly.

Example:

```sh
cd projects/communication/uart/tb/rx
xvlog -sv -L uvm -f files.f
xelab -L uvm tb_uart_rx -s tb_uart_rx_snap
xsim -f ../../sim/vivado/rx/xsim_args_all.f
```

Use the matching role path for the other benches:

- `uart/tb/tx` with `../../sim/vivado/tx`
- `spi/tb/master` with `../../sim/vivado/master`
- `spi/tb/slave` with `../../sim/vivado/slave`
- `i2c/tb/master` with `../../sim/vivado/master`
- `i2c/tb/slave` with `../../sim/vivado/slave`

Raw compiled XSim directories and waveform databases were not copied into this source tree. Evidence logs and coverage text were separated into `artifacts/communication`.
