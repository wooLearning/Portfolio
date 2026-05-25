`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: DmaAxiLiteAxis
Role: AXI-Lite-controlled AXI-Lite master and AXI-Stream DMA
Summary:
  - S2MM writes stream input bytes into SRAM through AXI-Lite single beats
  - MM2S reads SRAM bytes through AXI-Lite single beats and emits stream output
  - Exposes AXI-Lite control/status/address/length/interrupt registers
  - Raises done/error interrupt levels through sticky IRQ status bits
StateDescription:
  - S_IDLE waits for START
  - S_S2MM_STREAM accepts one stream byte
  - S_S2MM_WRITE issues one AXI-Lite byte write and waits for B
  - S_MM2S_READ issues one AXI-Lite read and waits for R
  - S_MM2S_STREAM holds one byte until stream handshake
[MODULE_INFO_END]
*/
module DmaAxiLiteAxis #(
  parameter logic [31:0] P_SRAM_BASE  = address_map_pkg::SRAM_BASE,
  parameter logic [31:0] P_SRAM_BYTES = address_map_pkg::SRAM_SIZE
) (
  input  logic        iClk,
  input  logic        iRstn,
  input  logic [31:0] iS_AWADDR,
  input  logic        iS_AWVALID,
  output logic        oS_AWREADY,
  input  logic [31:0] iS_WDATA,
  input  logic [3:0]  iS_WSTRB,
  input  logic        iS_WVALID,
  output logic        oS_WREADY,
  output logic [1:0]  oS_BRESP,
  output logic        oS_BVALID,
  input  logic        iS_BREADY,
  input  logic [31:0] iS_ARADDR,
  input  logic        iS_ARVALID,
  output logic        oS_ARREADY,
  output logic [31:0] oS_RDATA,
  output logic [1:0]  oS_RRESP,
  output logic        oS_RVALID,
  input  logic        iS_RREADY,
  output logic        oDoneIrq,
  output logic        oErrorIrq,

  input  logic [7:0]  iS_TDATA,
  input  logic        iS_TVALID,
  output logic        oS_TREADY,
  input  logic        iS_TLAST,
  output logic [7:0]  oM_TDATA,
  output logic        oM_TVALID,
  input  logic        iM_TREADY,
  output logic        oM_TLAST,

  output logic [31:0] oM_AWADDR,
  output logic        oM_AWVALID,
  input  logic        iM_AWREADY,
  output logic [31:0] oM_WDATA,
  output logic [3:0]  oM_WSTRB,
  output logic        oM_WVALID,
  input  logic        iM_WREADY,
  input  logic [1:0]  iM_BRESP,
  input  logic        iM_BVALID,
  output logic        oM_BREADY,
  output logic [31:0] oM_ARADDR,
  output logic        oM_ARVALID,
  input  logic        iM_ARREADY,
  input  logic [31:0] iM_RDATA,
  input  logic [1:0]  iM_RRESP,
  input  logic        iM_RVALID,
  output logic        oM_RREADY
);

  localparam logic [7:0] LP_ADDR_CTRL       = 8'h00;
  localparam logic [7:0] LP_ADDR_STATUS     = 8'h04;
  localparam logic [7:0] LP_ADDR_SRC_ADDR   = 8'h08;
  localparam logic [7:0] LP_ADDR_DST_ADDR   = 8'h0C;
  localparam logic [7:0] LP_ADDR_LEN_BYTES  = 8'h10;
  localparam logic [7:0] LP_ADDR_COUNT      = 8'h14;
  localparam logic [7:0] LP_ADDR_IRQ_ENABLE = 8'h18;
  localparam logic [7:0] LP_ADDR_IRQ_STATUS = 8'h1C;

  localparam logic [31:0] LP_IRQ_DONE  = 32'h0000_0001;
  localparam logic [31:0] LP_IRQ_ERROR = 32'h0000_0002;

  typedef enum logic [2:0] {
    S_IDLE,
    S_S2MM_STREAM,
    S_S2MM_WRITE,
    S_MM2S_READ,
    S_MM2S_STREAM
  } state_e;

  state_e      rState;
  logic        rDirection;
  logic [31:0] rSrcAddr;
  logic [31:0] rDstAddr;
  logic [31:0] rLenBytes;
  logic [31:0] rCountBytes;
  logic [31:0] rIrqEnable;
  logic        rDoneSticky;
  logic        rErrorSticky;
  logic        rAddrErrorSticky;
  logic        rAxiErrorSticky;
  logic        rStreamErrorSticky;
  logic [31:0] rActiveAddr;
  logic [7:0]  rS2mmData;
  logic        rS2mmLast;
  logic        rAwDone;
  logic        rWDone;
  logic [7:0]  rMData;
  logic [31:0] rReadData;
  logic        rBValid;
  logic        rRValid;
  logic        wWrite;
  logic        wRead;
  logic        wStartPulse;
  logic        wAbortPulse;
  logic        wBusy;
  logic        wLastBeat;
  logic        wSHandshake;
  logic        wMHandshake;
  logic        wStartDirection;
  logic [31:0] wStartBase;
  logic [31:0] wStartEnd;
  logic        wStartInRange;
  logic        wClearDone;
  logic        wClearError;
  logic [31:0] wReadData;

  function automatic logic [31:0] byte_to_wdata(
    input logic [7:0]  iData,
    input logic [1:0]  iByteLane
  );
    begin
      unique case (iByteLane)
        2'd0:    byte_to_wdata = {24'd0, iData};
        2'd1:    byte_to_wdata = {16'd0, iData, 8'd0};
        2'd2:    byte_to_wdata = {8'd0, iData, 16'd0};
        default: byte_to_wdata = {iData, 24'd0};
      endcase
    end
  endfunction

  function automatic logic [3:0] byte_to_strb(input logic [1:0] iByteLane);
    begin
      unique case (iByteLane)
        2'd0:    byte_to_strb = 4'b0001;
        2'd1:    byte_to_strb = 4'b0010;
        2'd2:    byte_to_strb = 4'b0100;
        default: byte_to_strb = 4'b1000;
      endcase
    end
  endfunction

  function automatic logic [7:0] select_byte(
    input logic [31:0] iData,
    input logic [1:0]  iByteLane
  );
    begin
      unique case (iByteLane)
        2'd0:    select_byte = iData[7:0];
        2'd1:    select_byte = iData[15:8];
        2'd2:    select_byte = iData[23:16];
        default: select_byte = iData[31:24];
      endcase
    end
  endfunction

  assign oS_AWREADY = !rBValid && iS_WVALID;
  assign oS_WREADY  = !rBValid && iS_AWVALID;
  assign oS_BRESP   = axi_lite_pkg::RESP_OKAY;
  assign oS_BVALID  = rBValid;
  assign oS_ARREADY = !rRValid && !iS_AWVALID;
  assign oS_RDATA   = rReadData;
  assign oS_RRESP   = axi_lite_pkg::RESP_OKAY;
  assign oS_RVALID  = rRValid;

  assign wWrite      = iS_AWVALID && oS_AWREADY && iS_WVALID && oS_WREADY;
  assign wRead       = iS_ARVALID && oS_ARREADY;
  assign wStartPulse = wWrite && (iS_AWADDR[7:0] == LP_ADDR_CTRL) &&
                       iS_WSTRB[0] && iS_WDATA[0] && !wBusy;
  assign wAbortPulse = wWrite && (iS_AWADDR[7:0] == LP_ADDR_CTRL) &&
                       iS_WSTRB[0] && iS_WDATA[2] && wBusy;
  assign wClearDone  = wWrite && (iS_AWADDR[7:0] == LP_ADDR_IRQ_STATUS) &&
                       iS_WSTRB[0] && iS_WDATA[0];
  assign wClearError = wWrite && (iS_AWADDR[7:0] == LP_ADDR_IRQ_STATUS) &&
                       iS_WSTRB[0] && iS_WDATA[1];
  assign wBusy       = (rState != S_IDLE);
  assign wLastBeat   = (rLenBytes != 32'd0) && (rCountBytes == (rLenBytes - 32'd1));
  assign wSHandshake = iS_TVALID && oS_TREADY;
  assign wMHandshake = oM_TVALID && iM_TREADY;
  assign wStartDirection = iS_WDATA[1];
  assign wStartBase = wStartDirection ? rSrcAddr : rDstAddr;
  assign wStartEnd  = wStartBase + rLenBytes;
  assign wStartInRange = (rLenBytes != 32'd0) &&
                         (wStartBase >= P_SRAM_BASE) &&
                         (wStartBase < (P_SRAM_BASE + P_SRAM_BYTES)) &&
                         (wStartEnd >= wStartBase) &&
                         (wStartEnd <= (P_SRAM_BASE + P_SRAM_BYTES));

  assign oDoneIrq  = rDoneSticky && rIrqEnable[0];
  assign oErrorIrq = rErrorSticky && rIrqEnable[1];

  assign oS_TREADY = (rState == S_S2MM_STREAM);
  assign oM_TDATA  = rMData;
  assign oM_TVALID = (rState == S_MM2S_STREAM);
  assign oM_TLAST  = wLastBeat && oM_TVALID;

  assign oM_AWADDR  = rActiveAddr - P_SRAM_BASE;
  assign oM_AWVALID = (rState == S_S2MM_WRITE) && !rAwDone;
  assign oM_WDATA   = byte_to_wdata(rS2mmData, rActiveAddr[1:0]);
  assign oM_WSTRB   = byte_to_strb(rActiveAddr[1:0]);
  assign oM_WVALID  = (rState == S_S2MM_WRITE) && !rWDone;
  assign oM_BREADY  = (rState == S_S2MM_WRITE) && rAwDone && rWDone;
  assign oM_ARADDR  = rActiveAddr - P_SRAM_BASE;
  assign oM_ARVALID = (rState == S_MM2S_READ);
  assign oM_RREADY  = (rState == S_MM2S_READ);

  always_comb begin
    wReadData = 32'd0;

    unique case (iS_ARADDR[7:0])
      LP_ADDR_CTRL: begin
        wReadData = {29'd0, 1'b0, rDirection, 1'b0};
      end

      LP_ADDR_STATUS: begin
        wReadData = {26'd0, rStreamErrorSticky, rAxiErrorSticky,
                   rAddrErrorSticky, rErrorSticky, rDoneSticky, wBusy};
      end

      LP_ADDR_SRC_ADDR:   wReadData = rSrcAddr;
      LP_ADDR_DST_ADDR:   wReadData = rDstAddr;
      LP_ADDR_LEN_BYTES:  wReadData = rLenBytes;
      LP_ADDR_COUNT:      wReadData = rCountBytes;
      LP_ADDR_IRQ_ENABLE: wReadData = rIrqEnable;
      LP_ADDR_IRQ_STATUS: wReadData = {30'd0, rErrorSticky, rDoneSticky};
      default:            wReadData = 32'd0;
    endcase
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      rState             <= S_IDLE;
      rDirection         <= 1'b0;
      rSrcAddr           <= P_SRAM_BASE;
      rDstAddr           <= P_SRAM_BASE;
      rLenBytes          <= 32'd0;
      rCountBytes        <= 32'd0;
      rIrqEnable         <= 32'd0;
      rDoneSticky        <= 1'b0;
      rErrorSticky       <= 1'b0;
      rAddrErrorSticky   <= 1'b0;
      rAxiErrorSticky    <= 1'b0;
      rStreamErrorSticky <= 1'b0;
      rActiveAddr        <= P_SRAM_BASE;
      rS2mmData          <= 8'd0;
      rS2mmLast          <= 1'b0;
      rAwDone            <= 1'b0;
      rWDone             <= 1'b0;
      rMData             <= 8'd0;
      rReadData          <= 32'd0;
      rBValid            <= 1'b0;
      rRValid            <= 1'b0;
    end
    else begin
      if (wWrite) begin
        rBValid <= 1'b1;
      end
      else if (rBValid && iS_BREADY) begin
        rBValid <= 1'b0;
      end

      if (wRead) begin
        rReadData <= wReadData;
        rRValid   <= 1'b1;
      end
      else if (rRValid && iS_RREADY) begin
        rRValid <= 1'b0;
      end

      if (wClearDone) begin
        rDoneSticky <= 1'b0;
      end

      if (wClearError) begin
        rErrorSticky       <= 1'b0;
        rAddrErrorSticky   <= 1'b0;
        rAxiErrorSticky    <= 1'b0;
        rStreamErrorSticky <= 1'b0;
      end

      if (wWrite) begin
        unique case (iS_AWADDR[7:0])
          LP_ADDR_CTRL: begin
            if (iS_WSTRB[0] && !wBusy) begin
              rDirection <= iS_WDATA[1];
            end
          end

          LP_ADDR_SRC_ADDR: begin
            if (!wBusy) begin
              rSrcAddr <= iS_WDATA;
            end
          end

          LP_ADDR_DST_ADDR: begin
            if (!wBusy) begin
              rDstAddr <= iS_WDATA;
            end
          end

          LP_ADDR_LEN_BYTES: begin
            if (!wBusy) begin
              rLenBytes <= iS_WDATA;
            end
          end

          LP_ADDR_IRQ_ENABLE: begin
            rIrqEnable <= iS_WDATA;
          end

          default: begin
          end
        endcase
      end

      if (wAbortPulse) begin
        rState             <= S_IDLE;
        rErrorSticky       <= 1'b1;
        rStreamErrorSticky <= 1'b1;
        rAwDone            <= 1'b0;
        rWDone             <= 1'b0;
      end
      else begin
        unique case (rState)
          S_IDLE: begin
            rAwDone <= 1'b0;
            rWDone  <= 1'b0;

            if (wStartPulse) begin
              rDoneSticky        <= 1'b0;
              rErrorSticky       <= 1'b0;
              rAddrErrorSticky   <= 1'b0;
              rAxiErrorSticky    <= 1'b0;
              rStreamErrorSticky <= 1'b0;
              rCountBytes        <= 32'd0;
              rActiveAddr        <= iS_WDATA[1] ? rSrcAddr : rDstAddr;

              if (!wStartInRange) begin
                rErrorSticky     <= 1'b1;
                rAddrErrorSticky <= 1'b1;
              end
              else if (iS_WDATA[1]) begin
                rState <= S_MM2S_READ;
              end
              else begin
                rState <= S_S2MM_STREAM;
              end
            end
          end

          S_S2MM_STREAM: begin
            if (wSHandshake) begin
              rS2mmData <= iS_TDATA;
              rS2mmLast <= iS_TLAST;
              rAwDone   <= 1'b0;
              rWDone    <= 1'b0;
              rState    <= S_S2MM_WRITE;
            end
          end

          S_S2MM_WRITE: begin
            if (oM_AWVALID && iM_AWREADY) begin
              rAwDone <= 1'b1;
            end

            if (oM_WVALID && iM_WREADY) begin
              rWDone <= 1'b1;
            end

            if (oM_BREADY && iM_BVALID) begin
              if (iM_BRESP != axi_lite_pkg::RESP_OKAY) begin
                rErrorSticky    <= 1'b1;
                rAxiErrorSticky <= 1'b1;
                rState          <= S_IDLE;
              end
              else if (rS2mmLast && !wLastBeat) begin
                rErrorSticky       <= 1'b1;
                rStreamErrorSticky <= 1'b1;
                rState             <= S_IDLE;
              end
              else if (wLastBeat) begin
                rCountBytes <= rCountBytes + 32'd1;
                rDoneSticky <= 1'b1;
                rState      <= S_IDLE;
              end
              else begin
                rCountBytes <= rCountBytes + 32'd1;
                rActiveAddr <= rActiveAddr + 32'd1;
                rAwDone     <= 1'b0;
                rWDone      <= 1'b0;
                rState      <= S_S2MM_STREAM;
              end
            end
          end

          S_MM2S_READ: begin
            if (iM_RVALID) begin
              if (iM_RRESP != axi_lite_pkg::RESP_OKAY) begin
                rErrorSticky    <= 1'b1;
                rAxiErrorSticky <= 1'b1;
                rState          <= S_IDLE;
              end
              else begin
                rMData <= select_byte(iM_RDATA, rActiveAddr[1:0]);
                rState <= S_MM2S_STREAM;
              end
            end
          end

          S_MM2S_STREAM: begin
            if (wMHandshake) begin
              if (wLastBeat) begin
                rCountBytes <= rCountBytes + 32'd1;
                rDoneSticky <= 1'b1;
                rState      <= S_IDLE;
              end
              else begin
                rCountBytes <= rCountBytes + 32'd1;
                rActiveAddr <= rActiveAddr + 32'd1;
                rState      <= S_MM2S_READ;
              end
            end
          end

          default: begin
            rState <= S_IDLE;
          end
        endcase
      end
    end
  end

endmodule
