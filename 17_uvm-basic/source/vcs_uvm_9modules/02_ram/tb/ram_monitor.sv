`ifndef RAM_MONITOR_SV
`define RAM_MONITOR_SV

class ram_monitor extends uvm_monitor;
  `uvm_component_utils(ram_monitor)

  virtual ram_if ram_vif;
  uvm_analysis_port #(ram_seq_item) send;

  function new(string name = "ram_monitor", uvm_component parent);
    super.new(name, parent);
    send = new("send", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual ram_if)::get(this, "", "ram_vif", ram_vif)) begin
      `uvm_fatal("RAM_MON", "Monitor failed to get virtual interface")
    end
  endfunction

  task run_phase(uvm_phase phase);
    ram_seq_item item;

    forever begin
      @(ram_vif.mon_cb);

      if (!ram_vif.mon_cb.iRstn) begin
        continue;
      end

      if (!ram_vif.mon_cb.iCs) begin
        continue;
      end

      item = ram_seq_item::type_id::create("item");
      item.iCs    = ram_vif.mon_cb.iCs;
      item.iWea   = ram_vif.mon_cb.iWea;
      item.iAddr  = ram_vif.mon_cb.iAddr;
      item.iWData = ram_vif.mon_cb.iWData;

      if (!item.iWea) begin
        #1;
        item.oRData = ram_vif.oRData;
      end else begin
        item.oRData = ram_vif.mon_cb.oRData;
      end

      send.write(item);
    end
  endtask

endclass

`endif
