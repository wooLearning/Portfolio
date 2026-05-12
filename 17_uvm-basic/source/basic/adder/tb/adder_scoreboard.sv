`ifndef ADDER_SCOREBOARD_SV 
`define ADDER_SCOREBOARD_SV

class adder_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(adder_scoreboard)

  uvm_analysis_imp #(adder_seq_item, adder_scoreboard) recv;
  
  function new(string name = "adder_scoreboard", uvm_component parent); 
    super.new(name, parent);
    recv = new("recv", this);
  endfunction

  function void write(adder_seq_item item);
    logic [DATA_WIDTH:0] expected;

    expected = item.iA + item.iB;

    if(item.oY != expected) begin
       `uvm_error("ADDER_SCB",$sformatf("Mismatch: iA=0x%0h iB=0x%0h expected=0x%0h actual=0x%0h",
                  item.iA, item.iB, expected, item.oY))
    end
    else begin
      `uvm_info("ADDER_SCB",$sformatf("PASS: iA=0x%0h iB=0x%0h oY=0x%0h",
                item.iA, item.iB, item.oY), UVM_LOW)
    end
  endfunction

endclass
`endif