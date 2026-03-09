/*******************************************************************
* - Project          : 2024 winter internship
* - File name        : TbTop_Lab3_1_wRdChk_wFor.v
* - Description      : Testbench top for Lab1
* - Owner            : SangWook Woo
* - Revision history : 1) 2024.12.27 : Initial release
*                      2) 2025.01.12 : AesCore.v testBecn
********************************************************************/

`timescale 1ns/10ps

module Tb_AesCore;

  /***********************************************
  // wire & register
  ***********************************************/
  reg              iClk;
  reg              iRsn;


  reg              iStAes;
  reg  [127:0]     iAesKey;
  reg  [127:0]     iPlainText;
  reg  [127:0]     roCpText;


  wire [127:0]     oCpText;
  wire             oAesDone;
  

AesCore AesCore1(

  .iClk(iClk),
  .iRsn(iRsn),

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
    roCpText <= 128'h29_C3_50_5F_57_14_20_F6_40_22_99_B3_1A_02_D7_3A;
    roCpText <= 128'h69_c4_e0_d8_6a_7b_04_30_d8_cd_b7_80_70_b4_c5_5a; 
    repeat (  5) @(posedge iClk);
    iRsn <= 1'b0;

    repeat (  2) @(posedge iClk); 
    $display("**** Reset released !!! ****");
    iRsn <= 1'b1;
        
    repeat ( 2) @(posedge iClk); 
    iStAes <= 1'b1;
    //iAesKey <= 128'h54_68_61_74_73_20_6D_79_20_4B_75_6E_67_20_46_75;
    //iPlainText <= 128'h54_77_6F_20_4F_6E_65_20_4E_69_6E_65_20_54_77_6F;

    iAesKey <= 128'h00_01_02_03_04_05_06_07_08_09_0a_0b_0c_0d_0e_0f;
    iPlainText <= 128'h00_11_22_33_44_55_66_77_88_99_aa_bb_cc_dd_ee_ff;
    //iAesKey <= 128'h00_01_02_03_04_05_06_07_08_09_0a_0b_0c_0d_0e_0f;
    //iPlainText <= 128'h00_10_20_30_40_50_60_70_80_90_a0_b0_c0_d0_e0_f0;
    @(posedge oAesDone);
    if(roCpText == oCpText)begin
      $display("%h is equal to %h",oCpText,roCpText);
      $display("*****************SUCCESSS GOOD *****************");
    end
    else begin
      $display("%h is not equal to %h",oCpText,roCpText);
      $display("*****************FAILED NO GOOD *****************");
    end
    
    repeat( 3) @(posedge iClk);
    $finish;
  end


  /***********************************************
  // VCD dump
  ***********************************************/
 
  initial
  begin
    $shm_open("/user/student/edu2/Intership_Sangwook_Woo/AES/TestBench/Dump/AesCoreOnly_Test.shm");
    $shm_probe("AC");//MT memory
  end
 

endmodule
