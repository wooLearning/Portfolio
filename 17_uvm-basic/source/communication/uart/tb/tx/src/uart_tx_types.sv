`ifndef UART_TX_TYPES_SV
`define UART_TX_TYPES_SV

typedef enum int {
  UART_TX_RESULT_COMPLETE,
  UART_TX_RESULT_IGNORED,
  UART_TX_RESULT_RESET_ABORT,
  UART_TX_RESULT_TIMEOUT_ABORT
} uart_tx_result_e;

typedef enum int {
  UART_TX_RESET_NONE,
  UART_TX_RESET_IDLE,
  UART_TX_RESET_START,
  UART_TX_RESET_DATA,
  UART_TX_RESET_STOP
} uart_tx_reset_phase_e;

typedef enum int {
  UART_TX_TICK_DIRECT,
  UART_TX_TICK_INTEGER_DIVIDER,
  UART_TX_TICK_PHASE_ACCUMULATOR
} uart_tx_tick_mode_e;

typedef enum int {
  UART_TX_JITTER_NONE,
  UART_TX_JITTER_EARLY_LATE,
  UART_TX_JITTER_RANDOM
} uart_tx_jitter_mode_e;

`endif
