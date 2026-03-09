/*******************************************************************
  - Project          : 2025 winter internship
  - File name        : Prj_Axi_Top.v
  - Description      : Top module connecting AXI2APB Bridge and APB Slave
  - Owner            : SangWook.Woo
  - revision history : 1) 2026-01-07 : basic Axi2Bridege design top module wiring
                       2) 2026-01-09 : multiple slave wiring
                       3) 2026-01-11 : address range modify and AES block adding
*******************************************************************/

`timescale 1ns/10ps

module Prj_Axi_Top (
  input                 iClk,
  input                 iRsn,

  //--------------------
  // AXI Slave Interface
  //--------------------

  //AW Channel
  input                 iS_AwValid,
  input  [1:0]          iS_AwLen,
  input  [31:0]         iS_AwAddr,
  output                oS_AwReady,

  //W Channel
  input                 iS_WValid,
  input                 iS_WLast,
  input  [31:0]         iS_WData,
  output                oS_WReady,

  //B Channel
  output                oS_BValid,
  output [1:0]          oS_BResp,
  input                 iS_BReady,

  //AR Channel
  input                 iS_ArValid,
  input  [1:0]          iS_ArLen,
  input  [31:0]         iS_ArAddr,
  output                oS_ArReady,

  //R Channel 
  output                oS_RValid,
  output                oS_RLast,
  output [31:0]         oS_RData,
  output [1:0]          oS_RResp,
  input                 iS_RReady,
 
  //APB interrupt output
  output                oInt

);

  // Internal APB Signals
  wire [3:0]  wPSEL;
  wire        wPENABLE;
  wire        wPWRITE;
  wire [15:0] wPADDR;
  wire [31:0] wPWDATA;
  wire [31:0] wPRDATA;
  wire        wPREADY;

  // Slave Outputs
  wire [31:0] wPRDATA0, wPRDATA1, wPRDATA2, wPRDATA3;
  wire        wPREADY0, wPREADY1, wPREADY2, wPREADY3;

  // Mux 
  assign wPRDATA = (wPSEL[0]) ? wPRDATA0 :
                   (wPSEL[1]) ? wPRDATA1 :
                   (wPSEL[2]) ? wPRDATA2 :
                   (wPSEL[3]) ? wPRDATA3 : 32'h0;

  assign wPREADY = (wPSEL[0]) ? wPREADY0 :
                   (wPSEL[1]) ? wPREADY1 :
                   (wPSEL[2]) ? wPREADY2 :
                   (wPSEL[3]) ? wPREADY3 : 1'b0; // Default Ready

  // AXI to APB Bridge Instantiation
  Axi2Apb u_Axi2Apb (
    .iClk       (iClk),
    .iRsn       (iRsn),


    .iS_AwAddr  (iS_AwAddr),
    .iS_AwLen   (iS_AwLen),
    .iS_AwValid (iS_AwValid),
    .oS_AwReady (oS_AwReady),

    .iS_WData   (iS_WData),
    .iS_WLast   (iS_WLast),
    .iS_WValid  (iS_WValid),
    .oS_WReady  (oS_WReady),

    .oS_BResp   (oS_BResp),
    .oS_BValid  (oS_BValid),
    .iS_BReady  (iS_BReady),

    .iS_ArAddr  (iS_ArAddr),
    .iS_ArLen   (iS_ArLen),
    .iS_ArValid (iS_ArValid),
    .oS_ArReady (oS_ArReady),

    .oS_RData   (oS_RData),
    .oS_RResp   (oS_RResp),
    .oS_RLast   (oS_RLast),
    .oS_RValid  (oS_RValid),
    .iS_RReady  (iS_RReady),

    // APB Master Interface 
    .oPSEL      (wPSEL),
    .oPENABLE   (wPENABLE),
    .oPWRITE    (wPWRITE),
    .oPADDR     (wPADDR),
    .oPWDATA    (wPWDATA),
    .iPRDATA    (wPRDATA),
    .iPREADY    (wPREADY)
  );

  // APB Slave 0 (0x7000_0000 - 0x7000_FFFF)
  ApbSlave u_ApbSlave0 (
    .iClk     (iClk),
    .iRsn     (iRsn),
    .iPSEL    (wPSEL[0]),
    .iPENABLE (wPENABLE),
    .iPWRITE  (wPWRITE),
    .iPADDR   (wPADDR),
    .iPWDATA  (wPWDATA),
    .oPRDATA  (wPRDATA0),
    .oPREADY  (wPREADY0)
  );

  // APB Slave 1 (0x7001_0000 - 0x7001_FFFF)
  ApbSlave u_ApbSlave1 (
    .iClk     (iClk),
    .iRsn     (iRsn),
    .iPSEL    (wPSEL[1]),
    .iPENABLE (wPENABLE),
    .iPWRITE  (wPWRITE),
    .iPADDR   (wPADDR),
    .iPWDATA  (wPWDATA),
    .oPRDATA  (wPRDATA1),
    .oPREADY  (wPREADY1)
  );

  // APB Slave 2 (0x7002_0000 - 0x7002_FFFF)
  ApbSlave u_ApbSlave2 (
    .iClk     (iClk),
    .iRsn     (iRsn),
    .iPSEL    (wPSEL[2]),
    .iPENABLE (wPENABLE),
    .iPWRITE  (wPWRITE),
    .iPADDR   (wPADDR),
    .iPWDATA  (wPWDATA),
    .oPRDATA  (wPRDATA2),
    .oPREADY  (wPREADY2)
  );
 
  //APB SLAVE 3 AES BLOCK(0x7003_0000 ~ -x7003_FFFF)
  
  Cp_Top u_Cp_Top( //not yet
    .iClk     (iClk),
    .iRsn     (iRsn),

    // APB interface
    .iPsel    (wPSEL[3]),
    .iPenable (wPENABLE),
    .iPwrite  (wPWRITE),
    .iPaddr   (wPADDR),
    .iPwdata  (wPWDATA),

    .oPrdata  (wPRDATA3),
    .oPREADY  (wPREADY3),

    .oInt(oInt)
);


 
  /*
  // APB Slave 3 (0x7000_3000 - 0x7000_3FFF)
  ApbSlave u_ApbSlave3 (
    .iClk     (iClk),
    .iRsn     (iRsn),
    .iPSEL    (wPSEL[3]),
    .iPENABLE (wPENABLE),
    .iPWRITE  (wPWRITE),
    .iPADDR   (wPADDR),
    .iPWDATA  (wPWDATA),
    .oPRDATA  (wPRDATA3),
    .oPREADY  (wPREADY3)
  );
*/
endmodule
