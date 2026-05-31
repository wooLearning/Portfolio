`ifndef ADDER_SEQ_ITEM_SV
`define ADDER_SEQ_ITEM_SV

class adder_seq_item extends uvm_sequence_item;
  rand logic [DATA_WIDTH-1:0] iA;
  rand logic [DATA_WIDTH-1:0] iB;
       logic [DATA_WIDTH  :0] oY;
  
  `uvm_object_utils_begin(adder_seq_item)
    `uvm_field_int(iA, UVM_ALL_ON)
    `uvm_field_int(iB, UVM_ALL_ON)
    `uvm_field_int(oY, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "adder_seq_item");
    super.new(name);
  endfunction
  
endclass



`endif
