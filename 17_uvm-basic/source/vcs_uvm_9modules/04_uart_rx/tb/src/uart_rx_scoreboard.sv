`ifndef UART_RX_SCOREBOARD_SV
`define UART_RX_SCOREBOARD_SV

class uart_rx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_rx_scoreboard)

  uvm_analysis_imp_exp #(uart_rx_seq_item, uart_rx_scoreboard) exp_recv;
  uvm_analysis_imp_obs #(uart_rx_obs_item, uart_rx_scoreboard) obs_recv;
  uvm_analysis_imp_ser #(uart_rx_serial_item, uart_rx_scoreboard) ser_recv;
  uvm_analysis_port #(uart_rx_seq_item) coverage_ap;

  uart_rx_seq_item mExpectedQ[$];
  uart_rx_seq_item mSerialExpectedQ[$];
  bit              mNoEventFailed[int unsigned];
  int unsigned     mPassCount;
  int unsigned     mFailCount;

  function new(string name = "uart_rx_scoreboard", uvm_component parent);
    super.new(name, parent);
    exp_recv   = new("exp_recv", this);
    obs_recv   = new("obs_recv", this);
    ser_recv   = new("ser_recv", this);
    coverage_ap = new("coverage_ap", this);
    mPassCount = 0;
    mFailCount = 0;
  endfunction

  function uart_rx_seq_item clone_expected(uart_rx_seq_item item);
    uart_rx_seq_item cloned;

    cloned = uart_rx_seq_item::type_id::create("scb_expected_clone");
    cloned.copy(item);
    return cloned;
  endfunction

  function bit expects_no_observed_result(uart_rx_result_e result);
    return (result == UART_RX_RESULT_FALSE_START) ||
           (result == UART_RX_RESULT_RESET_ABORT);
  endfunction

  function bit expects_serial_result(uart_rx_result_e result);
    return (result == UART_RX_RESULT_VALID) ||
           (result == UART_RX_RESULT_FRAME_ERROR) ||
           (result == UART_RX_RESULT_FALSE_START);
  endfunction

  function void write_exp(uart_rx_seq_item item);
    uart_rx_seq_item exp_item;

    if (item.is_window_done) begin
      if (mNoEventFailed.exists(item.item_id)) begin
        mNoEventFailed.delete(item.item_id);
        return;
      end

      if ((mExpectedQ.size() == 0) ||
          (mExpectedQ[0].item_id != item.item_id) ||
          !expects_no_observed_result(mExpectedQ[0].expected_result)) begin
        mFailCount++;
        `uvm_error("UART_RX_SCB",
                   $sformatf("Unexpected no-event window completion id=%0d",
                             item.item_id))
        return;
      end

      void'(mExpectedQ.pop_front());
      mPassCount++;
      coverage_ap.write(clone_expected(item));
      `uvm_info("UART_RX_SCB",
                $sformatf("NO-EVENT PASS id=%0d result=%0d",
                          item.item_id, item.expected_result),
                UVM_LOW)
      return;
    end

    exp_item = clone_expected(item);
    mExpectedQ.push_back(exp_item);

    if (expects_serial_result(item.expected_result)) begin
      mSerialExpectedQ.push_back(clone_expected(item));
    end
  endfunction

  function void write_ser(uart_rx_serial_item item);
    uart_rx_seq_item expected;

    if (mSerialExpectedQ.size() == 0) begin
      mFailCount++;
      `uvm_error("UART_RX_SCB",
                 $sformatf("Unexpected serial frame result=%0d data=0x%0h",
                           item.result, item.data))
      return;
    end

    expected = mSerialExpectedQ.pop_front();

    if (expected.expected_result != item.result) begin
      mFailCount++;
      `uvm_error("UART_RX_SCB",
                 $sformatf("SERIAL RESULT MISMATCH id=%0d expected=%0d actual=%0d data=0x%0h",
                           expected.item_id, expected.expected_result,
                           item.result, item.data))
      return;
    end

    if ((expected.expected_result == UART_RX_RESULT_VALID) &&
        (expected.data !== item.data)) begin
      mFailCount++;
      `uvm_error("UART_RX_SCB",
                 $sformatf("SERIAL DATA MISMATCH id=%0d expected=0x%0h actual=0x%0h",
                           expected.item_id, expected.data, item.data))
      return;
    end
  endfunction

  function void write_obs(uart_rx_obs_item item);
    uart_rx_seq_item expected;

    if (mExpectedQ.size() == 0) begin
      mFailCount++;
      `uvm_error("UART_RX_SCB",
                 $sformatf("Unexpected observed result=%0d data=0x%0h",
                           item.result, item.data))
      return;
    end

    expected = mExpectedQ[0];

    if (expects_no_observed_result(expected.expected_result)) begin
      mFailCount++;
      mNoEventFailed[expected.item_id] = 1'b1;
      void'(mExpectedQ.pop_front());
      `uvm_error("UART_RX_SCB",
                 $sformatf("Observed result during no-event item id=%0d expected=%0d actual=%0d data=0x%0h",
                           expected.item_id, expected.expected_result,
                           item.result, item.data))
      return;
    end

    void'(mExpectedQ.pop_front());

    if (expected.expected_result != item.result) begin
      if (!((expected.expected_result == UART_RX_RESULT_TIMEOUT) &&
            (item.result == UART_RX_RESULT_FRAME_ERROR))) begin
        mFailCount++;
        `uvm_error("UART_RX_SCB",
                   $sformatf("RESULT MISMATCH id=%0d expected=%0d actual=%0d data=0x%0h",
                             expected.item_id, expected.expected_result,
                             item.result, item.data))
        return;
      end
    end

    if ((expected.expected_result == UART_RX_RESULT_VALID) &&
        (expected.data !== item.data)) begin
      mFailCount++;
      `uvm_error("UART_RX_SCB",
                 $sformatf("DATA MISMATCH id=%0d expected=0x%0h actual=0x%0h",
                           expected.item_id, expected.data, item.data))
      return;
    end

    mPassCount++;
    coverage_ap.write(clone_expected(expected));
    `uvm_info("UART_RX_SCB",
              $sformatf("PASS id=%0d result=%0d data=0x%0h",
                        expected.item_id, item.result, item.data),
              UVM_LOW)
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    if (mExpectedQ.size() != 0) begin
      mFailCount += mExpectedQ.size();
      `uvm_error("UART_RX_SCB",
                 $sformatf("Unmatched expected items=%0d", mExpectedQ.size()))
    end

    if (mSerialExpectedQ.size() != 0) begin
      mFailCount += mSerialExpectedQ.size();
      `uvm_error("UART_RX_SCB",
                 $sformatf("Unmatched serial expected items=%0d",
                           mSerialExpectedQ.size()))
    end

    `uvm_info("UART_RX_SCB",
              $sformatf("Scoreboard pass=%0d fail=%0d", mPassCount, mFailCount),
              UVM_LOW)
  endfunction
endclass

`endif
