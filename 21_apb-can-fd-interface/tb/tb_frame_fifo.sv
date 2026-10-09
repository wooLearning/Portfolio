`timescale 1ns/1ps
`default_nettype none

// Independent software queue checks ordering and simultaneous iPush/iPop behavior.
module tb_frame_fifo;
  parameter integer DEPTH = 4;
  localparam integer COUNT_W = $clog2(DEPTH+1);
  logic iClk = 0;
  always #5 iClk = ~iClk;
  logic iRstN = 0, iPush = 0, iPop = 0;
  logic [31:0] iData = 0;
  logic [31:0] oData;
  logic oFull, oEmpty, oPushReady;
  logic [COUNT_W-1:0] oCount;
  logic [31:0] rReferenceMem [0:DEPTH-1];
  integer reference_count = 0, step, k, checks = 0;
  logic [31:0] rRng = 32'h71a6_4c29;
  logic wDoPop, wDoPush;
  integer hit_full_replace = 0, hit_empty_both = 0, hit_overflow = 0, hit_underflow = 0;

  frame_fifo #(.DATA_W(32), .DEPTH(DEPTH)) dut (
    .iClk(iClk), .iRstN(iRstN), .iPush(iPush), .iData(iData), .iPop(iPop),
    .oData(oData), .oFull(oFull), .oEmpty(oEmpty), .oPushReady(oPushReady), .oCount(oCount)
  );
  task automatic check(input logic condition, input string message);
    begin
      checks = checks + 1;
      if (condition !== 1'b1) $fatal(1,"FIFO depth=%0d step=%0d %s",DEPTH,step,message);
    end
  endtask
  task automatic sample_step;
    begin
      #1;
      check(oCount == reference_count,"pre-edge occupancy");
      check(oEmpty == (reference_count==0),"oEmpty flag");
      check(oFull == (reference_count==DEPTH),"oFull flag");
      wDoPop = iPop && (reference_count>0);
      wDoPush = iPush && ((reference_count<DEPTH) || wDoPop);
      check(oPushReady == ((reference_count<DEPTH) || wDoPop),"oPushReady policy");
      if (reference_count>0) check(oData === rReferenceMem[0],"head ordering");
      else check(oData==0,"oEmpty output zero");
      if (iPush && iPop && reference_count==DEPTH) hit_full_replace=hit_full_replace+1;
      if (iPush && iPop && reference_count==0) hit_empty_both=hit_empty_both+1;
      if (iPush && !iPop && reference_count==DEPTH) hit_overflow=hit_overflow+1;
      if (iPop && reference_count==0) hit_underflow=hit_underflow+1;
      @(posedge iClk);
      if (wDoPop) begin
        for (k=0;k<reference_count-1;k=k+1) rReferenceMem[k]=rReferenceMem[k+1];
        reference_count=reference_count-1;
      end
      if (wDoPush) begin
        rReferenceMem[reference_count]=iData;
        reference_count=reference_count+1;
      end
      #1; check(oCount==reference_count,"post-edge occupancy");
      if (reference_count>0) check(oData===rReferenceMem[0],"post-edge head");
    end
  endtask
  initial begin
    repeat(2) @(negedge iClk);
    iRstN=1;
    for (step=0;step<2000;step=step+1) begin
      @(negedge iClk);
      rRng=rRng^(rRng<<13); rRng=rRng^(rRng>>17); rRng=rRng^(rRng<<5);
      iPush=rRng[0]; iPop=rRng[1]; iData=rRng;
      // Force boundary visits before the randomized portion.
      if (step<DEPTH+2) begin iPush=1; iPop=0; end
      if (step==DEPTH+2) begin iPush=1; iPop=1; end
      if (step>DEPTH+2 && step<2*DEPTH+5) begin iPush=0; iPop=1; end
      if (step==2*DEPTH+5) begin iPush=1; iPop=1; end
      if (step==1000) begin
        iRstN=0; iPush=0; iPop=0; reference_count=0;
        @(negedge iClk); iRstN=1;
      end
      sample_step();
    end
    check(hit_full_replace>0 && hit_empty_both>0 && hit_overflow>0 && hit_underflow>0,
      "all four boundary scenarios covered");
    $display("PASS fifo: depth=%0d steps=2000 checks=%0d full_replace=%0d empty_both=%0d overflow=%0d underflow=%0d",
      DEPTH,checks,hit_full_replace,hit_empty_both,hit_overflow,hit_underflow);
    $finish;
  end
  initial begin #100000; $fatal(1,"FIFO watchdog timeout"); end
endmodule

`default_nettype wire
