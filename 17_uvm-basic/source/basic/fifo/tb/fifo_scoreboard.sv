`ifndef FIFO_SCOREBOARD_SV
`define FIFO_SCOREBOARD_SV

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp #(fifo_seq_item, fifo_scoreboard) recv;
  logic [DATA_WIDTH-1:0] model_q[$];

  function new(string name = "fifo_scoreboard", uvm_component parent);
    super.new(name, parent);
    recv = new("recv", this);
  endfunction

  function void check_status(fifo_seq_item item);
    bit exp_full;
    bit exp_empty;
    int exp_count;

    exp_count = model_q.size();
    exp_full  = (exp_count == DEPTH);
    exp_empty = (exp_count == 0);

    if (item.oCount !== exp_count[ADDR_WIDTH:0]) begin
      `uvm_error("FIFO_SCB",
                 $sformatf("COUNT MISMATCH expected=%0d actual=%0d",
                           exp_count, item.oCount))
    end

    if (item.oFull !== exp_full) begin
      `uvm_error("FIFO_SCB",
                 $sformatf("FULL MISMATCH expected=%0b actual=%0b",
                           exp_full, item.oFull))
    end

    if (item.oEmpty !== exp_empty) begin
      `uvm_error("FIFO_SCB",
                 $sformatf("EMPTY MISMATCH expected=%0b actual=%0b",
                           exp_empty, item.oEmpty))
    end
  endfunction

  function void write(fifo_seq_item item);
    bit wr_fire;
    bit rd_fire;
    logic [DATA_WIDTH-1:0] expected;

    check_status(item);

    wr_fire = item.iWrEn && !item.oFull;
    rd_fire = item.iRdEn && !item.oEmpty;

    if (rd_fire) begin
      expected = model_q.pop_front();

      if (item.oRdData !== expected) begin
        `uvm_error("FIFO_SCB",
                   $sformatf("READ MISMATCH expected=0x%0h actual=0x%0h",
                             expected, item.oRdData))
      end else begin
        `uvm_info("FIFO_SCB",
                  $sformatf("READ PASS data=0x%0h", item.oRdData),
                  UVM_LOW)
      end
    end

    if (wr_fire) begin
      model_q.push_back(item.iWrData);
      `uvm_info("FIFO_SCB",
                $sformatf("WRITE data=0x%0h depth=%0d", item.iWrData, model_q.size()),
                UVM_LOW)
    end
  endfunction
endclass

`endif
