`ifndef FIFO_MONITOR_SV
`define FIFO_MONITOR_SV

class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)

  virtual fifo_if fifo_vif;
  uvm_analysis_port #(fifo_seq_item) send;

  function new(string name = "fifo_monitor", uvm_component parent);
    super.new(name, parent);
    send = new("send", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "fifo_vif", fifo_vif)) begin
      `uvm_fatal("FIFO_MON", "Monitor failed to get virtual interface")
    end
  endfunction

  task run_phase(uvm_phase phase);
    fifo_seq_item item;

    forever begin
      @(fifo_vif.mon_cb);

      if (!fifo_vif.mon_cb.iRstn) begin
        continue;
      end

      item = fifo_seq_item::type_id::create("mon_item");
      item.iWrEn   = fifo_vif.mon_cb.iWrEn;
      item.iRdEn   = fifo_vif.mon_cb.iRdEn;
      item.iWrData = fifo_vif.mon_cb.iWrData;
      item.oRdData = fifo_vif.mon_cb.oRdData;
      item.oFull   = fifo_vif.mon_cb.oFull;
      item.oEmpty  = fifo_vif.mon_cb.oEmpty;
      item.oCount  = fifo_vif.mon_cb.oCount;

      send.write(item);
    end
  endtask
endclass

`endif
