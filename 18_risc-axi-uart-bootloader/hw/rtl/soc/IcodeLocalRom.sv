`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: IcodeLocalRom
Role: Local instruction ROM fast path for the RISC-V core IBus
Summary:
  - Loads a hex instruction image with readmemh
  - Keeps instruction fetch out of the slower AXI-Lite transaction FSM
  - Uses a one-word sequential prefetch so straight-line code can run with low wait
StateDescription:
  - rData holds the last requested instruction
  - rPrefetchData holds the next sequential instruction after a hit
[MODULE_INFO_END]
*/
module IcodeLocalRom #(
  parameter integer P_ADDR_WIDTH = 12,
  parameter string  P_MEM_FILE = "src/timing_programs/link_demo.mem",
  parameter bit     P_SYNC_READ = 1'b1
) (
  input  logic        iClk,
  input  logic        iRstn,
  input  logic        iLocalValid,
  input  logic [31:0] iLocalAddr,
  output logic        oLocalReady,
  output logic [31:0] oLocalRData,
  output logic        oLocalError,
  output logic [31:0] oDbgHitCount,
  output logic [31:0] oDbgMissCount,
  output logic [31:0] oDbgBurstCount
);

  localparam integer LP_DEPTH = (1 << P_ADDR_WIDTH);
  localparam logic [31:0] LP_NOP = 32'h0000_0013;

  (* ram_style = "block" *) logic [31:0] rMem [0:LP_DEPTH-1];
  logic [P_ADDR_WIDTH-1:0] wWordAddr;
  logic [P_ADDR_WIDTH-1:0] wNextWordAddr;
  logic                    wAddrInRange;
  logic                    wNextAddrInRange;
  logic [31:0]             wNextAddr;
  integer                  idx;

  assign wWordAddr        = iLocalAddr[P_ADDR_WIDTH+1:2];
  assign wNextAddr        = iLocalAddr + 32'd4;
  assign wNextWordAddr    = wNextAddr[P_ADDR_WIDTH+1:2];
  assign wAddrInRange     = (iLocalAddr[31:P_ADDR_WIDTH+2] == '0);
  assign wNextAddrInRange = (wNextAddr[31:P_ADDR_WIDTH+2] == '0);
  assign oLocalError      = 1'b0;
  assign oDbgMissCount    = 32'd0;
  assign oDbgBurstCount   = 32'd0;

  initial begin
    for (idx = 0; idx < LP_DEPTH; idx = idx + 1) begin
      rMem[idx] = LP_NOP;
    end

    $readmemh(P_MEM_FILE, rMem);
  end

  generate
    if (P_SYNC_READ) begin : g_sync_read
      logic [31:0] rAddr;
      logic [31:0] rData;
      logic        rDataValid;
      logic [31:0] rPrefAddr;
      logic [31:0] rPrefetchData;
      logic        rPrefetchValid;
      logic        wDataHit;
      logic        wPrefetchHit;

      assign wDataHit     = rDataValid && (rAddr == iLocalAddr);
      assign wPrefetchHit = rPrefetchValid && (rPrefAddr == iLocalAddr);
      assign oLocalReady  = iLocalValid && (wDataHit || wPrefetchHit);
      assign oLocalRData  = wPrefetchHit ? rPrefetchData : rData;

      always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
          rAddr          <= 32'd0;
          rData          <= LP_NOP;
          rDataValid     <= 1'b0;
          rPrefAddr       <= 32'd0;
          rPrefetchData  <= LP_NOP;
          rPrefetchValid <= 1'b0;
          oDbgHitCount   <= 32'd0;
        end
        else if (iLocalValid) begin
          if (wDataHit || wPrefetchHit) begin
            oDbgHitCount   <= oDbgHitCount + 32'd1;
            rAddr          <= iLocalAddr;
            rData          <= wPrefetchHit ? rPrefetchData : rData;
            rDataValid     <= 1'b1;
            rPrefAddr       <= wNextAddr;
            rPrefetchData  <= wNextAddrInRange ? rMem[wNextWordAddr] : LP_NOP;
            rPrefetchValid <= 1'b1;
          end
          else begin
            rAddr          <= iLocalAddr;
            rData          <= wAddrInRange ? rMem[wWordAddr] : LP_NOP;
            rDataValid     <= 1'b1;
            rPrefetchValid <= 1'b0;
          end
        end
      end
    end
    else begin : g_async_read
      assign oLocalReady = iLocalValid;
      assign oLocalRData = wAddrInRange ? rMem[wWordAddr] : LP_NOP;

      always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
          oDbgHitCount <= 32'd0;
        end
        else if (iLocalValid) begin
          oDbgHitCount <= oDbgHitCount + 32'd1;
        end
      end
    end
  endgenerate

endmodule
