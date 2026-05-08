typedef enum bit {LOOP_SPI, LOOP_I2C} loop_protocol_e;

class loopback_seq_item extends uvm_sequence_item;
  rand loop_protocol_e protocol;
  rand bit             read_en;
  rand bit [1:0]       spi_mode;
  rand bit [1:0]       reg_sel;
  rand bit [7:0]       tx_data;
  bit                  compare_en;
  bit                  inject_reset;
  int unsigned         reset_delay_cycles;

  bit [15:0] exp_digits;
  bit [7:0]  exp_rx_data;
  bit        exp_ack_error;

  bit [15:0] obs_digits;
  bit [7:0]  obs_rx_data;
  bit        obs_ack_error;

  `uvm_object_utils_begin(loopback_seq_item)
    `uvm_field_enum(loop_protocol_e, protocol, UVM_ALL_ON)
    `uvm_field_int(read_en, UVM_ALL_ON)
    `uvm_field_int(spi_mode, UVM_ALL_ON)
    `uvm_field_int(reg_sel, UVM_ALL_ON)
    `uvm_field_int(tx_data, UVM_ALL_ON)
    `uvm_field_int(compare_en, UVM_ALL_ON)
    `uvm_field_int(inject_reset, UVM_ALL_ON)
    `uvm_field_int(reset_delay_cycles, UVM_ALL_ON)
    `uvm_field_int(exp_digits, UVM_ALL_ON)
    `uvm_field_int(exp_rx_data, UVM_ALL_ON)
    `uvm_field_int(exp_ack_error, UVM_ALL_ON)
    `uvm_field_int(obs_digits, UVM_ALL_ON)
    `uvm_field_int(obs_rx_data, UVM_ALL_ON)
    `uvm_field_int(obs_ack_error, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "loopback_seq_item");
    super.new(name);
  endfunction

  function string protocol_name();
    return (protocol == LOOP_I2C) ? "I2C" : "SPI";
  endfunction

  function string convert2string();
    return $sformatf(
        "protocol=%s read=%0b spi_mode=%0d reg=%0d tx=0x%02h compare=%0b inject_reset=%0b reset_delay=%0d exp_digits=0x%04h exp_rx=0x%02h exp_ack=%0b obs_digits=0x%04h obs_rx=0x%02h obs_ack=%0b",
        protocol_name(), read_en, spi_mode, reg_sel, tx_data, compare_en, inject_reset,
        reset_delay_cycles, exp_digits, exp_rx_data, exp_ack_error, obs_digits, obs_rx_data,
        obs_ack_error);
  endfunction
endclass

