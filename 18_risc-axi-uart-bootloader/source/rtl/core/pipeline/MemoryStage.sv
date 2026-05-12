`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: MemoryStage
Role: RV32I pipeline memory stage with external data bus request
Summary:
  - Converts EX/MEM load/store controls into the core-local DBus signals
  - Formats byte and half-word load data for write-back
  - Packages memory-stage results for the MEM/WB pipeline register
StateDescription:
  - Combinational only: memory state lives behind the external DBus
[MODULE_INFO_END]
*/
module MemoryStage (
  input  rv32i_pkg::ex_mem_packet_t iExMemPacket,
  input  logic                      iDBusReady,
  input  logic [31:0]               iDBusRData,
  input  logic                      iDBusError,
  output logic                      oDBusValid,
  output logic                      oDBusWrite,
  output logic [31:0]               oDBusAddr,
  output logic [1:0]                oDBusSize,
  output logic [31:0]               oDBusWData,
  output logic                      oDataWaitStall,
  output logic                      oMemTrapEn,
  output rv32i_pkg::exc_cause_e     oMemTrapCause,
  output logic [31:0]               oMemTrapTval,
  output logic [31:0]               oMemTrapPc,
  output rv32i_pkg::mem_wb_packet_t oMemWbPacket
);

  logic        wMemAccessValid;
  logic [31:0] wLoadData;
  logic [31:0] wStageWbData;

  assign wMemAccessValid =
    iExMemPacket.valid &&
    ((iExMemPacket.load_type != rv32i_pkg::LOAD_NONE) || iExMemPacket.mem_write);

  assign oDBusValid     = wMemAccessValid;
  assign oDBusWrite     = iExMemPacket.mem_write;
  assign oDBusAddr      = iExMemPacket.alu_result;
  assign oDBusWData     = iExMemPacket.store_data;
  assign oDataWaitStall = wMemAccessValid && !iDBusReady;
  assign oMemTrapEn     = wMemAccessValid && iDBusReady && iDBusError;
  assign oMemTrapCause  = iExMemPacket.mem_write ?
                           rv32i_pkg::EXC_STORE_ACCESS_FAULT :
                           rv32i_pkg::EXC_LOAD_ACCESS_FAULT;
  assign oMemTrapTval   = iExMemPacket.alu_result;
  assign oMemTrapPc     = iExMemPacket.pc;

  always_comb begin
    oDBusSize = 2'b10;

    unique case (iExMemPacket.store_type)
      rv32i_pkg::STORE_SB: oDBusSize = 2'b00;
      rv32i_pkg::STORE_SH: oDBusSize = 2'b01;
      rv32i_pkg::STORE_SW: oDBusSize = 2'b10;
      default: begin
        unique case (iExMemPacket.load_type)
          rv32i_pkg::LOAD_LB,
          rv32i_pkg::LOAD_LBU: oDBusSize = 2'b00;
          rv32i_pkg::LOAD_LH,
          rv32i_pkg::LOAD_LHU: oDBusSize = 2'b01;
          default:             oDBusSize = 2'b10;
        endcase
      end
    endcase
  end

  always_comb begin
    wLoadData = iDBusRData;

    unique case (iExMemPacket.load_type)
      rv32i_pkg::LOAD_LB:  wLoadData = {{24{iDBusRData[7]}}, iDBusRData[7:0]};
      rv32i_pkg::LOAD_LH:  wLoadData = {{16{iDBusRData[15]}}, iDBusRData[15:0]};
      rv32i_pkg::LOAD_LW:  wLoadData = iDBusRData;
      rv32i_pkg::LOAD_LBU: wLoadData = {24'd0, iDBusRData[7:0]};
      rv32i_pkg::LOAD_LHU: wLoadData = {16'd0, iDBusRData[15:0]};
      default:             wLoadData = iDBusRData;
    endcase
  end

  assign wStageWbData =
    (iExMemPacket.wb_sel == rv32i_pkg::WB_MEM) ? wLoadData : iExMemPacket.wb_data_non_mem;

  always_comb begin
    oMemWbPacket.valid      = iExMemPacket.valid && !oMemTrapEn;
    oMemWbPacket.illegal    = iExMemPacket.illegal;
    oMemWbPacket.reg_write  = iExMemPacket.reg_write;
    oMemWbPacket.forward_en = iExMemPacket.reg_write && (iExMemPacket.rd_addr != 5'd0);
    oMemWbPacket.rd_addr    = iExMemPacket.rd_addr;
    oMemWbPacket.wr_data    = wStageWbData;
  end

endmodule
