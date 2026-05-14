`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: FetchStage
Role: RV32I pipeline fetch stage with external instruction bus request
Summary:
  - Owns the PC register through the existing Pc helper
  - Presents the current PC on the core-local instruction bus
  - Packages fetched instruction data for the IF/ID pipeline register
StateDescription:
  - PC state is stored in Pc
[MODULE_INFO_END]
*/
module FetchStage #(
  parameter bit     P_ENABLE_BTB = 1'b1,
  parameter integer P_BTB_ENTRIES = 16
) (
  input  logic                   iClk,
  input  logic                   iRstn,
  input  logic                   iPcWriteEn,
  input  logic                   iPcTargetEn,
  input  logic [31:0]            iPcTarget,
  input  logic                   iBtbUpdateValid,
  input  logic                   iBtbUpdateTaken,
  input  logic [31:0]            iBtbUpdatePc,
  input  logic [31:0]            iBtbUpdateTarget,
  input  logic                   iIBusReady,
  input  logic [31:0]            iIBusRData,
  input  logic                   iIBusError,
  output logic                   oIBusValid,
  output logic [31:0]            oIBusAddr,
  output logic                   oFetchWaitStall,
  output rv32i_pkg::if_id_packet_t oFetchPacket,
  output logic [31:0]            oDbgPc
);

  localparam integer LP_BTB_INDEX_WIDTH = (P_BTB_ENTRIES <= 2) ? 1 : $clog2(P_BTB_ENTRIES);
  localparam integer LP_BTB_TAG_LSB = LP_BTB_INDEX_WIDTH + 2;

  logic [31:0] wPc;
  logic [31:0] wPcPlus4;
  logic        wBtbHit;
  logic [31:0] wBtbTarget;
  logic        wPcTargetEn;
  logic [31:0] wPcTarget;
  logic [LP_BTB_INDEX_WIDTH-1:0] wLookupIndex;
  logic [LP_BTB_INDEX_WIDTH-1:0] wUpdateIndex;
  logic [31:LP_BTB_TAG_LSB] rBtbTag [0:P_BTB_ENTRIES-1];
  logic [31:0] rBtbTarget [0:P_BTB_ENTRIES-1];
  logic        rBtbValid [0:P_BTB_ENTRIES-1];
  logic        rBtbTaken [0:P_BTB_ENTRIES-1];
  integer idx;

  assign wLookupIndex = wPc[LP_BTB_INDEX_WIDTH+1:2];
  assign wUpdateIndex = iBtbUpdatePc[LP_BTB_INDEX_WIDTH+1:2];

  assign wBtbHit =
    P_ENABLE_BTB &&
    rBtbValid[wLookupIndex] &&
    rBtbTaken[wLookupIndex] &&
    (rBtbTag[wLookupIndex] == wPc[31:LP_BTB_TAG_LSB]);

  assign wBtbTarget = rBtbTarget[wLookupIndex];
  assign wPcTargetEn = iPcTargetEn || wBtbHit;
  assign wPcTarget = iPcTargetEn ? iPcTarget : wBtbTarget;

  Pc uPc (
    .iClk        (iClk),
    .iRstn       (iRstn),
    .iPcWe       (iPcWriteEn),
    .iPcTargetEn (wPcTargetEn),
    .iPcTarget   (wPcTarget),
    .oPc         (wPc),
    .oPcPlus4    (wPcPlus4)
  );

  assign oIBusValid      = 1'b1;
  assign oIBusAddr       = wPc;
  assign oFetchWaitStall = !iIBusReady;
  assign oDbgPc          = wPc;

  always_comb begin
    oFetchPacket.valid    = 1'b1;
    oFetchPacket.instr_error = iIBusError;
    oFetchPacket.predicted_taken = wBtbHit;
    oFetchPacket.pc       = wPc;
    oFetchPacket.pc_plus4 = wPcPlus4;
    oFetchPacket.predicted_target = wBtbTarget;
    oFetchPacket.instr    = iIBusRData;
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      for (idx = 0; idx < P_BTB_ENTRIES; idx = idx + 1) begin
        rBtbValid[idx]  <= 1'b0;
        rBtbTaken[idx]  <= 1'b0;
        rBtbTag[idx]    <= '0;
        rBtbTarget[idx] <= 32'd0;
      end
    end
    else if (P_ENABLE_BTB && iBtbUpdateValid) begin
      rBtbValid[wUpdateIndex]  <= 1'b1;
      rBtbTaken[wUpdateIndex]  <= iBtbUpdateTaken;
      rBtbTag[wUpdateIndex]    <= iBtbUpdatePc[31:LP_BTB_TAG_LSB];
      rBtbTarget[wUpdateIndex] <= iBtbUpdateTarget;
    end
  end

endmodule
