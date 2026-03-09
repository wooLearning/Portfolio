/*******************************************************************
  - Project          : 2025 winter internship
  - File name        : TbTop_Prj_Axi_Overlap.v
  - Description      : Testbench for AXI to APB Bridge (Overlap Scenario)
  - Owner            : Sangwook.woo
  - Revision history : 1) 2026.01.07 : Initial release
                       2) 2026.01.07 : read, write task define
                       3) 2026.01.07 : read, write simultaneous check
                       4) 2026.01.07 : error state check block add
                       5) 2026.01.08 : Burst task 
                       6) 2026.01.09 : oS_RValid, iS_RReady timing error solve
                       7) 2026.01.09 : task divide using ifdef
                       8) 2026.01.11 : testbench address modified because registermap and addressmap modified
                       9) 2026.01.11 : AES Test Case 
*******************************************************************/

`timescale 1ns/10ps

module TbTop_Prj_Axi;

  // Clock & Reset
  reg         iClk;
  reg         iRsn;

  // AXI Slave Interface Signals
  reg  [31:0] iS_AwAddr;
  reg  [1:0]  iS_AwLen;
  reg         iS_AwValid;
  wire        oS_AwReady;

  reg  [31:0] iS_WData;
  reg         iS_WLast;
  reg         iS_WValid;
  wire        oS_WReady;

  wire [1:0]  oS_BResp;
  wire        oS_BValid;
  reg         iS_BReady;

  reg  [31:0] iS_ArAddr;
  reg  [1:0]  iS_ArLen;
  reg         iS_ArValid;
  wire        oS_ArReady;

  wire [31:0] oS_RData;
  wire [1:0]  oS_RResp;
  wire        oS_RLast;
  wire        oS_RValid;
  reg         iS_RReady;

  //AES Block Interrupt
  wire oInt;

  //for testbench variable
  reg [31:0]  rData;
  reg [31:0]  rExpectedData;
  integer i;
  reg err_flag;

  // Clock Generation (100MHz)
  initial begin
    iClk = 1'b0;
    forever #5 iClk = ~iClk;
  end

  // DUT Instantiation
  Prj_Axi_Top u_DUT (
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

    //interrupt for AES block
    .oInt(oInt)
  );


  /***********************************************
  // Sync. & active low reset define
  ***********************************************/
  initial begin
  iRsn <= 1'b1;

  repeat (  1) @(posedge iClk);
    iRsn <= 1'b0;

    repeat (  5) @(posedge iClk);
    $display("OOOOO Reset released !!! OOOOO");
    iRsn <= 1'b1;
  end

  // AXI Write Task Burst include
  task axi_write(input [31:0] addr, input [31:0] data, input [1:0] len);
    begin 
      $display("[@%0t] [WRITE START] Addr: 0x%h Data: 0x%h Len: %0d", $time, addr, data, len);
      @(posedge iClk);

      //AW Channel 
      iS_AwAddr  <= addr;
      iS_AwLen   <= len;//burst length
      iS_AwValid <= 1'b1;
      wait(oS_AwReady);
      @(posedge iClk);
      iS_AwValid <= 1'b0;

      //W Channel
      rData <= data;
      for(i=0; i<=len; i=i+1) begin
        repeat (1) @(posedge iClk);//master delay
        iS_WData   <= rData;
        iS_WLast   <= (i==len);
        iS_WValid  <= 1'b1;
        wait(oS_WReady); 
        @(posedge iClk);
        iS_WData   <= 0;
        iS_WLast   <= 1'b0;
        iS_WValid  <= 1'b0;

        rData <= rData + 1'b1;//Incr data for checking
      end
      
      //B Channel
      wait(oS_BValid);
      @(posedge iClk);//master delay
      iS_BReady  <= 1'b1;
      if(oS_BResp == 2'b00) begin
        $display("OO [@%0t] [WRITE DONE ] Addr: 0x%h Data: 0x%h OO", $time, addr, data);
      end
      else begin
        $display("XX [@%0t] [WRITE FAIL ] Addr: 0x%h Data: 0x%h XX", $time, addr, data);
      end
      @(posedge iClk);
      iS_BReady  <= 1'b0;
      
     end
  endtask

  // AXI Read Task (Single Burst)
  task axi_read(input [31:0] addr, input [31:0] data, input [1:0] len);
    begin
      err_flag <= 1'b0;
      $display("[@%0t] [READ  START] Addr: 0x%h Len: %0d", $time, addr, len);
      @(posedge iClk);
      iS_ArAddr  <= addr;
      iS_ArLen   <= len; //burst length
      iS_ArValid <= 1'b1;
      
      // Wait for ARREADY (This might take long if Write is active)
      wait(oS_ArReady);
      //$display("[@%0t] [READ  ARACK] Address Accepted", $time);
      @(posedge iClk);
      iS_ArAddr  <= 0;
      iS_ArValid <= 1'b0;

      //R Channel
      rExpectedData <= data;//burst incr and check register
      for(i=0; i<=len; i=i+1) begin
        wait(oS_RValid); // oS_RValid == 1'b1 && oS_RLast == 1'b1 if burst read
        
        //check read value
        if( (oS_RData == rExpectedData) && (oS_RResp==2'b00) ) begin// 
          $display("OO [@%0t] [READ DONE] %0d Addr: 0x%h, Data: 0x%h OO", $time, i, addr, oS_RData);
        end 
        else begin
          err_flag <= 1'b1;
          $display("[@%0t] XX [READ FAIL] Addr: 0x%h XX", $time, addr); 
        end
        @(posedge iClk);

        //---------------
        // error state check
        //---------------
        if (i==len && oS_RLast != 1'b1) begin
          $display("ERROR: RLAST missing on last beat");
          err_flag <= 1'b1;
        end 
        if (i!=len && oS_RLast == 1'b1) begin
          $display("ERROR: RLAST premature");
          err_flag <= 1'b1;
        end

        iS_RReady  <= 1'b1;
        @(posedge iClk);
        iS_RReady  <= 1'b0;
        wait(!oS_RValid); // Wait for Valid to drop
        rExpectedData <= rExpectedData + 1'b1;
      end

      if(err_flag) $display("XX [READ FAIL] XX");
      else $display("OO [READ ALL DONE] OO");
    end
  endtask

  //Test_case single burst transfer
  task Test_Case1;
    begin
    $display("TEST CASE 1 .. single transfer test");
    //-------------------
    //Wrie Phase single burst
    //-----------------
    axi_write(32'h70000000, 32'hAAAAAAAA, 2'b00);
    axi_write(32'h70000004, 32'hBBBBBBBB, 2'b00);
    axi_write(32'h70000008, 32'hCCCCCCCC, 2'b00);
    axi_write(32'h7000000C, 32'hDDDDDDDD, 2'b00);

    //wrong address  
    axi_write(32'h8000000C, 32'hDEADBEEF, 2'b00);
    axi_write(32'h7014000C, 32'hDEADBEEF, 2'b00);

    //------------------
    //read Phase single burst
    //-----------------
    axi_read(32'h70000000, 32'hAAAAAAAA, 2'b00);
    axi_read(32'h70000004, 32'hBBBBBBBB, 2'b00);
    axi_read(32'h70000008, 32'hCCCCCCCC, 2'b00);
    axi_read(32'h7000000C, 32'hDDDDDDDD, 2'b00);
     
    //wrong address read
    axi_read(32'h80000008, 32'hCCCCCCCC, 2'b00);
    axi_read(32'h7014000C, 32'hDDDDDDDD, 2'b00);
    end
  endtask

  //write read delay test
  task Test_Case2;
    begin
    //simultanous case1
    $display("---------------------------------------------------");
    $display(" Simultaneous Case1:  while Writing, read arrives");
    $display("---------------------------------------------------");
    
    fork
      // Thread 1: Write to 0x7000_0000
      begin
        axi_write(32'h70000000, 32'hDDDD_DDDD, 2'b00);
      end

      // Thread 2: Read from 0x7000_0000 (Started slightly later)
      begin
        #5; // Delay to ensure Write has started
        @(posedge iClk);
        axi_read(32'h70000000, 32'hDDDD_DDDD, 2'b00);
      end
    join

    //simultanous case2
    $display("---------------------------------------------------");
    $display(" Simultaneous Case2:  while reading, wrtie arrives");
    $display("---------------------------------------------------");
    
    fork
      // Thread 1: Write to 0x7000_0000
      begin
        axi_read(32'h70000000, 32'hDDDD_DDDD, 2'b00);
      end
      // Thread 2: Read from 0x7000_0000 (Started slightly later)
      begin
        #5; // Delay to ensure Write has started
        @(posedge iClk);
        axi_write(32'h70000000, 32'hAAAA_AAAA, 2'b00);
      end
    join 
    end
  endtask


  //four burst test
  task Test_Case3;
    begin
    $display("---------------------------------------------------");
    $display(" Burst Test Start");
    $display("---------------------------------------------------");
    //burst test start
    axi_write(32'h7000_0000, 32'hAAAA_AAAA, 2'b11);
    repeat(2) @(posedge iClk);
    axi_read(32'h7000_0000, 32'hAAAA_AAAA, 2'b11);
    end
  endtask
  
  //four slave test 1-burst and 4-burst 
  task Test_Case4;
    begin
    $display("---------------------------------------------------");
    $display(" Multi-Slave Access Test1");
    $display("---------------------------------------------------");

    // Slave 0 (0x7000_0000)
    $display("Testing Slave 0...");
    axi_write(32'h7000_0000, 32'h0A0A_0A0A, 2'b00); // Reg A
    axi_write(32'h7000_0004, 32'h0B0B_0B0B, 2'b00); // Reg B
    axi_write(32'h7000_0008, 32'h0C0C_0C0C, 2'b00); // Reg C
    axi_write(32'h7000_000C, 32'h0D0D_0D0D, 2'b00); // Reg D
    
    axi_read (32'h7000_0000, 32'h0A0A_0A0A, 2'b00);
    axi_read (32'h7000_0004, 32'h0B0B_0B0B, 2'b00);
    axi_read (32'h7000_0008, 32'h0C0C_0C0C, 2'b00);
    axi_read (32'h7000_000C, 32'h0D0D_0D0D, 2'b00);

    // Slave 1 (0x7001_0000)
    $display("Testing Slave 1...");
    axi_write(32'h7001_0000, 32'h1A1A_1A1A, 2'b00);
    axi_write(32'h7001_0004, 32'h1B1B_1B1B, 2'b00);
    axi_write(32'h7001_0008, 32'h1C1C_1C1C, 2'b00);
    axi_write(32'h7001_000C, 32'h1D1D_1D1D, 2'b00);

    axi_read (32'h7001_0000, 32'h1A1A_1A1A, 2'b00);
    axi_read (32'h7001_0004, 32'h1B1B_1B1B, 2'b00);
    axi_read (32'h7001_0008, 32'h1C1C_1C1C, 2'b00);
    axi_read (32'h7001_000C, 32'h1D1D_1D1D, 2'b00);

    // Slave 2 (0x7002_0000)
    $display("Testing Slave 2...");
    axi_write(32'h7002_0000, 32'h2A2A_2A2A, 2'b00);
    axi_write(32'h7002_0004, 32'h2B2B_2B2B, 2'b00);
    axi_write(32'h7002_0008, 32'h2C2C_2C2C, 2'b00);
    axi_write(32'h7002_000C, 32'h2D2D_2D2D, 2'b00);

    axi_read (32'h7002_0000, 32'h2A2A_2A2A, 2'b00);
    axi_read (32'h7002_0004, 32'h2B2B_2B2B, 2'b00);
    axi_read (32'h7002_0008, 32'h2C2C_2C2C, 2'b00);
    axi_read (32'h7002_000C, 32'h2D2D_2D2D, 2'b00);

    // Slave 3 (0x7003_0000 ~ 0x7003_FFFF)
    /*
    $display("Testing Slave 3...");
    axi_write(32'h7000_3000, 32'h3A3A_3A3A, 2'b00);
    axi_write(32'h7000_3004, 32'h3B3B_3B3B, 2'b00);
    axi_write(32'h7000_3008, 32'h3C3C_3C3C, 2'b00);
    axi_write(32'h7000_300C, 32'h3D3D_3D3D, 2'b00);

    axi_read (32'h7000_3000, 32'h3A3A_3A3A, 2'b00);
    axi_read (32'h7000_3004, 32'h3B3B_3B3B, 2'b00);
    axi_read (32'h7000_3008, 32'h3C3C_3C3C, 2'b00);
    axi_read (32'h7000_300C, 32'h3D3D_3D3D, 2'b00);
    */
    end
  endtask


  //multi slave single burst
  task Test_Case5;
    begin
    $display("---------------------------------------------------");
    $display(" Multi-Slave Access Test2");
    $display("---------------------------------------------------");
    // Slave 0
    axi_write(32'h7000_0000, 32'h1111_1111, 2'b00);
    axi_read (32'h7000_0000, 32'h1111_1111, 2'b00);
    
    // Slave 1
    axi_write(32'h7001_0000, 32'h2222_2222, 2'b00);
    axi_read (32'h7001_0000, 32'h2222_2222, 2'b00);

    // Slave 2
    axi_write(32'h7002_0000, 32'h3333_3333, 2'b00);
    axi_read (32'h7002_0000, 32'h3333_3333, 2'b00);

    /*
    // Slave 3
    axi_write(32'h7000_3000, 32'h4444_4444, 2'b00);
    axi_read (32'h7000_3000, 32'h4444_4444, 2'b00); 
    */
    end
  endtask

  //case6 : multi _slave with AES 
  task Test_Case6;
    begin
    $display("---------------------------------------------------");
    $display(" Multi-Slave Access with AES Block ");
    $display("---------------------------------------------------");
   

    //plain text
    axi_write (32'h7003_4000, 32'h33_22_11_00, 2'b00);
    axi_write (32'h7003_4004, 32'h77_66_55_44, 2'b00);
    axi_write (32'h7003_4008, 32'hBB_AA_99_88, 2'b00);
    axi_write (32'h7003_400C, 32'hFF_EE_DD_CC, 2'b00);

    //key input
    axi_write (32'h7003_2000, 32'h03_02_01_00, 2'b00);
    axi_write (32'h7003_2004, 32'h07_06_05_04, 2'b00);
    axi_write (32'h7003_2008, 32'h0B_0A_09_08, 2'b00);
    axi_write (32'h7003_200C, 32'h0F_0E_0D_0C, 2'b00);


    ////////////interrupt enable
    axi_write(32'h7003_A000,1'b1,2'b00);
    axi_write(32'h7003_A008,1'b1,2'b00);
    ///////////////////////

    //startCp
    repeat (50) @(posedge iClk);
    axi_write(32'h7003_0004,32'd16, 2'b00);//apb_write(32'h0003_0004,byteSize);
    repeat (5) @(posedge iClk);
    axi_write(32'h7003_0000,32'h1,  2'b00);//start

    $display("=====================================");
    $display("OOOOO 0x0004 0x0000 write DtCp module Start");
    $display("======================================");

    
     @(posedge oInt);
    //interrupt end read A004 pending clear//////////////////////
    /*
    iPsel    <= 1'b1;
    iPenable <= 1'b0;
    iPwrite  <= 1'b0;
    iPaddr   <= 16'hA004;
    @(posedge iClk);
    iPenable <= 1'b1;
    //if read data == 1'b1 peding clear
    @(posedge iClk);
    if (oPrdata[0] == 1'b1) begin
      axi_write(32'h7003_A004,1'b1, 2'b00);
    end
    iPsel    <= 1'b0;
    iPenable <= 1'b0;
    //////////////////////////////////////////
    */
    axi_read (32'h7003_A004, 32'b1, 2'b00);
    axi_write(32'h7003_A004, 1'b1, 2'b00);//if oS_RData[0] == 1'b1 only


    $display("-------------------------------------------");
    $display("AES READ START");
    $display("-------------------------------------------");

    //compare data
    axi_read (32'h7003_6000, 32'hd8_e0_c4_69, 2'b00);
    axi_read (32'h7003_6004, 32'h30_04_7B_6A, 2'b00);
    axi_read (32'h7003_6008, 32'h80_B7_CD_D8, 2'b00);
    axi_read (32'h7003_600C, 32'h5A_C5_B4_70, 2'b00);

    repeat(10) @(posedge iClk);
 
    end
  endtask  


  // Test Scenario: Overlap Write and Read
  initial begin
    iS_AwAddr  = 32'h0;
    iS_AwLen   = 2'h0;
    iS_AwValid = 1'b0;
    iS_WData   = 32'h0;
    iS_WLast   = 1'b0;
    iS_WValid  = 1'b0;
    iS_BReady  = 1'b0;
    iS_ArAddr  = 32'h0;
    iS_ArLen   = 2'h0;
    iS_ArValid = 1'b0;
    iS_RReady  = 1'b0;
    
    repeat (100) @(posedge iClk); 
   
    //Test_Case1();
    //Test_Case2(); 

   // #100;
   // repeat(10) @(posedge iClk);
    
    //Test_Case3(); 
   
   `ifdef  Case1 
      Test_Case1(); 
    
    `elsif Case2
      Test_Case2();

    `elsif Case3
      Test_Case3();
    
    `elsif Case4 
      Test_Case4();
    
    `elsif Case5
      Test_Case5();
    
    `elsif Case6
      Test_Case6();     
    `endif

    #100;
    repeat(10) @(posedge iClk);

    $display("Simulation Finished");
    $finish;
  end

  /***********************************************
  // SHM dump
  ***********************************************/
  initial begin
    $shm_open("/user/student/cadedu11/Intership_Sangwook.Woo/Proj4/TestBench/Dump/Proj4.shm");
    $shm_probe("ACMT");
  end

endmodule
