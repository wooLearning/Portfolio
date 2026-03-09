/*******************************************************************
  - Project          : 2025 winter internship
  - File name        : Axi2Apb.v
  - Description      : AXI to APB Bridge (Single Burst, Synchronous)
  - Owner            : SangWook.Woo
  - Revision history : 1) 2026.01.07 : Initial release
                       2) 2026.01.07 : wrong address state process fail
                       3) 2026.01.08 : Add new fsm state (error state)
                       4) 2026.01.08 : stimultanous read write  add
                       5) 2026.01.08 : burst
                       6) 2026.01.09 : apb multiple slave bridge start 
*******************************************************************/

`timescale 1ns/10ps

module Axi2Apb (
  // Clock & reset
  input                 iClk,
  input                 iRsn,

  // AXI Slave Interface
  // AW Channel
  input  [31:0]         iS_AwAddr,
  input  [1:0]          iS_AwLen,
  input                 iS_AwValid,
  output                oS_AwReady,

  // W Channel
  input  [31:0]         iS_WData,
  input                 iS_WLast,
  input                 iS_WValid,
  output                oS_WReady,

  // B Channel
  output [1:0]          oS_BResp,
  output                oS_BValid,
  input                 iS_BReady,

  // AR Channel
  input  [31:0]         iS_ArAddr,
  input  [1:0]          iS_ArLen,
  input                 iS_ArValid,
  output                oS_ArReady,

  // R Channel
  output [31:0]         oS_RData,
  output [1:0]          oS_RResp,
  output                oS_RLast,
  output                oS_RValid,
  input                 iS_RReady,

  // APB Master Interface
  output [3:0]          oPSEL,
  output                oPENABLE,
  output                oPWRITE,
  output [15:0]         oPADDR,
  output [31:0]         oPWDATA,
  input  [31:0]         iPRDATA,
  input                 iPREADY
  
);

  //----------------------------------------------------------------
  // Write FSM States
  //----------------------------------------------------------------
  localparam xW_Idle    = 3'd0;
  localparam xW_AwReady = 3'd1;
  localparam xW_WValid  = 3'd2;
  localparam xW_Setup   = 3'd3;
  localparam xW_Enable  = 3'd4;
  localparam xW_Error   = 3'd5;
  localparam xW_BValid  = 3'd6;

  reg [2:0] rWrCurState, rWrNextState;

  //----------------------------------------------------------------
  // Read FSM States
  //----------------------------------------------------------------
  localparam xR_Idle    = 3'd0;
  localparam xR_ArReady = 3'd1;
  localparam xR_Setup   = 3'd2;
  localparam xR_Enable  = 3'd3;
  localparam xR_RValid  = 3'd4;

  reg [2:0] rRdCurState, rRdNextState;

  // Internal Registers for buffering AXI signals
  reg [31:0] rAwAddr;
  reg [31:0] rWData;
  reg [1:0]  rAwLen;
  reg [1:0]  rAwLenCnt;

  reg [31:0] rArAddr;
  reg [31:0] rRData;
  reg [1:0]  rArLen;
  reg [1:0]  rArLenCnt;

  // Internal Wire for Apb slave Select
  wire [3:0] wSelIdx;
  //----------------------------------------------------------------
  // Write FSM
  //----------------------------------------------------------------
  always @(posedge iClk) begin
    if (!iRsn) rWrCurState <= xW_Idle;
    else       rWrCurState <= rWrNextState;
  end

  always @(*) begin
    case (rWrCurState)
      xW_Idle    : begin
        if (iS_AwValid && rRdCurState == xW_Idle) rWrNextState = xW_AwReady;
        else                                      rWrNextState = xW_Idle;
      end
      xW_AwReady : begin
        rWrNextState = xW_WValid;
      end
      xW_WValid  : begin
        if (iS_WValid && (rAwAddr[31:20] == 12'h700)) rWrNextState = xW_Setup;
        else if (iS_WValid == 1'b1)                    rWrNextState = xW_Error;
        else                                           rWrNextState = xW_WValid;
      end
      xW_Setup   : begin
        rWrNextState = xW_Enable;
      end
      xW_Enable  : begin
        if (iPREADY) begin
          if (rAwLenCnt < rAwLen) rWrNextState = xW_WValid;
          else                    rWrNextState = xW_BValid;
        end else begin
          rWrNextState = xW_Enable;
        end
      end
      xW_Error   : begin
        if (rAwLenCnt < rAwLen) rWrNextState = xW_WValid;
        else                 rWrNextState = xW_BValid;
      end
      xW_BValid  : begin
        if (iS_BReady) rWrNextState = xW_Idle;
        else           rWrNextState = xW_BValid;
      end
      default    :     rWrNextState = xW_Idle;
    endcase
  end

  // Buffer AXI Write Signals
  always @(posedge iClk) begin
    if (!iRsn) begin
      rAwAddr   <= 32'h0;
      rWData    <= 32'h0;
      rAwLen    <= 2'b0;
      rAwLenCnt <= 2'b0;
    end 
    else begin
      if (rWrCurState == xW_Idle && iS_AwValid) begin // AW stage
        rAwAddr <= iS_AwAddr;
        rAwLen  <= iS_AwLen;
        rAwLenCnt  <= 2'b0;
      end

      // W stage
      if (rWrCurState == xW_WValid && iS_WValid) begin 
        rWData  <= iS_WData;
      end
      
      // Incr Address and Cnt for burst action
      if (rWrCurState == xW_Enable && iPREADY) begin
          if (rAwLenCnt < rAwLen) begin
            rAwLenCnt  <= rAwLenCnt + 1;
            rAwAddr <= rAwAddr + 4;
          end
      end

      // Error case increment (consume burst)
      if (rWrCurState == xW_Error) begin
          if (rAwLenCnt < rAwLen) begin
             rAwLenCnt  <= rAwLenCnt + 1;
          end
      end
    end
  end

  assign oS_AwReady = (rWrCurState == xW_AwReady);
  assign oS_WReady  = (rWrCurState == xW_Enable) || (rWrCurState == xW_Error);
  assign oS_BValid  = (rWrCurState == xW_BValid);
  assign oS_BResp   = (rWrNextState != xW_BValid) ? 2'b11:
                      (rAwAddr[31:20] == 12'h700) ? 2'b00 : 2'b01; // OKAY(00), ERROR(01), DontCare(11)

  //----------------------------------------------------------------
  // Read FSM
  //----------------------------------------------------------------
  always @(posedge iClk) begin
    if (!iRsn) rRdCurState <= xR_Idle;
    else       rRdCurState <= rRdNextState;
  end

  always @(*) begin
    case (rRdCurState)
      xR_Idle    : begin
        if (iS_ArValid && rWrCurState == xW_Idle) rRdNextState = xR_ArReady;
        else                                      rRdNextState = xR_Idle;
      end
      xR_ArReady : begin
        if (rArAddr[31:20] == 12'h700) rRdNextState = xR_Setup;
        else                            rRdNextState = xR_RValid;
      end
      xR_Setup   : begin
        rRdNextState = xR_Enable;
      end
      xR_Enable  : begin
        if (iPREADY) rRdNextState = xR_RValid;
        else         rRdNextState = xR_Enable;
      end
      xR_RValid  : begin
        if (iS_RReady) begin
          if (rArLenCnt < rArLen) rRdNextState = xR_Setup;
          else                    rRdNextState = xR_Idle;
        end 
        else begin
          rRdNextState = xR_RValid;
        end
      end
      default    : rRdNextState = xR_Idle;
    endcase
  end

  // Buffer AXI Read Signals
  always @(posedge iClk) begin
    if (!iRsn) begin
      rArAddr   <= 32'h0;
      rRData    <= 32'h0;
      rArLen    <= 2'b0;
      rArLenCnt <= 2'b0;
    end
    else begin
      // AR state
      if (rRdCurState == xR_Idle && iS_ArValid) begin
        rArAddr   <= iS_ArAddr;
        rArLen    <= iS_ArLen;
        rArLenCnt <= 2'b0;
      end

      // R state
      if (rRdCurState == xR_Enable && iPREADY) begin
        rRData  <= iPRDATA;
      end
      if (rRdCurState == xR_RValid && iS_RReady) begin
         if (rArLenCnt < rArLen) begin
            rArLenCnt  <= rArLenCnt + 1;
            rArAddr <= rArAddr + 4;
         end
      end
    end
  end

  assign oS_ArReady = (rRdCurState == xR_ArReady);
  assign oS_RValid  = (rRdCurState == xR_RValid);
  assign oS_RData   = rRData;
  assign oS_RResp   = (rRdCurState != xR_RValid) ? 2'b11 :
                      (rArAddr[31:20] == 12'h700) ? 2'b00 : 2'b01; // OKAY(00), ERROR(01), DontCare(11)
  assign oS_RLast   = (rRdCurState == xR_RValid) && (rArLenCnt == rArLen); // Last beat coincides with Valid in Single Burst

  //----------------------------------------------------------------
  // APB Master Output Logic
  //----------------------------------------------------------------
  // APB is shared between Read and Write. Write has priority if both somehow active, 
  // but AXI masters should manage address phases.

  assign wSelIdx = (rWrCurState == xW_Setup || rWrCurState == xW_Enable) ? rAwAddr[19:16] : rArAddr[19:16];

  assign oPSEL    = (rWrCurState == xW_Setup || rWrCurState == xW_Enable ||
                     rRdCurState == xR_Setup || rRdCurState == xR_Enable) ? (4'd1 << wSelIdx) : 4'd0;
  assign oPENABLE = (rWrCurState == xW_Enable || rRdCurState == xR_Enable);
  assign oPWRITE  = (rWrCurState == xW_Setup || rWrCurState == xW_Enable);
  assign oPADDR   = (oPWRITE) ? rAwAddr[15:0] : rArAddr[15:0];
  assign oPWDATA  = rWData;

endmodule
