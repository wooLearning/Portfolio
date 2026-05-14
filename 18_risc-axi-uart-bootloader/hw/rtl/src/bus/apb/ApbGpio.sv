`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbGpio
Role: Minimal APB wrapper for the simple GPIO block
Summary:
  - Exposes GPIO OUT, IN, and DIR registers on APB
  - Keeps the GPIO core independent from APB protocol details
  - Uses zero-wait APB responses
StateDescription:
  - GPIO state is held in the wrapped Gpio module
[MODULE_INFO_END]
*/
module ApbGpio #(
  parameter integer P_GPIO_WIDTH = 16
) (
  input  logic                      iPclk,
  input  logic                      iPresetn,
  input  logic                      iPSEL,
  input  logic                      iPENABLE,
  input  logic                      iPWRITE,
  input  logic [11:0]               iPADDR,
  input  logic [31:0]               iPWDATA,
  input  logic [3:0]                iPSTRB,
  input  logic [P_GPIO_WIDTH-1:0]   iGpioIn,
  output logic [P_GPIO_WIDTH-1:0]   oGpioOut,
  output logic [P_GPIO_WIDTH-1:0]   oGpioDir,
  output logic [31:0]               oPRDATA,
  output logic                      oPREADY,
  output logic                      oPSLVERR
);

  localparam logic [7:0] LP_ADDR_OUT = 8'h00;
  localparam logic [7:0] LP_ADDR_IN  = 8'h04;
  localparam logic [7:0] LP_ADDR_DIR = 8'h08;

  logic                  wWrite;
  logic                  wOutWriteEn;
  logic                  wDirWriteEn;
  logic [31:0]           wWriteMask32;
  logic [P_GPIO_WIDTH-1:0] wGpioIn;

  assign wWrite      = iPSEL && iPENABLE && iPWRITE;
  assign wOutWriteEn = wWrite && (iPADDR[7:0] == LP_ADDR_OUT);
  assign wDirWriteEn = wWrite && (iPADDR[7:0] == LP_ADDR_DIR);

  assign wWriteMask32 = {
    {8{iPSTRB[3]}},
    {8{iPSTRB[2]}},
    {8{iPSTRB[1]}},
    {8{iPSTRB[0]}}
  };

  assign oPREADY  = 1'b1;
  assign oPSLVERR = 1'b0;

  Gpio #(
    .P_WIDTH(P_GPIO_WIDTH)
  ) uGpio (
    .iClk        (iPclk),
    .iRstn       (iPresetn),
    .iOutWriteEn (wOutWriteEn),
    .iDirWriteEn (wDirWriteEn),
    .iWriteData  (iPWDATA[P_GPIO_WIDTH-1:0]),
    .iWriteMask  (wWriteMask32[P_GPIO_WIDTH-1:0]),
    .iGpioIn     (iGpioIn),
    .oGpioIn     (wGpioIn),
    .oGpioOut    (oGpioOut),
    .oGpioDir    (oGpioDir)
  );

  always_comb begin
    oPRDATA = 32'd0;

    unique case (iPADDR[7:0])
      LP_ADDR_OUT: oPRDATA[P_GPIO_WIDTH-1:0] = oGpioOut;
      LP_ADDR_IN:  oPRDATA[P_GPIO_WIDTH-1:0] = wGpioIn;
      LP_ADDR_DIR: oPRDATA[P_GPIO_WIDTH-1:0] = oGpioDir;
      default:     oPRDATA = 32'd0;
    endcase
  end

endmodule
