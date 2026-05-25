`ifndef FIFO_SEQUENCE_SV
`define FIFO_SEQUENCE_SV

class fifo_sequence extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_sequence)

  function new(string name = "fifo_sequence");
    super.new(name);
  endfunction

  task automatic send_item_fifo_access(bit wr_en, bit rd_en);
    fifo_seq_item item;

    item = fifo_seq_item::type_id::create("fifo_access_item");
    start_item(item);

    if (!item.randomize() with {
      iWrEn == wr_en;
      iRdEn == rd_en;
    }) begin
      `uvm_error("FIFO_SEQ", "FIFO access item randomization failed")
    end

    finish_item(item);
  endtask

  task automatic send_item_random_test();
    fifo_seq_item item;

    item = fifo_seq_item::type_id::create("fifo_random_item");
    start_item(item);

    if (!item.randomize()) begin
      `uvm_error("FIFO_SEQ", "FIFO random item randomization failed")
    end

    finish_item(item);
  endtask

  task body();
    send_item_fifo_access(1'b0, 1'b0);
    send_item_fifo_access(1'b0, 1'b1);
    send_item_fifo_access(1'b1, 1'b0);

    send_item_fifo_access(1'b0, 1'b0);
    send_item_fifo_access(1'b1, 1'b1);
    send_item_fifo_access(1'b1, 1'b0);
    send_item_fifo_access(1'b0, 1'b1);

    repeat (DEPTH + 2) begin
      send_item_fifo_access(1'b1, 1'b0);
    end

    send_item_fifo_access(1'b0, 1'b0);
    send_item_fifo_access(1'b1, 1'b1);
    send_item_fifo_access(1'b1, 1'b0);
    send_item_fifo_access(1'b0, 1'b1);

    repeat (DEPTH + 2) begin
      send_item_fifo_access(1'b0, 1'b1);
    end

    repeat (100) begin
      send_item_random_test();
    end
  endtask
endclass

`endif
