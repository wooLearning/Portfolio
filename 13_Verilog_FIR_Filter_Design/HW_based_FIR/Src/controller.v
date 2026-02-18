/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : Controller.v
  - Description      : FSM(Finite State Machine)
  - Owner            : Dongjun.Joo
  - Revision history : 1) 2024.11.23 : Initial release
                       2) 2024.11.24 : 1st Debugging
                       3) 2024.11.28 : 2nd Debugging
                       4) 2024.12.01 : Prototype
*******************************************************************/

`timescale 1ns/10ps

module controller (

  // Clock & reset
  input             iClk12M,            // Rising edge
  input             iEnSample600k,      // Rising edge
  input             iRsn,               // Sync. & low reset

  // Update flag
  input             iCoeffUpdateFlag,   // 1'b1: Write, 1'b0: Accmulation

  // Input for SP-SRAM 
  input             iCsnRam,
  input             iWrnRam,
  input      [ 5:0] iAddrRam,
  input      [15:0] iWrDtRam,
  input      [ 5:0] iNumOfCoeff,

  // SP-SRAM access output to SpSram.v
  output            oCsnRam_0, oCsnRam_1, oCsnRam_2, oCsnRam_3,
  output            oWrnRam_0, oWrnRam_1, oWrnRam_2, oWrnRam_3, 
  output     [ 3:0] oAddrRam_0, oAddrRam_1, oAddrRam_2, oAddrRam_3,
  output     [15:0] oWtDtRam_0, oWtDtRam_1, oWtDtRam_2, oWtDtRam_3,

  // Accumulator control output to Accumulator.v
  output            oEnAdd_0, oEnAdd_1, oEnAdd_2, oEnAdd_3,
  output            oEnMul_0, oEnMul_1, oEnMul_2, oEnMul_3,
  output            oEnAcc_0, oEnAcc_1, oEnAcc_2, oEnAcc_3,
  output            oEnDelay
  );

  // Parameter for FSM
  parameter   p_Idle     = 3'b000;
  parameter   p_Update   = 3'b001;
  parameter   p_StAcc    = 3'b010;
  parameter   p_StMul    = 3'b011;
  parameter   p_StAdd    = 3'b100;
  parameter   p_EdMul    = 3'b101;
  parameter   p_EdAdd    = 3'b110;
  parameter   p_Sum      = 3'b111;


// Parameter for RamAddr
  parameter   p_SelRam_0 = 2'b00;
  parameter   p_SelRam_1 = 2'b01;
  parameter   p_SelRam_2 = 2'b10;
  parameter   p_SelRam_3 = 2'b11;


  // wire & reg
  reg    [ 2:0]     rCurState;                                        // Current state
  reg    [ 2:0]     rNxtState;                                        // Next    state

  // Main Counter
  reg    [ 5:0]     rCnt_0;                                           // Read Mul1~10   : 6'd9
  reg    [ 6:0]     rCnt_1;                                           // 128-set of 600k : 6'd63 

  reg    [ 5:0]     rAddrRam_0, rAddrRam_1, rAddrRam_2, rAddrRam_3;   // Correct : iAddrRam         Others : 16'h0000
  reg    [ 5:0]     rNumOfCoeff;                                      // Number of Coefficient
  reg    [15:0]     rWrDtRam;                                         // Data for writing
  reg               rCsnRam;
  reg               rWrnRam;
  
  reg               rBufState;  

  reg               rEnMul;                                           // Enable Multiplication
  reg               rEnAdd;                                           // Enable Addition
  reg               rEnAcc;                                           // Enable Accumulation
  reg               rEnDelay;                                         // Connected with oEnDelay(which is a wire type)

  reg               rResult;                                          // Result of Summation

  

// Part 1: State assignment

  /*************************************************************/
  // FSM(Finite State Machine)
  /*************************************************************/
  // Part 1: Current state update
  always @(posedge iClk12M)
  begin
    if (!iRsn)
      rCurState <= p_Idle;
    else
      rCurState <= rNxtState;

  end


// Part 2: Next state decision
  always @(posedge iClk12M)
  begin
    case (rCurState)
      p_Idle     :
      begin
        if (iCoeffUpdateFlag == 1'b1 && iCsnRam == 1'b0 && iWrnRam == 1'b0)
          rNxtState <= p_Update;          // Update start 

        else
          rNxtState <= p_Idle;            // IDLE

        rBufState <= 1'b0;

      end


      p_Update   :
      begin
        if (iCsnRam == 1'b0)
        begin          
          if ( (iWrnRam == 1'b0) && (iCoeffUpdateFlag == 1'b1) )
                rNxtState <= p_Update;    // Repeat Update 10-coeff (Write)

          else if (iWrnRam == 1'b1)
          begin
            if (iCoeffUpdateFlag == 1'b1)
              rNxtState <= p_Update;

            else
              rNxtState <= p_StAcc;

          end

          else
            rNxtState <= p_Idle;          // Critical Error

        end  

      end 


      p_StAcc   :
      begin
        if(iEnSample600k == 1'b1)
        begin
          rNxtState <= p_StMul;           // Determine next state
          rBufState <= 1'b1;
        end

        else if(rBufState == 1'b1)
        begin
          rNxtState <= p_StMul;           // Delay 1-Clk
          rBufState <= 1'b0;
        end
          
        else
          rNxtState <= p_StAcc;           // Wait iEnSample600k

      end


      p_StMul   :
        rNxtState <= p_StAdd;             // Delay 1-Clk


      p_StAdd   :
      begin
        if (rCnt_0 == 6'd8)
        begin
          rNxtState <= p_EdMul;           // Complete Add & Mul
          rBufState <= 1'b1;

        end

        else if (rBufState == 1'b1)
        begin
          rNxtState <= p_EdMul;
          rBufState <= 1'b0;
        end

        else
          rNxtState <= p_StAdd;           // Repeat Add & Mul(about 10-ea coeff)

      end


      p_EdMul    :
        rNxtState <= p_EdAdd;             // Suspand 1-Clk


      p_EdAdd    :
        rNxtState <= p_Sum;               // Suspand 1-Clk


      p_Sum      :
      begin
        if(rCnt_0 == 6'd1)                // Suspend 3-clk
        begin
          if (rCnt_1 == 7'd0)
          begin
            rNxtState <= p_Idle;          // Up to 64-set of 600k
            rBufState <= 1'b1;
          end

          else      
          begin
            rNxtState <= p_StAcc;         // Coeff Convolution
            rBufState <= 1'b1;
          end

        end

        else if(rBufState == 1'b1)
        begin
          if (rCnt_1 == 7'd0)
          begin
            rNxtState <= p_Idle;          // Up to 64-set of 600k
            rBufState <= 1'b0;
          end

          else      
          begin
            rNxtState <= p_StAcc;         // Coeff Convolution
            rBufState <= 1'b0;
          end

        end

        else
          rNxtState <= p_Sum;             // Wait iEnSample600k

      end


      default    :
        rNxtState <= p_Idle;              // Critical Error

    endcase

  end


// Part 3: Output & enable making

  /*************************************************************/
  // Non-Blocking assignment
  /*************************************************************/

  // Controller
  always @(posedge iClk12M)
  begin
    // p_Idle
    if (!iRsn)
    begin
      rCnt_0      <=  6'd1;
      rCnt_1      <=  7'd0;

      rAddrRam_0  <=  6'hxx;
      rAddrRam_1  <=  6'hxx;
      rAddrRam_2  <=  6'hxx;
      rAddrRam_3  <=  6'hxx;

      rNumOfCoeff <=  6'd0;
      rWrDtRam    <= 16'hxxxx;                       

      rEnMul      <=  1'b0;
      rEnAdd      <=  1'b0;
      rEnAcc      <=  1'b0;
      rEnDelay    <=  1'b0;

    end


    else
    begin
      case(rCurState)
        p_Idle :
            begin 
            rCnt_0      <=  6'd1;
            rCnt_1      <=  7'd0;

            rAddrRam_0  <=  iAddrRam;
             rAddrRam_1  <=  iAddrRam;
             rAddrRam_2  <=  iAddrRam;
             rAddrRam_3  <=  iAddrRam;

            rNumOfCoeff <= iNumOfCoeff;
            rWrDtRam    <= iWrDtRam;
          
             rCsnRam     <= iCsnRam;
             rWrnRam     <= iWrnRam;

            rEnMul      <=  1'b0;
            rEnAdd      <=  1'b0;
            rEnAcc      <=  1'b0;
            rEnDelay    <=  1'b0;
                    
            end


        p_Update : 
        begin
          if(rCnt_0 <= (rNumOfCoeff - 6'd1) )
          begin
            rAddrRam_0 <= iAddrRam;
            rAddrRam_1 <= iAddrRam;
            rAddrRam_2 <= iAddrRam;
            rAddrRam_3 <= iAddrRam;

            rWrDtRam   <= iWrDtRam;

          end
      

          else
          begin
              if(rCnt_0 < 6'd9)
              begin
                rAddrRam_0 <= {p_SelRam_0, 4'h0} + rCnt_0;              // rAddrRam[5:0], p_SelRam[1:0], rCnt_0[5:0]
                rAddrRam_1 <= {p_SelRam_0, 4'h0} + rCnt_0;              // Prevent Error
                rAddrRam_2 <= {p_SelRam_0, 4'h0} + rCnt_0;              // Prevent Error
                rAddrRam_3 <= {p_SelRam_0, 4'h0} + rCnt_0;              // Prevent Error

                rWrDtRam   <= 16'h0000;
              end

              else if(rCnt_0 < 6'd19)
              begin
                rAddrRam_0 <= {p_SelRam_1, 4'h0} + (rCnt_0 - 6'd 9);     // Prevent Error
                rAddrRam_1 <= {p_SelRam_1, 4'h0} + (rCnt_0 - 6'd 9);     // rAddrRam[5:0], p_SelRam[1:0], rCnt_0[5:0]
                rAddrRam_2 <= {p_SelRam_1, 4'h0} + (rCnt_0 - 6'd 9);     // Prevent Error
                rAddrRam_3 <= {p_SelRam_1, 4'h0} + (rCnt_0 - 6'd 9);     // Prevent Error

                rWrDtRam   <= 16'h0000;
              end

              else if(rCnt_0 < 6'd29)
              begin
                rAddrRam_0 <= {p_SelRam_2, 4'h0} + (rCnt_0 - 6'd19);    // Prevent Error
                rAddrRam_1 <= {p_SelRam_2, 4'h0} + (rCnt_0 - 6'd19);    // Prevent Error
                rAddrRam_2 <= {p_SelRam_2, 4'h0} + (rCnt_0 - 6'd19);    // rAddrRam[5:0], p_SelRam[1:0], rCnt_0[5:0]
                rAddrRam_3 <= {p_SelRam_2, 4'h0} + (rCnt_0 - 6'd19);    // Prevent Error

                rWrDtRam   <= 16'h0000;
              end

              else if(rCnt_0 < 6'd39)
              begin
                rAddrRam_0 <= {p_SelRam_3, 4'h0} + (rCnt_0 - 6'd29);    // Prevent Error
                rAddrRam_1 <= {p_SelRam_3, 4'h0} + (rCnt_0 - 6'd29);    // Prevent Error
                rAddrRam_2 <= {p_SelRam_3, 4'h0} + (rCnt_0 - 6'd29);    // Prevent Error
                rAddrRam_3 <= {p_SelRam_3, 4'h0} + (rCnt_0 - 6'd29);    // rAddrRam[5:0], p_SelRam[1:0], rCnt_0[5:0]              

                rWrDtRam   <= 16'h0000;
              end

              else
              begin
                rAddrRam_0 <= {p_SelRam_0, 4'hF};
                rAddrRam_1 <= {p_SelRam_1, 4'hF};
                rAddrRam_2 <= {p_SelRam_2, 4'hF};
                rAddrRam_3 <= {p_SelRam_3, 4'hF};

                rWrDtRam   <= 16'h0000;
              end

          end

          if(rCnt_0 == 6'd39)
          begin
            rCsnRam <= 1'b1;
            rWrnRam <= 1'b1;

            rCnt_0  <= 6'd39;
          end

          else
          begin
            rCsnRam <= 1'b0;

            rCnt_0  <= rCnt_0 + 6'd1;
          end

        end

        
        p_StAcc : 
          begin
            if(iEnSample600k == 1'b1)
            begin
              rCsnRam    <= 1'b0;

              rCnt_0     <= rCnt_0 + 6'd1;                  // Update Counter_0 for save Adder
              rCnt_1     <= rCnt_1 + 7'd1;                  // Update Counter_1

              rEnDelay   <= 1'b1;                           // EnDelay  ON
              rEnMul     <= 1'b0;                           // EnMul    OFF
              rEnAdd     <= 1'b0;                           // EnAdd    OFF
              rEnAcc     <= 1'b0;                           // EnAcc    OFF

              rAddrRam_0 <= 6'h00; 
              rAddrRam_1 <= 6'h10; 
              rAddrRam_2 <= 6'h20;   
              rAddrRam_3 <= 6'h30; 
            end

            else if(rBufState == 1'b1)
            begin
              rAddrRam_0 <= rAddrRam_0 + 6'd1; 
              rAddrRam_1 <= rAddrRam_1 + 6'd1; 
              rAddrRam_2 <= rAddrRam_2 + 6'd1;  
              rAddrRam_3 <= rAddrRam_3 + 6'd1;

              rEnDelay   <= 1'b1;                           // EnDelay  ON
              rEnMul     <= 1'b1;                           // EnMul    ON
              rEnAdd     <= 1'b0;                           // EnAdd    OFF
              rEnAcc     <= 1'b0;                           // EnAcc    OFF
            end

            else
            begin
              rCsnRam    <= 1'b1;

              rCnt_0     <= 6'd0;                           // Reset Counter_0 for save Adder
              rCnt_1     <= rCnt_1;                         // Suspend Counter_1

              rAddrRam_0 <= 6'h0F;
              rAddrRam_1 <= 6'h1F;
              rAddrRam_2 <= 6'h2F;
              rAddrRam_3 <= 6'h3F;

              rEnDelay   <= 1'b1;                           // EnDelay  ON
              rEnMul     <= 1'b0;                           // EnMul    OFF
              rEnAdd     <= 1'b0;                           // EnAdd    OFF
              rEnAcc     <= 1'b0;                           // EnAcc    OFF
            end
                    
          end
                      

        p_StMul : 
          begin
            /*
          rCsnRam    <= 1'b0;
          rWrnRam    <= 1'b1;
          */

          rCnt_0     <= rCnt_0 + 6'd1;

          rAddrRam_0 <= rAddrRam_0 + 6'd1;              // Save Adder : ~(rCnt_0 + 6'd1)
          rAddrRam_1 <= rAddrRam_1 + 6'd1;  
          rAddrRam_2 <= rAddrRam_2 + 6'd1; 
          rAddrRam_3 <= rAddrRam_3 + 6'd1; 

          rEnDelay   <= 1'b1;                           // EnDelay  ON
          rEnMul     <= 1'b1;                           // EnMul    ON
          rEnAdd     <= 1'b1;                           // EnAdd    ON
          rEnAcc     <= 1'b1;                           // EnAcc    ON

            end
                    

        p_StAdd : 
          begin
          if(rBufState == 1'b1)
          begin
            //rCsnRam    <= 1'b1;
            rCnt_0     <= 6'd0;

            rAddrRam_0 <= 6'h0F;
            rAddrRam_1 <= 6'h1F;
            rAddrRam_2 <= 6'h2F;
            rAddrRam_3 <= 6'h3F;

          end

          else
          begin
            rCsnRam    <= 1'b0;

            rCnt_0     <= rCnt_0 + 6'd1;

            rAddrRam_0 <= rAddrRam_0 + 6'd1;              // Save Adder : ~(rCnt_0 + 6'd1)
            rAddrRam_1 <= rAddrRam_1 + 6'd1;  
            rAddrRam_2 <= rAddrRam_2 + 6'd1; 
            rAddrRam_3 <= rAddrRam_3 + 6'd1;   
/*
            rEnDelay   <= 1'b1;                           // EnDelay  ON
            rEnMul     <= 1'b1;                           // EnMul    ON
            rEnAdd     <= 1'b1;                           // EnAdd    ON
            rEnAcc     <= 1'b1;                           // EnAcc    ON
*/
          end

            end

        
        p_EdMul : 
          begin
          rCsnRam    <= 1'b1;
          rWrnRam    <= 1'b1;

          rCnt_0     <= 6'd0;                           // Reset Counter_0

          rEnDelay   <= 1'b1;                           // EnDelay  ON
          rEnMul     <= 1'b0;                           // EnMul    ON  (Last)
          rEnAdd     <= 1'b1;                           // EnAdd    ON  
                    
            end


        p_EdAdd   : 
          begin
          rEnDelay   <= 1'b1;                           // EnDelay  ON
          rEnMul     <= 1'b0;                           // EnMul    OFF
          rEnAdd     <= 1'b0;                           // EnAdd    ON  (Last)
          rEnAcc     <= 1'b0;                           // EnAcc    ON  (Last)
                    
           end


        p_Sum     : 
          begin
          rEnDelay   <= 1'b1;                           // EnDelay  ON
          rEnMul     <= 1'b0;                           // EnMul    OFF
          rEnAdd     <= 1'b0;                           // EnAdd    OFF
          rEnAcc     <= 1'b0;                           // EnAcc    OFF

          rCnt_0     <= rCnt_0 + 6'd1;
                      
            end

      endcase
        
    end

  end


  /*************************************************************/
  // Blocking assignment
  /*************************************************************/ 
  assign oAddrRam_0 = (rAddrRam_0[5:4] == p_SelRam_0) ? rAddrRam_0[3:0] : 4'b1111;     
   assign oAddrRam_1 = (rAddrRam_1[5:4] == p_SelRam_1) ? rAddrRam_1[3:0] : 4'b1111;   
  assign oAddrRam_2 = (rAddrRam_2[5:4] == p_SelRam_2) ? rAddrRam_2[3:0] : 4'b1111;   
  assign oAddrRam_3 = (rAddrRam_3[5:4] == p_SelRam_3) ? rAddrRam_3[3:0] : 4'b1111;   

   assign oWtDtRam_0 = rWrDtRam;
   assign oWtDtRam_1 = rWrDtRam;
   assign oWtDtRam_2 = rWrDtRam;
   assign oWtDtRam_3 = rWrDtRam;

   assign oCsnRam_0  = ( (rAddrRam_0[5:4] == p_SelRam_0) && (!rCsnRam) ) ? 1'b0 : 1'b1;
   assign oCsnRam_1  = ( (rAddrRam_1[5:4] == p_SelRam_1) && (!rCsnRam) ) ? 1'b0 : 1'b1;
   assign oCsnRam_2  = ( (rAddrRam_2[5:4] == p_SelRam_2) && (!rCsnRam) ) ? 1'b0 : 1'b1;
   assign oCsnRam_3  = ( (rAddrRam_3[5:4] == p_SelRam_3) && (!rCsnRam) ) ? 1'b0 : 1'b1;

   assign oWrnRam_0  = rWrnRam;
   assign oWrnRam_1  = rWrnRam;
   assign oWrnRam_2  = rWrnRam;
   assign oWrnRam_3  = rWrnRam;
      
   assign oEnMul_0   = rEnMul;
   assign oEnMul_1   = rEnMul;
   assign oEnMul_2   = rEnMul;
   assign oEnMul_3   = rEnMul;
   
   assign oEnAdd_0   = rEnAdd;
   assign oEnAdd_1   = rEnAdd;
   assign oEnAdd_2   = rEnAdd;
   assign oEnAdd_3   = rEnAdd;
   
   assign oEnAcc_0   = rEnAcc;
  assign oEnAcc_1   = rEnAcc;
  assign oEnAcc_2   = rEnAcc;
  assign oEnAcc_3   = rEnAcc;
   

   // p_StAcc & p_Acc
   assign oEnDelay = rEnDelay;


endmodule