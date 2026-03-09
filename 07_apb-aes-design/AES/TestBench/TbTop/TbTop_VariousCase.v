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


  reg  [127:0] writeData[0:127];  //512*32 array
  reg  [127:0] readData[0:127]; //check endian conversion

  parameter byteSize = 16;//1byte

  //for Aes module
  reg iStAes;
  reg[127:0] iAesKey;
  reg[127:0[ iPlainText;
  
  wire oAesDone;
  wire[127:0] oCpText;

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


 AesCore AesCore(
  .iClk            (iClk),
  .iRsn            (iRsn),

  .iStAes(iStAes),
  .iAesKey(iAesKey),
  .iPlainText(iPlainText),

  .oAesDone(oAesDone),
  .oCpText(oCpText)
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

  function[127:0] endianConv;
  input[127:0] data;
    begin
      endianConv = {data[0+:8],data[8+:8],data[16+:8],data[24+:8],data[32+:8],data[40+:8],data[48+:8],data[56+:8] ,data[64+:8]
                   ,data[72+:8],data[80+:8], data[88+:8],data[96+:8]data[104+:8],data[112+:8],data[120+:8]};
    end
  endfunction

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

    //make write random data
    for(i=0;i<byteSize/16;i=i+1) begin
      writeData[i] = {4{$urandom}};//32bit random number
    end
    iAesKey <= 128'h00_11_22_33_44_55_66_77_88_99_aa_bb_cc_dd_ee_ff;
    for(i=0;i<byteSize/4;i=i+1) begin
      iStAes = 1'b1;
      iPlainText = writeData[i];
      @(posedge oAesDone);
      readData[i] = oCpText;
    end
    repeat (50) @(posedge iClk);
  
    //key
    /*
    apb_write (16'h4000, 32'h33_22_11_00);
    apb_write (16'h4004, 32'h77_66_55_44);
    apb_write (16'h4008, 32'hBB_AA_99_88);
    apb_write (16'h400C, 32'hFF_EE_DD_CC);
    */
    apb_write (16'h4000, endianConv(iAesKey)[0+:32]);
    apb_write (16'h4004, endianConv(iAesKey)[32+:32]);
    apb_write (16'h4008, endianConv(iAesKey)[64+:32]);
    apb_write (16'h400C, endianConv(iAesKey)[96+:32]);

 
   for (i=0 ; i<byteSize/4; i=i+1) begin
      repeat (5) @(posedge iClk);
      apb_write(16'h4000+(4*i), writeData[i]);
    end 
   
   ////////////interrupt enable
    apb_write(16'hA000,1'b1);
    apb_write(16'hA008,1'b1);
    ///////////////////////

   //startCp
    repeat (50) @(posedge iClk);
    //apb_write(16'h0004,byteSize);
    apb_write(16'h0004,byteSize);
    repeat (5) @(posedge iClk);
    apb_write(16'h0000,32'h1);

    $display("=====================================");
    $display("0000  x0004 x0000 write Cp module Start");
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
   
    // read compare for block
    for(i=0; i<byteSize; i = i + 1) begin
      repeat(100) @(posedge iClk);
      apb_read(16'h6000+(4*i), readData[i]);
    end
   repeat(10) @(posedge iClk);

   $finish;
  end 


  /***********************************************
  // VCD dump
  ***********************************************/
 
  initial
  begin
    $shm_open("/user/student/edu2/Intership_Sangwook_Woo/AES/TestBench/Dump/AES_VariousCase.shm");
    $shm_probe("AC");
  end
 

endmodule
