`timescale 1ns / 1ps

module tb_StreamFifo;
  logic       rClk;
  logic       rRstn;
  logic [7:0] rSData;
  logic       rSValid;
  logic       wSReady;
  logic [7:0] wMData;
  logic       wMValid;
  logic       rMReady;
  logic       wFull;
  logic       wEmpty;
  int         rExpected;

  StreamFifo #(
    .P_DATA_WIDTH(8),
    .P_DEPTH(4)
  ) uDut (
    .iClk    (rClk),
    .iRstn   (rRstn),
    .iSData  (rSData),
    .iSValid (rSValid),
    .oSReady (wSReady),
    .oMData  (wMData),
    .oMValid (wMValid),
    .iMReady (rMReady),
    .oFull   (wFull),
    .oEmpty  (wEmpty)
  );

  initial begin
    rClk = 1'b0;
    forever #5 rClk = ~rClk;
  end

  task automatic push_byte(input logic [7:0] iData);
    begin
      @(posedge rClk);
      rSData  <= iData;
      rSValid <= 1'b1;

      do begin
        @(posedge rClk);
      end while (!wSReady);

      rSValid <= 1'b0;
      rSData  <= 8'd0;
    end
  endtask

  task automatic pop_byte(input logic [7:0] iExpected);
    begin
      @(posedge rClk);
      rMReady <= 1'b1;

      do begin
        @(posedge rClk);
      end while (!wMValid);

      if (wMData !== iExpected) begin
        $fatal(1, "FIFO data mismatch expected=0x%02h actual=0x%02h",
               iExpected, wMData);
      end

      rMReady <= 1'b0;
    end
  endtask

  initial begin
    rRstn   = 1'b0;
    rSData  = 8'd0;
    rSValid = 1'b0;
    rMReady = 1'b0;

    repeat (5) @(posedge rClk);
    rRstn = 1'b1;
    repeat (2) @(posedge rClk);

    if (!wEmpty) begin
      $fatal(1, "FIFO should be empty after reset");
    end

    push_byte(8'h11);
    push_byte(8'h22);
    push_byte(8'h33);
    push_byte(8'h44);

    if (!wFull) begin
      $fatal(1, "FIFO should be full after four pushes");
    end

    pop_byte(8'h11);
    pop_byte(8'h22);

    fork
      begin
        push_byte(8'h55);
        push_byte(8'h66);
      end
      begin
        pop_byte(8'h33);
        pop_byte(8'h44);
      end
    join

    pop_byte(8'h55);
    pop_byte(8'h66);

    if (!wEmpty) begin
      $fatal(1, "FIFO should be empty at end");
    end

    $display("STREAM_FIFO_PASS");
    $finish;
  end

endmodule
