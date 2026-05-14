`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: WritebackStage
Role: RV32I pipeline write-back stage
Summary:
  - Converts the MEM/WB packet into register-file write controls
  - Suppresses architectural commit while the bus wait hold is active
StateDescription:
  - Combinational only
[MODULE_INFO_END]
*/
module WritebackStage (
  input  rv32i_pkg::mem_wb_packet_t iMemWbPacket,
  input  logic                      iBusWaitStall,
  output logic                      oRegWriteEn,
  output logic [4:0]                oRdAddr,
  output logic [31:0]               oRdWrData,
  output logic                      oRetireValid
);

  assign oRegWriteEn = iMemWbPacket.valid && iMemWbPacket.reg_write && !iBusWaitStall;
  assign oRdAddr     = iMemWbPacket.rd_addr;
  assign oRdWrData   = iMemWbPacket.wr_data;
  assign oRetireValid = iMemWbPacket.valid && !iBusWaitStall;

endmodule
