`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbI2c
Role: Minimal APB wrapper for the I2C master core
Summary:
  - Exposes CTRL, STATUS, CLKDIV, SLAVE_ADDR, TXDATA, and RXDATA registers
  - Starts one single-byte I2C transaction per CTRL.START write
  - Holds DONE and ACKERR sticky until the next transfer starts or software clears them
StateDescription:
  - I2C transfer state is held in the wrapped I2cMaster module
[MODULE_INFO_END]
*/
module ApbI2c (
  input  logic        iPclk,
  input  logic        iPresetn,
  input  logic        iPSEL,
  input  logic        iPENABLE,
  input  logic        iPWRITE,
  input  logic [11:0] iPADDR,
  input  logic [31:0] iPWDATA,
  input  logic [3:0]  iPSTRB,
  input  logic        iI2cSda,
  output logic        oI2cSclDriveLow,
  output logic        oI2cSdaDriveLow,
  output logic [31:0] oPRDATA,
  output logic        oPREADY,
  output logic        oPSLVERR
);

  localparam logic [7:0] LP_ADDR_CTRL      = 8'h00;
  localparam logic [7:0] LP_ADDR_STATUS    = 8'h04;
  localparam logic [7:0] LP_ADDR_CLKDIV    = 8'h08;
  localparam logic [7:0] LP_ADDR_SLAVEADDR = 8'h0C;
  localparam logic [7:0] LP_ADDR_TXDATA    = 8'h10;
  localparam logic [7:0] LP_ADDR_RXDATA    = 8'h14;

  logic        rRead;
  logic [15:0] rClkDiv;
  logic [15:0] rClkCnt;
  logic [6:0]  rSlaveAddr;
  logic [7:0]  rTxData;
  logic        rDoneSticky;
  logic        rAckErrorSticky;
  logic        wWrite;
  logic        wStartPulse;
  logic        wTick;
  logic        wI2cBusy;
  logic        wI2cDone;
  logic        wI2cAckError;
  logic [7:0]  wI2cRxData;

  assign wWrite = iPSEL && iPENABLE && iPWRITE;
  assign wStartPulse = wWrite && (iPADDR[7:0] == LP_ADDR_CTRL) &&
                       iPSTRB[0] && iPWDATA[0] && !wI2cBusy;
  assign oPREADY  = 1'b1;
  assign oPSLVERR = 1'b0;

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rClkCnt <= 16'd0;
      wTick   <= 1'b0;
    end
    else begin
      wTick <= 1'b0;

      if (wI2cBusy || wStartPulse) begin
        if (rClkCnt >= rClkDiv) begin
          rClkCnt <= 16'd0;
          wTick   <= 1'b1;
        end
        else begin
          rClkCnt <= rClkCnt + 16'd1;
        end
      end
      else begin
        rClkCnt <= 16'd0;
      end
    end
  end

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rRead           <= 1'b0;
      rClkDiv         <= 16'd1;
      rSlaveAddr      <= 7'd0;
      rTxData         <= 8'd0;
      rDoneSticky     <= 1'b0;
      rAckErrorSticky <= 1'b0;
    end
    else begin
      if (wI2cDone) begin
        rDoneSticky <= 1'b1;
      end

      if (wI2cAckError) begin
        rAckErrorSticky <= 1'b1;
      end

      if (wStartPulse) begin
        rDoneSticky     <= 1'b0;
        rAckErrorSticky <= 1'b0;
      end

      if (wWrite) begin
        unique case (iPADDR[7:0])
          LP_ADDR_CTRL: begin
            if (iPSTRB[0] && !wI2cBusy) begin
              rRead <= iPWDATA[1];
            end
          end

          LP_ADDR_STATUS: begin
            if (iPSTRB[0]) begin
              if (iPWDATA[1]) begin
                rDoneSticky <= 1'b0;
              end

              if (iPWDATA[2]) begin
                rAckErrorSticky <= 1'b0;
              end
            end
          end

          LP_ADDR_CLKDIV: begin
            if (!wI2cBusy) begin
              rClkDiv <= iPWDATA[15:0];
            end
          end

          LP_ADDR_SLAVEADDR: begin
            if (iPSTRB[0] && !wI2cBusy) begin
              rSlaveAddr <= iPWDATA[6:0];
            end
          end

          LP_ADDR_TXDATA: begin
            if (iPSTRB[0] && !wI2cBusy) begin
              rTxData <= iPWDATA[7:0];
            end
          end

          default: begin
          end
        endcase
      end
    end
  end

  I2cMaster uI2cMaster (
    .iClk       (iPclk),
    .iRstn      (iPresetn),
    .iTick      (wTick),
    .iStart     (wStartPulse),
    .iRead      (rRead),
    .iSlaveAddr (rSlaveAddr),
    .iTxData    (rTxData),
    .iSda       (iI2cSda),
    .oRxData    (wI2cRxData),
    .oBusy      (wI2cBusy),
    .oDone      (wI2cDone),
    .oAckError  (wI2cAckError),
    .oSclDriveLow     (oI2cSclDriveLow),
    .oSdaDriveLow     (oI2cSdaDriveLow)
  );

  always_comb begin
    oPRDATA = 32'd0;

    unique case (iPADDR[7:0])
      LP_ADDR_CTRL: begin
        oPRDATA = {30'd0, rRead, 1'b0};
      end

      LP_ADDR_STATUS: begin
        oPRDATA = {29'd0, rAckErrorSticky, rDoneSticky, wI2cBusy};
      end

      LP_ADDR_CLKDIV: begin
        oPRDATA = {16'd0, rClkDiv};
      end

      LP_ADDR_SLAVEADDR: begin
        oPRDATA = {25'd0, rSlaveAddr};
      end

      LP_ADDR_TXDATA: begin
        oPRDATA = {24'd0, rTxData};
      end

      LP_ADDR_RXDATA: begin
        oPRDATA = {24'd0, wI2cRxData};
      end

      default: begin
        oPRDATA = 32'd0;
      end
    endcase
  end

endmodule
