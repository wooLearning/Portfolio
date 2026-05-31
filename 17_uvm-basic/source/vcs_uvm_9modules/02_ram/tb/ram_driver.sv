`ifndef RAM_DRIVER_SV
`define RAM_DRIVER_SV

class ram_driver extends uvm_driver #(ram_seq_item);
  `uvm_component_utils(ram_driver)

  virtual ram_if ram_vif;

  function new(string name = "ram_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual ram_if)::get(this, "", "ram_vif", ram_vif)) begin
      `uvm_fatal("RAM_DRV", "Driver failed to get virtual interface")
    end
  endfunction

  task automatic drive_idle();
    ram_vif.iCs    <= 1'b0;
    ram_vif.iWea   <= 1'b0;
    ram_vif.iAddr  <= '0;
    ram_vif.iWData <= '0;
  endtask

  task automatic drive_item(ram_seq_item item);
    @(ram_vif.drv_cb);
    ram_vif.drv_cb.iCs    <= item.iCs;
    ram_vif.drv_cb.iWea   <= item.iWea;
    ram_vif.drv_cb.iAddr  <= item.iAddr;
    ram_vif.drv_cb.iWData <= item.iWData;

    @(ram_vif.drv_cb);
    drive_idle();
  endtask

  task run_phase(uvm_phase phase);
    ram_seq_item item;

    drive_idle();
    wait (ram_vif.iRstn === 1'b1);

    forever begin
      seq_item_port.get_next_item(item);

      if (ram_vif.iRstn !== 1'b1) begin
        drive_idle();
        wait (ram_vif.iRstn === 1'b1);
      end

      drive_item(item);
      seq_item_port.item_done();
    end
  endtask

endclass

`endif
