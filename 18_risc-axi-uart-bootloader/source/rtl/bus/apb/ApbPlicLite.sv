`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbPlicLite
Role: APB로 제어되는 RISC-V PLIC 형태의 간단한 외부 interrupt controller
Summary:
  - 각 peripheral raw IRQ level을 gateway에서 1회성 request pulse로 바꾼다.
  - request pulse를 pending bit로 latch한다.
  - enable, pending, threshold, priority, claim, complete register를 제공한다.
  - claim 가능한 interrupt가 있으면 CPU의 machine external interrupt line을 올린다.
StateDescription:
  - gateway는 같은 source가 complete되기 전까지 중복 request를 막는다.
  - pending bit는 software가 COMPLETE를 쓸 때까지 유지한다.
  - CLAIM read는 가장 우선순위가 높은 pending source ID만 알려주고 side effect를 만들지 않는다.
[MODULE_INFO_END]

구현상 중요한 점:
  일반 PLIC 문서에서는 claim read가 pending clear 효과를 갖는 형태가 많다.
  하지만 이 SoC에서는 CPU -> AXI-Lite -> APB bridge를 거쳐 read data가 돌아오므로,
  claim read와 같은 cycle에 pending을 지우면 CPU가 claim ID를 안정적으로 받기 전에
  source가 사라지는 타이밍 문제가 생길 수 있다.

  그래서 여기서는 CLAIM read를 "ID 조회"로만 쓰고, handler가 PLIC_COMPLETE에
  claim ID를 write했을 때 pending/gateway 상태를 정리한다. 현재 ROM의
  software vector table dispatch도 이 동작을 기준으로 한다.
*/
module ApbPlicLite #(
  parameter integer P_NUM_SOURCES = 8,
  parameter integer P_PRIORITY_WIDTH = 3
) (
  input  logic        iPclk,
  input  logic        iPresetn,
  input  logic [P_NUM_SOURCES-1:0] iIrqSources,
  input  logic        iPSEL,
  input  logic        iPENABLE,
  input  logic        iPWRITE,
  input  logic [11:0] iPADDR,
  input  logic [31:0] iPWDATA,
  input  logic [3:0]  iPSTRB,
  output logic [31:0] oPRDATA,
  output logic        oPREADY,
  output logic        oPSLVERR,
  output logic        oExternalIrq
);

  localparam logic [7:0] LP_ADDR_ENABLE          = 8'h00;
  localparam logic [7:0] LP_ADDR_PENDING         = 8'h04;
  localparam logic [7:0] LP_ADDR_ENABLED_PENDING = 8'h08;
  localparam logic [7:0] LP_ADDR_CLAIM           = 8'h0C;
  localparam logic [7:0] LP_ADDR_COMPLETE        = 8'h10;
  localparam logic [7:0] LP_ADDR_THRESHOLD       = 8'h14;
  localparam logic [7:0] LP_ADDR_ACTIVE          = 8'h18;
  localparam logic [7:0] LP_ADDR_PRIORITY_BASE   = 8'h20;

  logic [31:0] rEnable;
  logic [31:0] rPending;
  logic [31:0] rActive;
  logic [P_PRIORITY_WIDTH-1:0] rThreshold;
  logic [P_PRIORITY_WIDTH-1:0] rPriority [0:P_NUM_SOURCES-1];
  logic [P_NUM_SOURCES-1:0] wGatewayRequestPulse;
  logic [P_NUM_SOURCES-1:0] wGatewayCompletePulse;
  logic [P_NUM_SOURCES-1:0] wGatewayBlocked;
  logic [31:0] wGatewayRequestMask;
  logic [31:0] wGatewayCompleteMask;
  logic [31:0] wCompleteMask;
  logic [31:0] wPendingClearMask;
  logic [31:0] wEnabledPending;
  logic [31:0] wClaimable;
  logic [31:0] wClaimMask;
  logic [31:0] wPriorityReadData;
  logic [31:0] wSourceLimitMask;
  logic [31:0] wPriorityIndex;
  logic [31:0] wBestId;
  logic [P_PRIORITY_WIDTH-1:0] wBestPriority;
  logic        wRead;
  logic        wWrite;
  logic        wPrioritySel;
  integer      idxMask;
  integer      idxClaim;
  integer      idxReset;
  integer      idxComplete;

  assign wRead  = iPSEL && iPENABLE && !iPWRITE;
  assign wWrite = iPSEL && iPENABLE && iPWRITE;
  assign oPREADY = 1'b1;
  assign oPSLVERR = 1'b0;

  ApbPlicGateway #(
    .P_NUM_SOURCES(P_NUM_SOURCES)
  ) uApbPlicGateway (
    .iClk          (iPclk),
    .iRstn         (iPresetn),
    .iRawIrq       (iIrqSources),
    .iCompletePulse(wGatewayCompletePulse),
    .oRequestPulse (wGatewayRequestPulse),
    .oBlocked      (wGatewayBlocked)
  );

  always_comb begin
    wGatewayRequestMask = 32'd0;
    wSourceLimitMask = 32'd0;
    wGatewayCompletePulse = '0;

    for (idxMask = 0; idxMask < P_NUM_SOURCES; idxMask = idxMask + 1) begin
      wGatewayRequestMask[idxMask] = wGatewayRequestPulse[idxMask];
      wSourceLimitMask[idxMask] = 1'b1;
      wGatewayCompletePulse[idxMask] = wGatewayCompleteMask[idxMask];
    end
  end

  // enable된 pending source만 CPU에 interrupt 후보로 보낸다.
  assign wEnabledPending = rEnable & rPending & wSourceLimitMask;
  assign wPendingClearMask =
    (wWrite && (iPADDR[7:0] == LP_ADDR_PENDING)) ? (iPWDATA & wSourceLimitMask) : 32'd0;
  assign wGatewayCompleteMask = (wCompleteMask | wPendingClearMask) & wSourceLimitMask;

  always_comb begin
    wBestId       = 32'd0;
    wBestPriority = '0;
    wClaimable    = 32'd0;

    // claim 가능한 source 중 priority가 가장 높은 ID를 고른다. ID는 source index + 1이다.
    for (idxClaim = 0; idxClaim < P_NUM_SOURCES; idxClaim = idxClaim + 1) begin
      if (rEnable[idxClaim] && rPending[idxClaim] && !rActive[idxClaim] &&
          (rPriority[idxClaim] > rThreshold)) begin
        wClaimable[idxClaim] = 1'b1;

        if ((wBestId == 32'd0) || (rPriority[idxClaim] > wBestPriority)) begin
          wBestId       = idxClaim[31:0] + 32'd1;
          wBestPriority = rPriority[idxClaim];
        end
      end
    end
  end

  assign wClaimMask = (wBestId == 32'd0) ? 32'd0 : (32'd1 << (wBestId[4:0] - 5'd1));
  // claim 가능한 source가 하나라도 있으면 CPU machine external IRQ를 올린다.
  assign oExternalIrq = |wClaimable;

  always_comb begin
    wCompleteMask = 32'd0;

    if (wWrite && (iPADDR[7:0] == LP_ADDR_COMPLETE) &&
        (iPWDATA[4:0] != 5'd0) && (iPWDATA[4:0] <= P_NUM_SOURCES[4:0])) begin
      for (idxComplete = 0; idxComplete < P_NUM_SOURCES; idxComplete = idxComplete + 1) begin
        if (iPWDATA[4:0] == (idxComplete[4:0] + 5'd1)) begin
          wCompleteMask[idxComplete] = 1'b1;
        end
      end
    end
  end

  always_comb begin
    wPriorityIndex = {24'd0, iPADDR[7:2]} - 32'd8;
    wPrioritySel = (iPADDR[7:0] >= LP_ADDR_PRIORITY_BASE) &&
                   (wPriorityIndex < P_NUM_SOURCES[31:0]);
    wPriorityReadData = 32'd0;

    if (wPrioritySel) begin
      wPriorityReadData[P_PRIORITY_WIDTH-1:0] = rPriority[wPriorityIndex];
    end
  end

  always_comb begin
    oPRDATA = 32'd0;

    unique case (iPADDR[7:0])
      LP_ADDR_ENABLE:          oPRDATA = rEnable;
      LP_ADDR_PENDING:         oPRDATA = rPending & wSourceLimitMask;
      LP_ADDR_ENABLED_PENDING: oPRDATA = wEnabledPending;
      // CLAIM read는 side effect 없이 ID만 반환한다. pending clear는 COMPLETE에서 처리한다.
      LP_ADDR_CLAIM:           oPRDATA = wBestId;
      LP_ADDR_COMPLETE:        oPRDATA = 32'd0;
      LP_ADDR_THRESHOLD: begin
        oPRDATA[P_PRIORITY_WIDTH-1:0] = rThreshold;
      end
      LP_ADDR_ACTIVE:          oPRDATA = rActive & wSourceLimitMask;
      default: begin
        if (wPrioritySel) begin
          oPRDATA = wPriorityReadData;
        end
      end
    endcase
  end

  always_ff @(posedge iPclk or negedge iPresetn) begin
    if (!iPresetn) begin
      rEnable    <= 32'd0;
      rPending   <= 32'd0;
      rActive    <= 32'd0;
      rThreshold <= '0;

      for (idxReset = 0; idxReset < P_NUM_SOURCES; idxReset = idxReset + 1) begin
        rPriority[idxReset] <= {{(P_PRIORITY_WIDTH-1){1'b0}}, 1'b1};
      end
    end
    else begin
      // 기본적으로 새 request를 pending에 latch하고, complete된 source만 정리한다.
      rPending <= ((rPending | wGatewayRequestMask) & ~wCompleteMask) & wSourceLimitMask;

      if (wWrite) begin
        unique case (iPADDR[7:0])
          LP_ADDR_ENABLE: begin
            rEnable <= iPWDATA & wSourceLimitMask;
          end
          LP_ADDR_PENDING: begin
            // 디버그/강제 clear용 pending write. 1을 쓴 bit만 clear한다.
            rPending <= ((rPending & ~iPWDATA) | wGatewayRequestMask) & wSourceLimitMask;
          end
          LP_ADDR_COMPLETE: begin
            // handler가 claim ID를 complete로 써주면 해당 source를 정리한다.
            rActive <= (rActive & ~wCompleteMask) & wSourceLimitMask;
            rPending <= ((rPending | wGatewayRequestMask) & ~wCompleteMask) & wSourceLimitMask;
          end
          LP_ADDR_THRESHOLD: begin
            rThreshold <= iPWDATA[P_PRIORITY_WIDTH-1:0];
          end
          default: begin
            if (wPrioritySel) begin
              rPriority[wPriorityIndex] <= iPWDATA[P_PRIORITY_WIDTH-1:0];
            end
          end
        endcase
      end
    end
  end

endmodule
