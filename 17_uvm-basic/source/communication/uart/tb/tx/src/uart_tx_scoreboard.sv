`ifndef UART_TX_SCOREBOARD_SV
`define UART_TX_SCOREBOARD_SV

class uart_tx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_tx_scoreboard)

  uvm_analysis_imp_exp #(uart_tx_seq_item, uart_tx_scoreboard) exp_recv;
  uvm_analysis_imp_obs #(uart_tx_obs_item, uart_tx_scoreboard) obs_recv;
  uvm_analysis_port #(uart_tx_seq_item) coverage_ap;

  uart_tx_seq_item mExpectedQ[$];
  bit              mNoEventFailed[int unsigned];
  int unsigned     mPassCount;
  int unsigned     mFailCount;

  function new(string name = "uart_tx_scoreboard", uvm_component parent);
    super.new(name, parent);
    exp_recv   = new("exp_recv", this);
    obs_recv   = new("obs_recv", this);
    coverage_ap = new("coverage_ap", this);
    mPassCount = 0;
    mFailCount = 0;
  endfunction

  function uart_tx_seq_item clone_expected(uart_tx_seq_item item);
    uart_tx_seq_item cloned;

    cloned = uart_tx_seq_item::type_id::create("scb_expected_clone");
    cloned.copy(item);
    return cloned;
  endfunction

  function bit expects_no_observed_result(uart_tx_result_e result);
    return (result == UART_TX_RESULT_IGNORED) ||
           (result == UART_TX_RESULT_RESET_ABORT) ||
           (result == UART_TX_RESULT_TIMEOUT_ABORT);
  endfunction

  function void write_exp(uart_tx_seq_item item);
    uart_tx_seq_item exp_item;

    if (item.is_window_done) begin
      if (mNoEventFailed.exists(item.item_id)) begin
        mNoEventFailed.delete(item.item_id);
        return;
      end

      if ((mExpectedQ.size() == 0) ||
          (mExpectedQ[0].item_id != item.item_id) ||
          !expects_no_observed_result(mExpectedQ[0].expected_result)) begin
        mFailCount++;
        `uvm_error("UART_TX_SCB",
                   $sformatf("Unexpected no-event window completion id=%0d",
                             item.item_id))
        return;
      end

      void'(mExpectedQ.pop_front());
      mPassCount++;
      coverage_ap.write(clone_expected(item));
      `uvm_info("UART_TX_SCB",
                $sformatf("NO-EVENT PASS id=%0d result=%0d",
                          item.item_id, item.expected_result),
                UVM_LOW)
      return;
    end

    exp_item = clone_expected(item);
    mExpectedQ.push_back(exp_item);
  endfunction

  function void write_obs(uart_tx_obs_item item);
    uart_tx_seq_item expected;

    if (mExpectedQ.size() == 0) begin
      mFailCount++;
      `uvm_error("UART_TX_SCB",
                 $sformatf("Unexpected observed frame data=0x%0h done=%0b",
                           item.data, item.saw_done))
      return;
    end

    expected = mExpectedQ[0];

    if (expects_no_observed_result(expected.expected_result)) begin
      mFailCount++;
      mNoEventFailed[expected.item_id] = 1'b1;
      void'(mExpectedQ.pop_front());
      `uvm_error("UART_TX_SCB",
                 $sformatf("Observed frame during no-event item id=%0d expected=%0d actual_data=0x%0h",
                           expected.item_id, expected.expected_result,
                           item.data))
      return;
    end

    void'(mExpectedQ.pop_front());

    if (expected.data !== item.data) begin
      mFailCount++;
      `uvm_error("UART_TX_SCB",
                 $sformatf("DATA MISMATCH id=%0d expected=0x%0h actual=0x%0h",
                           expected.item_id, expected.data, item.data))
      return;
    end

    if (!item.stop_bit) begin
      mFailCount++;
      `uvm_error("UART_TX_SCB",
                 $sformatf("STOP BIT MISMATCH id=%0d data=0x%0h",
                           expected.item_id, item.data))
      return;
    end

    if (!item.saw_done) begin
      mFailCount++;
      `uvm_error("UART_TX_SCB",
                 $sformatf("MISSING DONE id=%0d data=0x%0h",
                           expected.item_id, item.data))
      return;
    end

    mPassCount++;
    coverage_ap.write(clone_expected(expected));
    `uvm_info("UART_TX_SCB",
              $sformatf("PASS id=%0d data=0x%0h",
                        expected.item_id, item.data),
              UVM_LOW)
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    if (mExpectedQ.size() != 0) begin
      mFailCount += mExpectedQ.size();
      `uvm_error("UART_TX_SCB",
                 $sformatf("Unmatched expected items=%0d", mExpectedQ.size()))
    end

    `uvm_info("UART_TX_SCB",
              $sformatf("Scoreboard pass=%0d fail=%0d", mPassCount, mFailCount),
              UVM_LOW)
  endfunction
endclass

`endif
