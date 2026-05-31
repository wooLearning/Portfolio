`ifndef ADDER_MONITOR_SV
`define ADDER_MONITOR_SV

class adder_monitor extends uvm_monitor;
  `uvm_component_utils(adder_monitor)

  virtual adder_if adder_vif;

  uvm_analysis_port #(adder_seq_item) send;

  function new(string name = "adder_monitor", uvm_component parent);
    super.new(name, parent);
    send = new("send", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual adder_if)::get(this, "", "adder_vif", adder_vif)) begin
      `uvm_fatal("ADDER_MON", "Monitor failed to get virtual interface")
    end
  endfunction

  task run_phase(uvm_phase phase);
    adder_seq_item mon_item;

    forever begin
      #1;

      mon_item = adder_seq_item::type_id::create("mon_item");

      mon_item.iA = adder_vif.iA;
      mon_item.iB = adder_vif.iB;
      mon_item.oY = adder_vif.oY;

      send.write(mon_item);
    end
  endtask
endclass

`endif
