# Communication Module UVM BFM Verification Plan

## Purpose

Plan a UVM verification strategy for `communication_module` using protocol BFMs instead of loopback-first testing.

The main rule is:

```text
If the DUT is a master, UVM models the slave side.
If the DUT is a slave or receiver, UVM models the master/transmitter side.
```

This keeps the DUT isolated, makes failures easier to localize, and lets the UVM side inject jitter, aborts, bad frames, NACKs, and reset timing intentionally.

## References

- Use `svUVMSkill.md` for project UVM style.
- Use `uvm-core-2020.3.1` and `uvm_doc` first when UVM implementation details are ambiguous.
- Search for additional references only when those local references are not enough.

## Common Architecture

Use the standard UVM hierarchy for each protocol:

```text
*_seq_item
*_sequence
*_sequencer
*_driver
*_monitor
*_scoreboard
*_coverage
*_agent
*_env
*_test
```

Each protocol interface should separate driver and monitor timing:

```systemverilog
clocking drv_cb @(posedge iClk);
  default input #1step output #1;
endclocking

clocking mon_cb @(posedge iClk);
  default input #1step output #1;
endclocking
```

Driver rules:

- Drive DUT inputs only through `drv_cb`.
- Drive idle values during reset.
- Do not decode protocol results inside the driver.
- Own intentional stimulus timing such as tick spacing, jitter, abort, and reset insertion.

Monitor rules:

- Sample DUT pins and outputs only through `mon_cb`.
- Decode protocol behavior from observed signals, not from driver assumptions.
- Publish observed transactions through analysis ports.
- Drop partial transactions on reset unless the test explicitly checks reset behavior.

Scoreboard rules:

- Compare expected transactions from sequences or predictors against monitor-observed results.
- Flush or mark in-flight expected items when reset is injected.
- Keep protocol checking out of coverage.

Coverage rules:

- Sample from monitor and scoreboard analysis streams.
- Cover normal transactions, timing variations, injected errors, and reset/abort cases.
- Keep protocol-specific covergroups in protocol-specific `*_coverage.sv` files.

## Verification Methods

Use these methods in the first pass:

- UVM BFM-based block verification.
- MDV-style functional coverage closure using protocol-specific covergroups.
- ABV-style simulation assertions for protocol invariants and illegal signal combinations.
- Error tests for bad frames, aborts, NACKs, wrong addresses, and reset during transactions.
- Jitter tests for UART `iTick16x` and protocol tick spacing variation.

Do not include formal verification in the first pass.

## UART Plan

### UART RX DUT

```text
DUT: uart_rx
UVM BFM: UART TX serial-line generator
Monitor: DUT output/status monitor
Scoreboard: transmitted frame intent vs oRxData/oRxValid/oFrameError
```

The UART TX BFM drives `iRx` and controls `iTick16x` timing according to the selected tick mode. This is the first target because it exercises BFM-driven serial timing, error tests, jitter tests, assertions, coverage, and scoreboard policy in the smallest protocol surface.

#### Scenarios

- Valid single frame: one start bit, 8 data bits LSB-first, one stop bit.
- Directed byte frames: `8'h00`, `8'hFF`, `8'h55`, `8'hAA`, walking 1, walking 0.
- Random byte frames.
- Back-to-back frames with minimum legal idle gap.
- Frames with variable idle gaps.
- Bad stop bit: stop bit driven low long enough to trigger `oFrameError`.
- False start: short low pulse on `iRx` that returns high before the RX mid-start sample.
- Reset during START, DATA, and STOP.
- Jitter test: bounded early/late movement of `iTick16x` spacing while preserving frame intent.
- Tick mode test:
  - Direct TB-generated `iTick16x`.
  - `uart_baud_tick` with integer-divider mode.
  - `uart_baud_tick` with phase-accumulator mode.

#### Assertions

- `oRxValid` and `oFrameError` must not be high in the same cycle.
- During reset, `oRxValid` and `oFrameError` must remain low.
- A valid frame must produce exactly one `oRxValid` pulse.
- A bad stop-bit frame must produce exactly one `oFrameError` pulse and no `oRxValid` pulse.
- A false start must not produce `oRxValid` or `oFrameError`.
- `oRxBusy` should assert after a confirmed start and deassert after valid, error, or reset termination.

#### Scoreboard

- Expected source: UART TX BFM publishes frame intent before driving the serial line.
- Observed source: RX output monitor publishes DUT status events from `oRxData`, `oRxValid`, `oFrameError`, and `oRxBusy`.
- Compare policy:
  - Valid frame: expected data must match `oRxData` when `oRxValid` pulses.
  - Bad stop bit: expected error must match `oFrameError`; no data compare is performed.
  - False start: scoreboard expects no completed observed transaction.
  - Reset-aborted frame: scoreboard marks the in-flight expected item as aborted and does not require valid/error completion after reset.

#### Driver/Monitor Timing

- Driver drives `iRx` through `drv_cb`.
- Driver generates or selects `iTick16x` timing from the scenario configuration.
- Monitor samples `iRx`, `iTick16x`, and DUT outputs through `mon_cb`.
- Monitor records start, data, and stop phases using observed tick positions, not BFM private counters.
- Reset handling is explicit: driver idles `iRx` high, monitor drops partial decode state, scoreboard flushes or marks aborted expectations.

#### Coverage

- Byte pattern: zero, all ones, alternating, walking 1, walking 0, random.
- Frame result: valid, frame error, false start, reset abort.
- Reset phase: idle, start, data, stop.
- Tick source: direct, integer divider, phase accumulator.
- Jitter mode: none, bounded early/late, bounded random.
- Idle gap: minimum, short, medium, long.

### UART TX DUT

```text
DUT: uart_tx
UVM driver: command-side iTxData/iTxValid stimulus
Monitor/BFM: UART RX serial decoder observing oTx
Scoreboard: requested byte vs decoded serial frame and oTxDone timing
```

#### Scenarios

- Valid transmit for directed and random byte values.
- Single request when `oTxReady` is high.
- Back-to-back requests accepted on legal ready cycles.
- Request attempted while `oTxReady` is low; driver should either wait or intentionally check that DUT ignores the illegal request according to the selected test.
- Reset during START, DATA, and STOP.
- Tick mode test:
  - Direct TB-generated `iTick16x`.
  - `uart_baud_tick` with integer-divider mode.
  - `uart_baud_tick` with phase-accumulator mode.
- Jitter test on direct `iTick16x` spacing.

#### Assertions

- `oTx` must idle high when not busy.
- `oTxDone` must be a one-cycle pulse.
- `oTxReady` and `oTxBusy` must not both represent active transfer readiness at the same time.
- Accepted transmit request must eventually produce one `oTxDone` unless reset aborts the frame.
- During reset, `oTxDone` must remain low and `oTx` must return high after reset behavior settles.

#### Scoreboard

- Expected source: command-side sequence item accepted when `iTxValid && oTxReady` is observed.
- Observed source: UART RX serial decoder monitor reconstructs byte and frame timing from `oTx`.
- Compare policy:
  - Accepted item data must match decoded serial byte.
  - `oTxDone` must align with end-of-frame completion.
  - Requests while not ready are not added to the expected queue unless the scenario explicitly expects illegal-request behavior.
  - Reset aborts the active expected item.

#### Driver/Monitor Timing

- Driver drives `iTxData` and `iTxValid` through `drv_cb`.
- Driver waits for `oTxReady` through `drv_cb` input sampling for legal transactions.
- Monitor decodes `oTx` through `mon_cb` and observed `iTick16x`.
- Monitor must detect start bit, 8 data bits LSB-first, and stop bit from the serial line.
- Scoreboard uses monitor-decoded serial data as the independent observed result, not DUT internal state.

#### Coverage

- Byte pattern: zero, all ones, alternating, walking 1, walking 0, random.
- Handshake: accepted when ready, attempted while busy, back-to-back accepted.
- Reset phase: idle, start, data, stop.
- Tick source: direct, integer divider, phase accumulator.
- Jitter mode: none, bounded early/late, bounded random.

## SPI Plan

### SPI Master DUT

```text
DUT: spi_master
UVM BFM: SPI slave responder
Monitor: SCLK/CS/MOSI/MISO bus monitor
Scoreboard: master TX/RX intent vs observed bus and oRxData/oDone
```

The slave BFM responds on MISO according to observed `oCsN`, `oSclk`, CPOL, and CPHA. It must not assume driver-side timing beyond what appears on the bus.

#### Scenarios

- CPOL/CPHA mode sweep across all 4 modes.
- Directed TX/RX byte pairs.
- Random TX/RX byte pairs.
- Minimum legal transfer with one byte.
- Back-to-back transfers with idle gap.
- Irregular `iTick` spacing.
- Reset while busy.
- Slave BFM releases or drives inactive MISO value when `oCsN` is high.

#### Assertions

- `oCsN` must be low during active transfer and high while idle/done.
- `oSclk` must return to CPOL idle level outside active transfer.
- `oDone` must be a one-cycle pulse.
- `oBusy` must remain high from accepted start until transfer completion.
- No SCLK toggles should be treated as transfer edges while `oCsN` is high.

#### Scoreboard

- Expected source: master command sequence item contains `iTxData`, expected slave response byte, CPOL, CPHA, and tick spacing mode.
- Observed source:
  - SPI bus monitor decodes MOSI byte from observed `oSclk`, `oCsN`, `oMosi`.
  - DUT status monitor captures `oRxData` and `oDone`.
- Compare policy:
  - Observed MOSI byte must match command TX byte.
  - DUT `oRxData` must match slave BFM MISO response byte when `oDone` pulses.
  - Reset-aborted transfer is marked aborted and removed from normal compare.

#### Driver/Monitor Timing

- Driver drives `iStart`, `iCpol`, `iCpha`, `iTxData`, and `iTick` through `drv_cb`.
- Slave BFM drives `iMiso` based on observed `oCsN` and `oSclk` timing.
- Bus monitor derives lead/trail edges from observed `oSclk` and CPOL.
- Bus monitor derives sample/shift edges from observed CPHA.
- Monitor does not rely on driver-side `iTick` counters for byte decode.

#### Coverage

- CPOL/CPHA cross.
- MOSI byte pattern.
- MISO byte pattern.
- Tick spacing: regular, irregular bounded.
- Transfer gap: single, back-to-back, delayed.
- Reset phase: idle, assert CS, transfer, complete.

### SPI Slave DUT

```text
DUT: spi_slave
UVM BFM: SPI master generator
Monitor: DUT output/status and bus monitor
Scoreboard: generated master frame vs oRxData/oRxValid/oMiso/oMisoOe
```

#### Scenarios

- CPOL/CPHA mode sweep across all 4 modes.
- Full byte transfers with directed and random MOSI values.
- Directed and random slave response data through `iTxData`.
- CS deasserted before a complete frame.
- CS gap between transfers.
- Reset during transfer.
- Master BFM samples MISO only while `oMisoOe` is active.

#### Assertions

- `oMisoOe` must be low when `iCsN` is high.
- `oRxValid` must be a one-cycle pulse.
- `oRxValid` should only occur after a complete frame.
- Reset must clear in-progress receive behavior.
- MISO should not be considered valid by the testbench when `oMisoOe` is low.

#### Scoreboard

- Expected source: SPI master BFM frame item contains MOSI byte, expected slave `iTxData`, CPOL, CPHA, and abort/reset intent.
- Observed source:
  - DUT output monitor captures `oRxData`, `oRxValid`, `oMiso`, and `oMisoOe`.
  - Bus monitor reconstructs MISO bits sampled by the master BFM.
- Compare policy:
  - Complete frame: `oRxData` must match generated MOSI byte when `oRxValid` pulses.
  - Master-sampled MISO byte must match `iTxData` for complete readback.
  - CS abort before complete frame expects no normal `oRxValid`.
  - Reset aborts active expected item.

#### Driver/Monitor Timing

- Master BFM drives `iSclk`, `iCsN`, and `iMosi` through `drv_cb`.
- Driver sets `iCpol`, `iCpha`, and `iTxData` before asserting CS.
- Monitor samples bus and DUT outputs through `mon_cb`.
- Edge decode is based on observed synchronized bus pins and selected CPOL/CPHA.
- Abort test deasserts CS at planned bit positions.

#### Coverage

- CPOL/CPHA cross.
- Complete frame vs CS abort.
- RX byte pattern.
- TX/MISO byte pattern.
- MISO output enable timing: before CS, during CS, after CS.
- Reset phase: idle, selected before data, mid-data, completion.

## I2C Plan

### I2C Master DUT

```text
DUT: i2c_master
UVM BFM: I2C slave responder
Monitor: resolved SCL/SDA bus monitor
Scoreboard: master command intent vs bus transaction and oRxData/oDone/oAckError
```

The slave BFM drives only open-drain pull-low behavior. It releases SDA for high values.

#### Scenarios

- Address hit with write ACK.
- Address hit with write data ACK.
- Address hit with read data response.
- Wrong address NACK.
- Data NACK after write.
- Reset during START, address, address ACK, data, data ACK, read data, and STOP.
- Irregular `iTick` spacing.
- Open-drain release and pull-low behavior on resolved SDA/SCL.

#### Assertions

- `oDone` must be a one-cycle pulse.
- `oAckError` must not assert for fully ACKed transactions.
- Wrong address or NACK scenario must eventually assert `oAckError`.
- During idle, SCL/SDA output enables should represent released bus behavior.
- START and STOP sequencing should preserve I2C ordering on resolved bus: START before address, STOP before done.

#### Scoreboard

- Expected source: master command item contains address, read/write, write data, expected read data, and ACK/NACK plan.
- Observed source:
  - I2C bus monitor decodes START, address byte, R/W bit, ACK/NACK, data byte, and STOP from resolved SCL/SDA.
  - DUT status monitor captures `oRxData`, `oDone`, and `oAckError`.
- Compare policy:
  - Write transaction: bus address/data must match command, and ACK plan must match observed ACK/NACK.
  - Read transaction: DUT `oRxData` must match slave BFM read data when done.
  - NACK/wrong address: `oAckError` expected, normal data compare skipped as appropriate.
  - Reset aborts active expected item.

#### Driver/Monitor Timing

- Driver drives `iStart`, `iRead`, `iSlaveAddr`, `iTxData`, and `iTick` through `drv_cb`.
- Slave BFM observes resolved SCL/SDA and drives only SDA pull-low behavior for ACK/read data.
- Bus monitor decodes START/STOP from resolved SDA transitions while SCL is high.
- Bus monitor samples data on SCL high phase according to observed bus behavior.
- Monitor does not rely only on master command fields; it reconstructs the actual bus transaction.

#### Coverage

- Direction: read, write.
- Address result: hit, miss.
- ACK/NACK point: address ACK, address NACK, write data ACK, write data NACK, read completion.
- Data pattern: zero, all ones, alternating, random.
- Reset phase: start, address, ACK, data, stop.
- Tick spacing: regular, irregular bounded.

### I2C Slave DUT

```text
DUT: i2c_slave
UVM BFM: I2C master generator
Monitor: resolved SCL/SDA bus and DUT output/status monitor
Scoreboard: generated bus transaction vs oRxData/oRxValid/oTxnDone/oTxnRead/oSdaOe
```

#### Scenarios

- Matching address write with directed and random data.
- Matching address read with directed and random `iTxData`.
- Wrong address transaction.
- STOP during partial address.
- STOP during partial write data.
- Reset during address, data, ACK, and read response.
- Master ACK after read data.
- Master NACK after read data.

#### Assertions

- `oSdaOe` must only represent pull-low behavior; high is bus release.
- `oRxValid` must be a one-cycle pulse.
- `oTxnDone` must be a one-cycle pulse.
- `oRxValid` should only assert for completed matching-address write transactions.
- Wrong address transaction must not assert `oRxValid`.
- Reset must clear in-progress transaction behavior.

#### Scoreboard

- Expected source: I2C master BFM item contains address, read/write, write data, master ACK/NACK after read, STOP/reset intent.
- Observed source:
  - Bus monitor decodes resolved SCL/SDA transaction.
  - DUT output monitor captures `oRxData`, `oRxValid`, `oTxnDone`, `oTxnRead`, and `oSdaOe`.
- Compare policy:
  - Matching write: `oRxData` must match master write data when `oRxValid` pulses.
  - Matching read: slave-driven SDA data must match `iTxData`; `oTxnRead` and `oTxnDone` must reflect read transaction completion.
  - Wrong address: no write-valid completion expected.
  - Partial STOP/reset: active expected item is marked partial or aborted; no normal completion required.

#### Driver/Monitor Timing

- Master BFM drives resolved-bus intent using open-drain style: pull low for 0, release for 1.
- Driver generates START, address, data, ACK/NACK, and STOP through `drv_cb`.
- Monitor samples resolved SCL/SDA and DUT outputs through `mon_cb`.
- Monitor derives START/STOP from observed SDA transitions while SCL is high.
- Monitor samples bits from observed SCL high windows and does not rely on BFM private counters.

#### Coverage

- Direction: read, write.
- Address result: hit, miss.
- Completion: full transaction, partial STOP, reset abort.
- Master ACK/NACK after read.
- Data pattern: zero, all ones, alternating, random.
- Reset phase: address, data, ACK, read response.

## Recommended Build Order

1. Define common config/types and clocking-block conventions.
2. Build UART RX DUT verification with UART TX BFM.
3. Build UART TX DUT verification with UART RX decoder monitor.
4. Build SPI master DUT verification with SPI slave BFM.
5. Build SPI slave DUT verification with SPI master BFM.
6. Build I2C master DUT verification with I2C slave BFM.
7. Build I2C slave DUT verification with I2C master BFM.
8. Add optional RTL-to-RTL integration sanity tests only after the per-block BFM tests are useful.

## Non-Goals For The First Pass

- Do not build a full reusable commercial-style VIP.
- Do not start with loopback as the main verification strategy.
- Do not add FIFO/APB/register wrappers until the standalone protocol cores are verified.
- Do not over-abstract common base classes before UART shows real duplication.
