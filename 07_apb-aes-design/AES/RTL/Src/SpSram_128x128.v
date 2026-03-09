/*******************************************************************
  - Project          : 2024 winter internship
  - File name        : SpSram_128x128.v
  - Description      : 128x128 Single Port SRAM modeling
  - Owner            : Inchul.song
  - Revision history : 1) 2025.01.07 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module SpSram_128x128 (//referemce

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // SP-SRAM Input & Output
  input            iCsn,               // Chip selected @ Low
  input            iWrn,               // 0:Write, 1:Read
  input  [3:0]     iWdSel,             // 0001/0010/0100/1000: 1st/2nd/3rd/4th @ Low
  input  [6:0]     iAddr,              // 128bit data address

  input  [127:0]   iWrDt,              // Write data
  output [127:0]   oRdDt               // Read data

  );



  // Parameter declaration
 


  // Integer declaration
  integer          i;



  // wire & reg declaration
  reg  [31:0]     rMem1st[0:127];      // 128*32 array
  reg  [31:0]     rMem2nd[0:127];      // 128*32 array
  reg  [31:0]     rMem3rd[0:127];      // 128*32 array
  reg  [31:0]     rMem4th[0:127];      // 128*32 array

  reg  [127:0]     rRdDt;



  /*************************************************************/
  // SP-SRAM write function
  /*************************************************************/
  // rMem1st[31:0] write operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      for (i=0 ; i<128 ; i=i+1)
      begin
        rMem1st[i] <= 32'h0;
      end
    end

    // Write condition
    else if (iCsn == 1'b0 && iWrn == 1'b0 && iWdSel[0] == 1'b0)
    begin
      rMem1st[iAddr] <= iWrDt[31:0];
    end

  end


  // rMem2nd[31:0] write operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      for (i=0 ; i<128 ; i=i+1)
      begin
        rMem2nd[i] <= 32'h0;
      end
    end

    // Write condition
    else if (iCsn == 1'b0 && iWrn == 1'b0 && iWdSel[1] == 1'b0)
    begin
      rMem2nd[iAddr] <= iWrDt[63:32];
    end

  end


  // rMem3rd[31:0] write operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      for (i=0 ; i<128 ; i=i+1)
      begin
        rMem3rd[i] <= 32'h0;
      end
    end

    // Write condition
    else if (iCsn == 1'b0 && iWrn == 1'b0 && iWdSel[2] == 1'b0)
    begin
      rMem3rd[iAddr] <= iWrDt[95:64];
    end

  end


  // rMem4th[31:0] write operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      for (i=0 ; i<128 ; i=i+1)
      begin
        rMem4th[i] <= 32'h0;
      end
    end

    // Write condition
    else if (iCsn == 1'b0 && iWrn == 1'b0 && iWdSel[3] == 1'b0)
    begin
      rMem4th[iAddr] <= iWrDt[127:96];
    end

  end


  /*************************************************************/
  // SP-SRAM read function
  /*************************************************************/
  // rMem read operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rRdDt <= 128'h0;
    end

    // Read codition
    else if (iCsn == 1'b0 && iWrn == 1'b1)
    begin
      rRdDt <= {rMem4th[iAddr], rMem3rd[iAddr], rMem2nd[iAddr], rMem1st[iAddr]};
    end

  end



  // Output mapping
  assign oRdDt = rRdDt[127:0];


endmodule
