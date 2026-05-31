`ifndef RAM_SEQUENCE_SV
`define RAM_SEQUENCE_SV

class ram_sequence extends uvm_sequence #(ram_seq_item);
  `uvm_object_utils(ram_sequence)

  function new(string name = "ram_sequence");
    super.new(name);
  endfunction

  task automatic send_item_cs_on_test(bit wea,
                                      logic [ADDR_WIDTH-1:0] addr);
    ram_seq_item item;

    item = ram_seq_item::type_id::create("cs_on_item");
    start_item(item);

    if (!item.randomize() with {
      iCs   == 1'b1;
      iWea  == wea;
      iAddr == addr;
    }) begin
      `uvm_error("RAM_SEQ", "CS-on item randomization failed")
    end

    finish_item(item);
  endtask

  task automatic send_directed(bit wea,
                               logic [ADDR_WIDTH-1:0] addr,
                               logic [DATA_WIDTH-1:0] data);
    ram_seq_item item;

    item = ram_seq_item::type_id::create("directed_item");
    start_item(item);

    if (!item.randomize() with {
      iCs    == 1'b1;
      iWea   == wea;
      iAddr  == addr;
      iWData == data;
    }) begin
      `uvm_error("RAM_SEQ", "Directed item randomization failed")
    end

    finish_item(item);
  endtask

  task automatic send_item_random_test();
    ram_seq_item item;

    item = ram_seq_item::type_id::create("random_item");
    start_item(item);

    if (!item.randomize()) begin
      `uvm_error("RAM_SEQ", "Random item randomization failed")
    end

    finish_item(item);
  endtask

  task body();
    int unsigned addr;
    logic [ADDR_WIDTH-1:0] first_addr;
    logic [ADDR_WIDTH-1:0] last_addr;
    logic [ADDR_WIDTH-1:0] misc_addr;
    logic [DATA_WIDTH-1:0] zero_data;
    logic [DATA_WIDTH-1:0] ones_data;
    logic [DATA_WIDTH-1:0] misc_data;

    first_addr = '0;
    last_addr  = DEPTH - 1;
    misc_addr  = DEPTH / 2;
    zero_data  = '0;
    ones_data  = '1;
    misc_data  = 32'h5a5a_a5a5;

    send_directed(1'b1, first_addr, zero_data);
    send_directed(1'b0, first_addr, '0);
    send_directed(1'b1, last_addr, ones_data);
    send_directed(1'b0, last_addr, '0);
    send_directed(1'b1, misc_addr, misc_data);
    send_directed(1'b0, misc_addr, '0);

    for (addr = 0; addr < DEPTH; addr++) begin
      send_item_cs_on_test(1'b1, addr[ADDR_WIDTH-1:0]);
      send_item_cs_on_test(1'b0, addr[ADDR_WIDTH-1:0]);
    end

    repeat (100) begin
      send_item_random_test();
    end
  endtask

endclass

`endif
