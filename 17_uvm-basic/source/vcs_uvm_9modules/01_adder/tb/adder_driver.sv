`ifndef ADDER_DRIVER_SV
`define ADDER_DRIVER_SV

class adder_driver extends uvm_driver #(adder_seq_item);
  `uvm_component_utils(adder_driver)
  
  virtual adder_if adder_vif;

  function new(string name = "adder_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual adder_if)::get(this, "", "adder_vif", adder_vif)) begin
      `uvm_fatal("ADDER_DRV", "Driver failed to get virtual interface")
    end
  endfunction
  
  task run_phase(uvm_phase phase);
    adder_seq_item item;

    forever begin
      seq_item_port.get_next_item(item);

      adder_vif.iA = item.iA;
      adder_vif.iB = item.iB;
      #1;
      seq_item_port.item_done();
    end
  endtask

endclass


`endif
