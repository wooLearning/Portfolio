/*******************************************************************
* - Project          : 2024 winter internship
* - File name        : TbTop_Lab3_1_wRdChk_wFor.v
* - Description      : Testbench top for Lab1
* - Owner            : SangWook Woo
* - Revision history : 1) 2024.12.27 : Initial release
********************************************************************/

`timescale 1ns/10ps

module TbTop_Aes;

  /***********************************************
  // wire & register
  ***********************************************/
  reg              iClk;
  reg              iRsn;


  reg              iPsel;
  reg              iPenable;
  reg              iPwrite;
  reg  [15:0]      iPaddr;

  reg  [31:0]      iPwdata;
  wire [31:0]      oPrdata;
  wire             oInt;  


  integer          i;


  reg  [31:0] writeData[0:511];  //512*32 array
  reg  [31:0] readData[0:511]; //check endian conversion

  parameter byteSize = 4;//32bit 

  /***********************************************
  //Top.v  instantiation
  ***********************************************/
  Cp_Top Cp_Top0 (
  // Clock & reset
  .iClk            (iClk),
  .iRsn            (iRsn),


  // APB interface
  .iPsel           (iPsel),
  .iPenable        (iPenable),
  .iPwrite         (iPwrite),
  .iPaddr          (iPaddr[15:0]),

  .iPwdata         (iPwdata[31:0]),
  .oPrdata         (oPrdata[31:0]),

  .oInt      (oInt)
  );



  /***********************************************
  // Clock define
  ***********************************************/
  initial
  begin
    iClk <= 1'b0;
  end


  always
  begin
    // 100MHz clock
    #5 iClk <= ~iClk;
  end



  /***********************************************
  // Sync. & active low reset define
  ***********************************************/
  initial
  begin
    iRsn <= 1'b1;

    repeat (  5) @(posedge iClk);
    iRsn <= 1'b0;

    repeat (  2) @(posedge iClk); 
    $display("**** Reset released !!! ****");
    iRsn <= 1'b1;

  end



  /***********************************************
  // APB write task
  ***********************************************/
  task apb_write (
    input  [15:0]  addr,     // Write address
    input  [31:0]  data      // Read data
  );
  begin

    iPsel    <= 1'b1;
    iPenable <= 1'b0;
    iPwrite  <= 1'b1;
    iPaddr   <= addr[15:0];
    iPwdata  <= data[31:0];

    @(posedge iClk);
    iPenable <= 1'b1;

    @(posedge iClk);
    $display("**** Write 0x%h at addr 0x%h !!! ****", data[31:0], addr[15:0]);
    iPsel    <= 1'b0;
    iPenable <= 1'b0;

  end
  endtask


    
  /***********************************************
  // APB read task
  ***********************************************/
  task apb_read (
    input  [15:0]  addr,     // Read address
    input  [31:0]  data      // Expected data
  );
  begin

    iPsel    <= 1'b1;
    iPenable <= 1'b0;
    iPwrite  <= 1'b0;
    iPaddr   <= addr[15:0];

    @(posedge iClk);
    iPenable <= 1'b1;

/**
    @(posedge iClk);
    $display("**** Read  0x%h from addr 0x%h !!! ****", oPrdata[31:0], addr[15:0]);
**/
    @(posedge iClk);
    $display("**** Read  0x%h & expected 0x%h from addr 0x%h !!! ****", oPrdata[31:0], data[31:0], addr[15:0]);

    if (oPrdata[31:0] == data[31:0])
    begin
      $display ("     OOOO Read data Passed !!! OOOO");
    end
    else
    begin
      $display ("     XXXX Read data Failed !!! XXXX");
      $display ("     ---> Must debug this  !!! <---");
    end
      
    iPsel    <= 1'b0;
    iPenable <= 1'b0;

  end
  endtask


 /***********************/
 //Write Test///
 /******************************/
  initial
  begin

    iPsel    <=  1'h0;
    iPenable <=  1'h0;
    iPwrite  <=  1'h0;
    iPaddr   <= 16'h0;
    iPwdata  <= 32'h0;

    repeat (100) @(posedge iClk);
    
    //plain text
    apb_write (16'h4000, 32'h33_22_11_00);
    apb_write (16'h4004, 32'h77_66_55_44);
    apb_write (16'h4008, 32'hBB_AA_99_88);
    apb_write (16'h400C, 32'hFF_EE_DD_CC);

    //key input
    apb_write (16'h2000, 32'h03_02_01_00);
    apb_write (16'h2004, 32'h07_06_05_04);
    apb_write (16'h2008, 32'h0B_0A_09_08);
    apb_write (16'h200C, 32'h0F_0E_0D_0C);
 
   
   ////////////interrupt enable
    apb_write(16'hA000,1'b1);
    apb_write(16'hA008,1'b1);
    ///////////////////////

   //startCp
    repeat (50) @(posedge iClk);
    //apb_write(16'h0004,byteSize);
    apb_write(16'h0004,16);
    repeat (5) @(posedge iClk);
    apb_write(16'h0000,32'h1);

    $display("=====================================");
    $display("0000  x0004 x0000 write DtCp module Start");
    $display("======================================");
    
  end
 

  /***************************************************
  // oOutEnable Test
  ****************************************************/
  
  initial begin
    @(posedge oInt);
    //interrupt end read A004 pending clear//////////////////////
    iPsel    <= 1'b1;
    iPenable <= 1'b0;
    iPwrite  <= 1'b0;
    iPaddr   <= 16'hA004;
    @(posedge iClk);
    iPenable <= 1'b1;
    //if read data == 1'b1 peding clear
    @(posedge iClk);
    if (oPrdata[0] == 1'b1) begin
      apb_write(16'hA004,1'b1);  
    end
    iPsel    <= 1'b0;
    iPenable <= 1'b0;
    //////////////////////////////////////////

    $display("-------------------------------------------");
    $display("000000 READ START");
    $display("-------------------------------------------");
  
   //compare data
   apb_read (16'h6000, 32'hD8_E0_C4_69);
   apb_read (16'h6004, 32'h30_04_7B_6A);
   apb_read (16'h6008, 32'h80_B7_CD_D8);
   apb_read (16'h600C, 32'h5A_C5_B4_70);  
 
   repeat(10) @(posedge iClk);

   $finish;
  end 


  /***********************************************
  // VCD dump
  ***********************************************/
 
  initial
  begin
    $shm_open("/user/student/edu2/Intership_Sangwook_Woo/AES/TestBench/Dump/AES_Test.shm");
    $shm_probe("AC");
  end
 

endmodule
