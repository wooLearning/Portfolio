`timescale 1ns / 1ps

module SpiSlaveByteRx (
  input  logic       iClk,
  input  logic       iRstn,
  input  logic       iSpiSclk,
  input  logic       iSpiMosi,
  input  logic       iSpiCsN,
  output logic       oSpiMiso,
  output logic [7:0] oRxData,
  output logic       oRxValid,
  input  logic       iRxReady,
  output logic       oOverflow,
  output logic [31:0] oRxCount
);

  logic [2:0]  rSclkSync;
  logic [2:0]  rCsNSync;
  logic [1:0]  rMosiSync;
  logic [2:0]  rBitCnt;
  logic [7:0]  rShift;
  logic [7:0]  rRxData;
  logic        rRxValid;
  logic        rOverflow;
  logic [31:0] rRxCount;
  logic        wActive;
  logic        wSclkRise;
  logic        wCsRise;
  logic [7:0]  wNextByte;

  assign wActive   = !rCsNSync[2];
  assign wSclkRise = wActive && (rSclkSync[2:1] == 2'b01);
  assign wCsRise   = (rCsNSync[2:1] == 2'b01);
  assign wNextByte = {rShift[6:0], rMosiSync[1]};
  assign oSpiMiso  = 1'b0;
  assign oRxData   = rRxData;
  assign oRxValid  = rRxValid;
  assign oOverflow = rOverflow;
  assign oRxCount  = rRxCount;

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rSclkSync <= 3'b000;
      rCsNSync  <= 3'b111;
      rMosiSync <= 2'b00;
    end
    else begin
      rSclkSync <= {rSclkSync[1:0], iSpiSclk};
      rCsNSync  <= {rCsNSync[1:0], iSpiCsN};
      rMosiSync <= {rMosiSync[0], iSpiMosi};
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rBitCnt   <= 3'd0;
      rShift    <= 8'd0;
      rRxData   <= 8'd0;
      rRxValid  <= 1'b0;
      rOverflow <= 1'b0;
      rRxCount  <= 32'd0;
    end
    else begin
      if (rRxValid && iRxReady) begin
        rRxValid <= 1'b0;
      end

      if (wCsRise) begin
        rBitCnt <= 3'd0;
      end
      else if (wSclkRise) begin
        rShift <= wNextByte;

        if (rBitCnt == 3'd7) begin
          rBitCnt <= 3'd0;

          if (!rRxValid || iRxReady) begin
            rRxData  <= wNextByte;
            rRxValid <= 1'b1;
            rRxCount <= rRxCount + 32'd1;
          end
          else begin
            rOverflow <= 1'b1;
          end
        end
        else begin
          rBitCnt <= rBitCnt + 3'd1;
        end
      end
    end
  end

endmodule
