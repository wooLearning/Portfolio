`ifndef FIFO_DRIVER_SV
`define FIFO_DRIVER_SV

class fifo_driver extends uvm_driver #(fifo_seq_item);
  `uvm_component_utils(fifo_driver)

  virtual fifo_if fifo_vif;

  function new(string name = "fifo_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "fifo_vif", fifo_vif)) begin
      `uvm_fatal("FIFO_DRV", "Driver failed to get virtual interface")
    end
  endfunction

  task automatic drive_idle();
    fifo_vif.iWrEn   <= 1'b0;
    fifo_vif.iRdEn   <= 1'b0;
    fifo_vif.iWrData <= '0;
  endtask

  task automatic drive_item(fifo_seq_item item);
    @(fifo_vif.drv_cb);
    fifo_vif.drv_cb.iWrEn   <= item.iWrEn;
    fifo_vif.drv_cb.iRdEn   <= item.iRdEn;
    fifo_vif.drv_cb.iWrData <= item.iWrData;

    @(fifo_vif.drv_cb);
    drive_idle();
  endtask

  task run_phase(uvm_phase phase);
    fifo_seq_item item;

    drive_idle();
    wait (fifo_vif.iRstn === 1'b1);

    forever begin
      seq_item_port.get_next_item(item);

      if (fifo_vif.iRstn !== 1'b1) begin
        drive_idle();
        wait (fifo_vif.iRstn === 1'b1);
      end

      drive_item(item);
      seq_item_port.item_done();
    end
  endtask
endclass

`endif
