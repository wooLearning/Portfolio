`ifndef RAM_SCOREBOARD_SV
`define RAM_SCOREBOARD_SV

class ram_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ram_scoreboard)

  uvm_analysis_imp #(ram_seq_item, ram_scoreboard) recv;
  logic [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];

  function new(string name = "ram_scoreboard", uvm_component parent);
    super.new(name, parent);
    recv = new("recv", this);

    foreach (model_mem[idx]) begin
      model_mem[idx] = '0;
    end
  endfunction

  function void write(ram_seq_item item);
    logic [DATA_WIDTH-1:0] expected;

    if (item.iWea) begin
      model_mem[item.iAddr] = item.iWData;
      `uvm_info("RAM_SCB",
                $sformatf("WRITE addr=0x%0h data=0x%0h", item.iAddr, item.iWData),
                UVM_LOW)
    end else begin
      expected = model_mem[item.iAddr];

      if (item.oRData !== expected) begin
        `uvm_error("RAM_SCB",
                   $sformatf("READ MISMATCH addr=0x%0h expected=0x%0h actual=0x%0h",
                             item.iAddr, expected, item.oRData))
      end else begin
        `uvm_info("RAM_SCB",
                  $sformatf("READ PASS addr=0x%0h data=0x%0h", item.iAddr, item.oRData),
                  UVM_LOW)
      end
    end
  endfunction

endclass

`endif
