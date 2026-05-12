`ifndef RAM_SEQ_ITEM_SV
`define RAM_SEQ_ITEM_SV

class ram_seq_item extends uvm_sequence_item;

  rand  logic                   iCs;
  rand  logic                   iWea;
  rand  logic [ADDR_WIDTH-1:0]  iAddr;
  rand  logic [DATA_WIDTH-1:0]  iWData;

  logic [DATA_WIDTH-1:0]  oRData;

  constraint cs_c{
    iCs dist {1'b1 := 9, 1'b0 := 1};
  }

  constraint wea_c{ //read write 5 5
    iWea dist {1'b1:=5, 1'b0:=5};
  }

  `uvm_object_utils_begin(ram_seq_item)
    `uvm_field_int(iCs,    UVM_ALL_ON)
    `uvm_field_int(iWea,   UVM_ALL_ON)
    `uvm_field_int(iAddr,  UVM_ALL_ON)
    `uvm_field_int(iWData, UVM_ALL_ON)
    `uvm_field_int(oRData, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "ram_seq_item");
    super.new(name);
  endfunction

endclass

`endif
