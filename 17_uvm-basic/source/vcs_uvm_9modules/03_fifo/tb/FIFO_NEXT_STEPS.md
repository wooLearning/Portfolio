# FIFO study notes

After FIFO, a good next order is:

1. Register Block
2. APB Slave
3. APB Peripheral
4. UART
5. SPI or I2C
6. AXI4-Lite

Why this order works:

- FIFO teaches queue-based scoreboards and full/empty corner cases.
- Register Block teaches address maps, reset values, read-only/write-only fields, and mirrored models.
- APB Slave adds a simple bus protocol with setup/access phases and wait states.
- APB Peripheral combines bus verification with real block behavior.

FIFO-specific verification focus:

- Empty read should not pop.
- Full write should not push.
- Simultaneous read/write should preserve count.
- `oCount`, `oFull`, and `oEmpty` must match the reference queue state.
