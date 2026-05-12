`ifndef FIFO_SEQ_ITEM_SV
`define FIFO_SEQ_ITEM_SV

class fifo_seq_item extends uvm_sequence_item;
  rand logic                  iWrEn;
  rand logic                  iRdEn;
  rand logic [DATA_WIDTH-1:0] iWrData;

  logic [DATA_WIDTH-1:0] oRdData;
  logic                  oFull;
  logic                  oEmpty;
  logic [ADDR_WIDTH:0]   oCount;

  constraint wr_en_c {
    iWrEn dist {1'b1 := 5, 1'b0 := 5};
  }

  constraint rd_en_c {
    iRdEn dist {1'b1 := 5, 1'b0 := 5};
  }

  `uvm_object_utils_begin(fifo_seq_item)
    `uvm_field_int(iWrEn,  UVM_ALL_ON)
    `uvm_field_int(iRdEn,  UVM_ALL_ON)
    `uvm_field_int(iWrData,UVM_ALL_ON)
    `uvm_field_int(oRdData,UVM_ALL_ON)
    `uvm_field_int(oFull,  UVM_ALL_ON)
    `uvm_field_int(oEmpty, UVM_ALL_ON)
    `uvm_field_int(oCount, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "fifo_seq_item");
    super.new(name);
  endfunction
endclass

`endif
