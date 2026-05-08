`timescale 1ns / 1ps

/*
 * Core interrupt path 개념 확인용 testbench.
 *
 * 목적:
 *   - Timer interrupt는 PLIC를 거치지 않고 MTIP 경로로 core에 들어가는 것을 보인다.
 *   - Peripheral external interrupt는 PLIC가 모아서 MEIP 경로로 core에 들어가는 것을 보인다.
 *   - MachineInterruptController가 mstatus.MIE, mie, mip를 보고 pending/cause를 만들고,
 *     TrapController가 mtvec redirect를 만드는 흐름을 짧은 파형으로 확인한다.
 *
 * 이 TB는 APB Timer peripheral 자체의 counter 동작 검증이 아니라,
 * 발표용 interrupt 경로 설명을 위한 최소 core-side 파형이다.
 */
module tb_CoreInterruptPath;
  logic        rSoftwareIrq;
  logic        rTimerIrq;
  logic        rPlicExternalIrq;
  logic [31:0] rMstatus;
  logic [31:0] rMie;
  logic [31:0] rMipSw;
  logic [31:0] rMtvec;
  logic        rBusWaitStall;
  logic        rExRedirectPending;
  logic        rMemTrapEn;
  logic [3:0]  rMemTrapCause;
  logic [31:0] rMemTrapTval;
  logic [31:0] rMemTrapPc;
  logic        rExTrapEn;
  logic [3:0]  rExTrapCause;
  logic [31:0] rExTrapTval;
  logic [31:0] rExTrapPc;
  logic        rExPcRedirectEn;
  logic [31:0] rExPcRedirectTarget;
  logic [31:0] rFetchPc;

  logic [31:0] wMip;
  logic        wInterruptPending;
  logic [3:0]  wInterruptCause;
  logic        wIrqTrapEn;
  logic        wTrapEn;
  logic        wTrapIsInterrupt;
  logic [3:0]  wTrapCause;
  logic [31:0] wTrapPc;
  logic [31:0] wTrapTval;
  logic        wTrapRedirectEn;
  logic [31:0] wTrapRedirectTarget;
  logic        wExOnlyPcRedirectEn;
  logic [31:0] wExOnlyPcRedirectTarget;

  MachineInterruptController uMachineInterruptController (
    .iSoftwareIrq      (rSoftwareIrq),
    .iTimerIrq         (rTimerIrq),
    .iExternalIrq      (rPlicExternalIrq),
    .iMstatus          (rMstatus),
    .iMie              (rMie),
    .iMipSw            (rMipSw),
    .oMip              (wMip),
    .oInterruptPending (wInterruptPending),
    .oInterruptCause   (wInterruptCause)
  );

  TrapController uTrapController (
    .iInterruptPending       (wInterruptPending),
    .iInterruptCause         (wInterruptCause),
    .iMtvec                  (rMtvec),
    .iBusWaitStall           (rBusWaitStall),
    .iExRedirectPending      (rExRedirectPending),
    .iMemTrapEn              (rMemTrapEn),
    .iMemTrapCause           (rMemTrapCause),
    .iMemTrapTval            (rMemTrapTval),
    .iMemTrapPc              (rMemTrapPc),
    .iExTrapEn               (rExTrapEn),
    .iExTrapCause            (rExTrapCause),
    .iExTrapTval             (rExTrapTval),
    .iExTrapPc               (rExTrapPc),
    .iExPcRedirectEn         (rExPcRedirectEn),
    .iExPcRedirectTarget     (rExPcRedirectTarget),
    .iFetchPc                (rFetchPc),
    .oIrqTrapEn              (wIrqTrapEn),
    .oTrapEn                 (wTrapEn),
    .oTrapIsInterrupt        (wTrapIsInterrupt),
    .oTrapCause              (wTrapCause),
    .oTrapPc                 (wTrapPc),
    .oTrapTval               (wTrapTval),
    .oTrapRedirectEn         (wTrapRedirectEn),
    .oTrapRedirectTarget     (wTrapRedirectTarget),
    .oExOnlyPcRedirectEn     (wExOnlyPcRedirectEn),
    .oExOnlyPcRedirectTarget (wExOnlyPcRedirectTarget)
  );

  task automatic expect_interrupt(
    input logic [3:0] iCause,
    input string      iName
  );
    begin
      #1;
      if (!wInterruptPending || !wIrqTrapEn || !wTrapEn || !wTrapIsInterrupt ||
          (wInterruptCause != iCause) || (wTrapCause != iCause) ||
          (wTrapRedirectTarget != 32'h0000_0080)) begin
        $fatal(1,
               "%s_FAIL pending=%0b irq_trap=%0b trap=%0b int=%0b int_cause=%0d trap_cause=%0d target=0x%08h",
               iName, wInterruptPending, wIrqTrapEn, wTrapEn, wTrapIsInterrupt,
               wInterruptCause, wTrapCause, wTrapRedirectTarget);
      end

      $display("%s_PASS cause=%0d mip=0x%08h target=0x%08h",
               iName, wTrapCause, wMip, wTrapRedirectTarget);
    end
  endtask

  initial begin
    rSoftwareIrq          = 1'b0;
    rTimerIrq             = 1'b0;
    rPlicExternalIrq      = 1'b0;
    rMstatus              = 32'd0;
    rMie                  = 32'd0;
    rMipSw                = 32'd0;
    rMtvec                = 32'h0000_0080;
    rBusWaitStall         = 1'b0;
    rExRedirectPending    = 1'b0;
    rMemTrapEn            = 1'b0;
    rMemTrapCause         = rv32i_pkg::EXC_NONE;
    rMemTrapTval          = 32'd0;
    rMemTrapPc            = 32'd0;
    rExTrapEn             = 1'b0;
    rExTrapCause          = rv32i_pkg::EXC_NONE;
    rExTrapTval           = 32'd0;
    rExTrapPc             = 32'd0;
    rExPcRedirectEn       = 1'b0;
    rExPcRedirectTarget   = 32'd0;
    rFetchPc              = 32'h0000_0200;

    #20;

    // Global MIE, MTIE, MEIE enable.
    rMstatus[rv32i_pkg::LP_MSTATUS_MIE_BIT] = 1'b1;
    rMie[rv32i_pkg::LP_IRQ_MTIP_BIT] = 1'b1;
    rMie[rv32i_pkg::LP_IRQ_MEIP_BIT] = 1'b1;
    #20;

    // Timer IRQ: PLIC output은 0이어도 MTIP pending으로 trap이 발생해야 한다.
    rTimerIrq = 1'b1;
    #10;
    expect_interrupt(rv32i_pkg::IRQ_TIMER, "TIMER_DIRECT_MTIP");

    rTimerIrq = 1'b0;
    #20;

    // External IRQ: PLIC가 만든 external line이 MEIP pending으로 trap을 만든다.
    rPlicExternalIrq = 1'b1;
    #10;
    expect_interrupt(rv32i_pkg::IRQ_EXTERNAL, "PLIC_EXTERNAL_MEIP");

    rPlicExternalIrq = 1'b0;
    #20;

    // 둘 다 동시에 들어오면 MachineInterruptController는 external을 우선 선택한다.
    rTimerIrq        = 1'b1;
    rPlicExternalIrq = 1'b1;
    #10;
    expect_interrupt(rv32i_pkg::IRQ_EXTERNAL, "EXTERNAL_PRIORITY_OVER_TIMER");

    #20;
    $display("CORE_INTERRUPT_PATH_PASS");
    $finish;
  end
endmodule
