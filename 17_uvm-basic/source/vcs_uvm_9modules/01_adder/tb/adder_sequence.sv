`ifndef ADDER_SEQUENCE_SV
`define ADDER_SEQUENCE_SV

class adder_sequence extends uvm_sequence #(adder_seq_item);
  `uvm_object_utils(adder_sequence)

  function new(string name = "adder_sequence");
    super.new(name);
  endfunction

  task automatic send_directed(logic [DATA_WIDTH-1:0] a,
                               logic [DATA_WIDTH-1:0] b);
    adder_seq_item item;

    item = adder_seq_item::type_id::create("directed_item");
    start_item(item);

    if (!item.randomize() with {
      iA == a;
      iB == b;
    }) begin
      `uvm_error("ADDER_SEQ", "Directed randomization failed")
    end

    finish_item(item);
  endtask

  task automatic send_random();
    adder_seq_item item;

    item = adder_seq_item::type_id::create("random_item");
    start_item(item);

    if (!item.randomize()) begin
      `uvm_error("ADDER_SEQ", "Randomization failed")
    end

    finish_item(item);
  endtask

  task body();
    logic [DATA_WIDTH-1:0] zero_value;
    logic [DATA_WIDTH-1:0] misc_value;
    logic [DATA_WIDTH-1:0] max_value;

    zero_value = '0;
    misc_value = {{(DATA_WIDTH-1){1'b0}}, 1'b1};
    max_value  = '1;

    send_directed(zero_value, zero_value);
    send_directed(zero_value, misc_value);
    send_directed(zero_value, max_value);
    send_directed(misc_value, zero_value);
    send_directed(misc_value, misc_value);
    send_directed(misc_value, max_value);
    send_directed(max_value,  zero_value);
    send_directed(max_value,  misc_value);
    send_directed(max_value,  max_value);

    repeat (50) begin
      send_random();
    end
    
  endtask

endclass


`endif
