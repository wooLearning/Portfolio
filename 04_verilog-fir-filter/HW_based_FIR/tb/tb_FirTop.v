`timescale 1ns/10ps

module tb_FirTop;
   parameter CLK = 83.333;
    // Inputs
    reg iClk12M;
    reg iRsn;
    reg iEnSample600k;
    reg iCoeffUpdateFlag;
    reg iCsnRam;
    reg iWrnRam;
    reg [5:0] iAddrRam;
    reg signed [15:0] iWrDtRam;
    reg [5:0] iNumOfCoeff;
    reg signed [2:0] iFirIn;
   reg [4:0] counter;  

    // Outputs
    wire signed [15:0] oFirOut;

    // Instantiate the Unit Under Test (UUT)
    FirTop uut (
        .iClk12M(iClk12M),
        .iRsn(iRsn),
        .iEnSample600k(iEnSample600k),
        .iCoeffUpdateFlag(iCoeffUpdateFlag),
        .iCsnRam(iCsnRam),
        .iWrnRam(iWrnRam),
        .iAddrRam(iAddrRam),
        .iWrDtRam(iWrDtRam),
        .iNumOfCoeff(iNumOfCoeff),
        .iFirIn(iFirIn),
        .oFirOut(oFirOut)
    );

    // Clock generation
    initial begin
        iClk12M <= 0;
      iRsn <= 1'b1;
        iCsnRam <= 1'b1;
        iWrnRam <= 1'b1;
        iNumOfCoeff <= 6'd0;
      iFirIn <= 3'b011;
      iEnSample600k <= 0;
      counter <= 0;
        repeat(4) @(posedge iEnSample600k);
        iFirIn <= 3'd0;
    end
   always begin
      #(CLK/2) iClk12M <= ~iClk12M;
   end
    always @(posedge iClk12M) begin
      if (counter == 5'd19) begin
         counter <= 5'd0;
         iEnSample600k  <= 1;
      end 
      else begin
         iEnSample600k  <= 0;
         counter <= counter + 1;
      end
    end


      initial 
    begin
        
        repeat(2) @(posedge iClk12M);
        iRsn <= 1'b0;
        repeat(2) @(posedge iClk12M);
        iRsn <= 1'b1;

        repeat(1) @(posedge iClk12M);
        iCsnRam <= 1'b0;
        iWrnRam <= 1'b0;
        iCoeffUpdateFlag <= 1'b1;

        iNumOfCoeff <= 6'd40;
iAddrRam <= 6'h00;
iWrDtRam <= 16'b0000000000000000; // -1

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h01;
iWrDtRam <= 16'b0000000000000000; // 2

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h02;
iWrDtRam <= 16'b0000000000000000; // -3

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h03;
iWrDtRam <= 16'b0000000000000000; // 4

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h04;
iWrDtRam <= 16'b0000000000000000; // -5

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h05;
iWrDtRam <= 16'b0000000000000000; // 6

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h06;
iWrDtRam <= 16'b0000000000000000; // -7

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h07;
iWrDtRam <= 16'b0000000000000000; // 8

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h08;
iWrDtRam <= 16'b0000000000000000; // -9

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h09;
iWrDtRam <= 16'b0000000000000000; // 10

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h10;
iWrDtRam <= 16'b0000000000000000; // -11

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h11;
iWrDtRam <= 16'b0000000000000000; // 12

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h12;
iWrDtRam <= 16'b0000000000000000; // -13

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h13;
iWrDtRam <= 16'b0000000000000000; // 14

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h14;
iWrDtRam <= 16'b0000000000000000; // -15

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h15;
iWrDtRam <= 16'b0000000000000000; // 16

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h16;
iWrDtRam <= 16'b0000000000000000; // -17

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h17;
iWrDtRam <= 16'b0000000000000000; // 18

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h18;
iWrDtRam <= 16'b0000000000000000; // -19

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h19;
iWrDtRam <= 16'b0000000000000000; // 20

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h20;
iWrDtRam <= 16'b0000000000000000; // -21

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h21;
iWrDtRam <= 16'b0000000000000000; // 22

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h22;
iWrDtRam <= 16'b0000000000000000; // -23

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h23;
iWrDtRam <= 16'b0000000011000000; // 24

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h24;
iWrDtRam <= 16'b0000000000000000; // -25

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h25;
iWrDtRam <= 16'b1111111010000000; // 26

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h26;
iWrDtRam <= 16'b0000000110; // -27

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h27;
iWrDtRam <= 16'b0000000000000000; // 28

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h28;
iWrDtRam <= 16'b1111110101000000; // -29

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h29;
iWrDtRam <= 16'b0000001101000000; // 30

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h30;
iWrDtRam <= 16'b0000000000000000; // -31

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h31;
iWrDtRam <= 16'b1111101101000000; // 32

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h32;
iWrDtRam <= 16'b0000101000000000; // -33

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h33;
iWrDtRam <= 16'b0000000000000000; // 34

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h34;
iWrDtRam <= 16'b1111100101000000; // -35

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h35;
iWrDtRam <= 16'b0000110000000000; // 36

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h36;
iWrDtRam <= 16'b0000000000000000; // -37

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h37;
iWrDtRam <= 16'b1110011010000000; // 38

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h38;
iWrDtRam <= 16'b0011001110000000; // -39

repeat(1) @(posedge iClk12M);
iAddrRam <= 6'h39;
iWrDtRam <= 16'b0111110100000000; // 40


      // write end

        repeat(10) @(posedge iClk12M);
        iWrnRam          <= 1'b1;
        iCoeffUpdateFlag <= 1'b0;
        iAddrRam         <= 6'h0;
        iWrDtRam         <= 16'h0000;

    end

   initial 
    begin
        $monitor("Time = %0t | iAddrRam = %d, iWrDtRam = %d, iEnSample600k = %d, iFirIn = %d, oFirOut = %d, ",
      $time, iAddrRam, iWrDtRam, iEnSample600k, iFirIn, oFirOut);
    end

endmodule
