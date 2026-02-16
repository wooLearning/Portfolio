`timescale 1ns / 10ps

module tb_LcdCtrl_RGB565();

    // Testbench Signals
    reg iClk;
    reg iClk2;
    reg iRsn;
    reg [16:0] iRamWrAddr;
    reg [15:0] iRamRdData;
    wire [16:0] oRamRdAddr;
    wire oLcdHSync;
    wire oLcdVSync;
    wire [4:0] oLcdR;
    wire [5:0] oLcdG;
    wire [4:0] oLcdB;

    wire [15:0] wOdata = {oLcdR, oLcdG, oLcdB};

    localparam WIDTH = 480;
    localparam HEIGHT = 272;
    localparam MAX_ADDR = WIDTH * HEIGHT - 1;

    reg [15:0] rArray [0:MAX_ADDR];
    reg rFlag;

    // Instantiate the module under test (MUT)
    LcdCtrl_RGB565 uut (
        .iClk(iClk2),
        .iRsn(iRsn),
        .iRamWrAddr(iRamWrAddr),
        .iRamRdData(iRamRdData),
        .oRamRdAddr(oRamRdAddr),
        .oLcdHSync(oLcdHSync),
        .oLcdVSync(oLcdVSync),
        .oLcdR(oLcdR),
        .oLcdG(oLcdG),
        .oLcdB(oLcdB)
    );


    // Clock generation
    always begin
        #5 iClk = ~iClk;  // 100 MHz clock, period 10ns
    end
    always begin
        #40 iClk2 = ~iClk2;  // 12.5 MHz clock, period = 80ns (half period = 40ns)
    end
    // Reset and test sequence
    initial begin
        // Initialize signals
        iClk = 0;
        iClk2 = 0;
        rFlag = 0;
        iRsn = 1;

        $display("Applying reset...");
        iRsn = 0;
        
        @(posedge iClk);
        @(posedge iClk);
        @(posedge iClk);
        
        iRsn = 1;

        $display("Test Start");
    
    end
    
    // iRamdWrAddr is working 100Mhz
    always @(posedge iClk or negedge iRsn) begin
        if(!iRsn) begin
            iRamWrAddr <= 0;
            iRamRdData <= 0;
            rFlag = 0;
        end
        else if(iRamWrAddr == MAX_ADDR) begin
           iRamWrAddr <= 0;
           iRamRdData <= 0;
           rFlag <= 1;
        end
        else if(!rFlag) begin
            iRamWrAddr = iRamWrAddr + 1;
            iRamRdData = iRamRdData + 1;
            rArray[iRamWrAddr] <= iRamRdData;
        end
    end
    
    // Monitor the outputs
    // initial begin
    //     $monitor("Time: %t, oRamRdAddr: %h, oLcdR: %h, oLcdG: %h, oLcdB: %h, oLcdHSync: %b, oLcdVSync: %b", 
    //               $time, oRamRdAddr, oLcdR, oLcdG, oLcdB, oLcdHSync, oLcdVSync);
    // end

endmodule
