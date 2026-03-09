/*******************************************************************
  - Project          : 2025 winter internship
  - File name        : ApbSlave.v
  - Description      : Simple APB Slave with individual register enables (Write & Read)
  - Owner            : SangWook.Woo
  - Revision history : 2025-01-07 initial release
                     : 2025-01-07 make enable signal for each register 
*******************************************************************/

`timescale 1ns/10ps

module ApbSlave (
  input             iClk,
  input             iRsn,

  input             iPSEL,
  input             iPENABLE,
  input             iPWRITE,
  input      [15:0] iPADDR,
  input      [31:0] iPWDATA,
  output reg [31:0] oPRDATA,
  output            oPREADY
);

  // Registers
  reg [31:0] rA, rB, rC, rD;

  // Control Signals
  wire wWrEn;
  wire wRdEn;

  // Individual Register Write Enables
  wire wWrEnA, wWrEnB, wWrEnC, wWrEnD;

  // Individual Register Read Enables
  wire wRdEnA, wRdEnB, wRdEnC, wRdEnD;

  // APB Ready (0-wait for now)
  assign oPREADY = iPENABLE;//always ready 

  // Global Write/Read Enable
  assign wWrEn = (iPSEL && iPENABLE && iPWRITE);
  assign wRdEn = (iPSEL && !iPWRITE); 

  // Individual Write Enables
  assign wWrEnA = wWrEn && (iPADDR[3:0] == 4'h0);
  assign wWrEnB = wWrEn && (iPADDR[3:0] == 4'h4);
  assign wWrEnC = wWrEn && (iPADDR[3:0] == 4'h8);
  assign wWrEnD = wWrEn && (iPADDR[3:0] == 4'hC);

  // Individual Read Enables
  assign wRdEnA = wRdEn && (iPADDR[3:0] == 4'h0);
  assign wRdEnB = wRdEn && (iPADDR[3:0] == 4'h4);
  assign wRdEnC = wRdEn && (iPADDR[3:0] == 4'h8);
  assign wRdEnD = wRdEn && (iPADDR[3:0] == 4'hC);  

 
  // Register Write Logic
  always @(posedge iClk) begin
    if (!iRsn) begin
      rA <= 32'h0;
      rB <= 32'h0;
      rC <= 32'h0;
      rD <= 32'h0;
    end else begin
      if (wWrEnA) rA <= iPWDATA[31:0];
      if (wWrEnB) rB <= iPWDATA[31:0];
      if (wWrEnC) rC <= iPWDATA[31:0];
      if (wWrEnD) rD <= iPWDATA[31:0];
    end
  end

  // Read Logic (Mux with individual enables)
  always @(*) begin
    if      (wRdEnA)      oPRDATA = rA[31:0];
    else if (wRdEnB)      oPRDATA = rB[31:0];
    else if (wRdEnC)      oPRDATA = rC[31:0];
    else if (wRdEnD)      oPRDATA = rD[31:0];
    else                  oPRDATA = 32'h0;
  end

endmodule
