`timescale 1ns/1ps
`default_nettype none

module tb_apb_can_bridge;
  parameter integer TX_DEPTH = 4;
  parameter integer RX_DEPTH = 8;
  logic iPclk = 0;
  always #10 iPclk = ~iPclk; // 50 MHz APB clock
  logic iPresetN = 0;
  logic iPsel = 0, iPenable = 0, iPwrite = 0;
  logic [11:0] iPaddr = 0;
  logic [31:0] iPwdata = 0;
  logic [31:0] oPrdata;
  logic oPready, oPslverr, oIrq;
  logic oCanTxValid, iCanTxReady, oCanTxFd, oCanTxBrs;
  logic [10:0] oCanTxId;
  logic [3:0] oCanTxDlc;
  logic [511:0] oCanTxData;
  logic wModelDone, wModelError;
  logic rInjectDone = 0, rInjectError = 0;
  logic iCanTxDone;
  assign iCanTxDone = wModelDone || rInjectDone;
  logic iCanTxError;
  assign iCanTxError = wModelError || rInjectError;
  logic rCoreAllow = 0, rCoreFail = 0;
  logic [7:0] rCoreLatency = 5;
  logic iCanRxValid = 0, iCanRxFd = 0, iCanRxBrs = 0;
  logic [10:0] iCanRxId = 0;
  logic [3:0] iCanRxDlc = 0;
  logic [511:0] iCanRxData = 0;
  logic [528:0] rExpectedTx [0:2047];
  integer exp_head = 0, exp_tail = 0;
  integer checks = 0, cases = 0, accepted_total = 0;
  integer idx, jdx, seed, random_state, random_value;
  logic [31:0] rReadValue;
  logic rStalled = 0;
  logic [528:0] rStalledFrame;
  logic [8*256-1:0] rVcdPath;

  apb_can_bridge #(.TX_DEPTH(TX_DEPTH), .RX_DEPTH(RX_DEPTH)) dut (
    .iPclk(iPclk), .iPresetN(iPresetN), .iPsel(iPsel), .iPenable(iPenable),
    .iPwrite(iPwrite), .iPaddr(iPaddr), .iPwdata(iPwdata),
    .oPrdata(oPrdata), .oPready(oPready), .oPslverr(oPslverr), .oIrq(oIrq),
    .oCanTxValid(oCanTxValid), .iCanTxReady(iCanTxReady), .oCanTxId(oCanTxId),
    .oCanTxDlc(oCanTxDlc), .oCanTxFd(oCanTxFd), .oCanTxBrs(oCanTxBrs),
    .oCanTxData(oCanTxData), .iCanTxDone(iCanTxDone), .iCanTxError(iCanTxError),
    .iCanRxValid(iCanRxValid), .iCanRxId(iCanRxId), .iCanRxDlc(iCanRxDlc),
    .iCanRxFd(iCanRxFd), .iCanRxBrs(iCanRxBrs), .iCanRxData(iCanRxData)
  );
  can_core_model u_core_model (
    .iClk(iPclk), .iRstN(iPresetN), .iAllow(rCoreAllow), .iLatency(rCoreLatency),
    .iFail(rCoreFail), .iTxValid(oCanTxValid), .oTxReady(iCanTxReady),
    .oTxDone(wModelDone), .oTxError(wModelError)
  );

  // Independent expected payload builder; every accepted frame is compared.
  function automatic integer payload_length(input integer dlc);
    begin
      case (dlc)
        0,1,2,3,4,5,6,7,8: payload_length = dlc;
        9: payload_length = 12; 10: payload_length = 16;
        11: payload_length = 20; 12: payload_length = 24;
        13: payload_length = 32; 14: payload_length = 48;
        15: payload_length = 64;
        default: payload_length = 0;
      endcase
    end
  endfunction
  function automatic [31:0] pattern_word(input integer tag, input integer index);
    pattern_word = 32'h91a7_c300 ^ (32'(tag) * 32'h0101_0101) ^ (32'(index) * 32'h1020_4081);
  endfunction
  function automatic [511:0] expected_payload(input integer tag, input integer dlc);
    integer k;
    logic [31:0] value;
    begin
      expected_payload = 0;
      for (k = 0; k < payload_length(dlc); k = k + 1) begin
        value = pattern_word(tag, k / 4);
        expected_payload[k*8 +: 8] = value[(k%4)*8 +: 8];
      end
    end
  endfunction
  task automatic check(input logic condition, input string message);
    begin
      checks = checks + 1;
      if (condition !== 1'b1) $fatal(1, "CHECK FAILED @ %0t: %s", $time, message);
    end
  endtask
  task automatic start_case(input string name);
    begin
      cases = cases + 1;
      $display("CASE %0d @ %0t: %s", cases, $time, name);
    end
  endtask
  task automatic tick(input integer count);
    repeat (count) begin @(posedge iPclk); #1; end
  endtask
  task automatic reset_dut;
    begin
      @(negedge iPclk);
      iPresetN = 0; iPsel = 0; iPenable = 0; iPwrite = 0; iCanRxValid = 0;
      rCoreAllow = 0; rCoreFail = 0; rInjectDone = 0; rInjectError = 0;
      exp_tail = 0;
      tick(3);
      @(negedge iPclk); iPresetN = 1;
      tick(2);
    end
  endtask
  task automatic apb_transfer(input logic write_en, input [11:0] addr,
    input [31:0] data, input logic expected_error, output logic [31:0] result);
    begin
      @(negedge iPclk);
      iPsel = 1; iPenable = 0; iPwrite = write_en; iPaddr = addr; iPwdata = data;
      @(posedge iPclk); #1;
      check(!oPslverr, "PSLVERR must be low during SETUP");
      @(negedge iPclk); iPenable = 1;
      #1;
      check(oPready, "zero-wait APB response");
      check(oPslverr === expected_error, $sformatf("APB error addr=%03x write=%0b", addr, write_en));
      result = oPrdata;
      @(posedge iPclk); #1;
      @(negedge iPclk); iPsel = 0; iPenable = 0;
    end
  endtask
  task automatic apb_write(input [11:0] addr, input [31:0] data, input logic error_expected);
    logic [31:0] unused;
    apb_transfer(1, addr, data, error_expected, unused);
  endtask
  task automatic apb_read(input [11:0] addr, input logic error_expected, output logic [31:0] data);
    apb_transfer(0, addr, 0, error_expected, data);
  endtask
  task automatic stage_frame(input integer id, input integer dlc, input logic fd,
    input logic brs, input integer tag);
    integer k;
    begin
      apb_write(12'h010, 32'(id), 0);
      apb_write(12'h014, (32'(brs)<<5) | (32'(fd)<<4) | 32'(dlc), 0);
      for (k = 0; k < (payload_length(dlc)+3)/4; k = k+1)
        apb_write(12'(12'h040 + k*4), pattern_word(tag,k), 0);
    end
  endtask
  task automatic expect_frame(input integer id, input integer dlc, input logic fd,
    input logic brs, input integer tag);
    begin
      rExpectedTx[exp_tail] = {11'(id),brs,fd,4'(dlc),expected_payload(tag,dlc)};
      exp_tail = exp_tail + 1;
    end
  endtask
  task automatic enqueue_frame(input integer id, input integer dlc, input logic fd,
    input logic brs, input integer tag);
    begin
      stage_frame(id,dlc,fd,brs,tag);
      expect_frame(id,dlc,fd,brs,tag);
      apb_write(12'h018,1,0);
    end
  endtask
  task automatic drain_tx;
    integer timeout_count;
    begin
      timeout_count = 0;
      while (exp_head != exp_tail || dut.u_tx_ctrl.rCurState != 0 || !dut.wTxEmpty) begin
        tick(1);
        timeout_count = timeout_count + 1;
        if (timeout_count > 5000) $fatal(1,"TX drain timeout");
      end
      tick(2);
    end
  endtask
  task automatic inject_rx(input integer id, input integer dlc, input integer tag);
    begin
      @(negedge iPclk);
      iCanRxId = 11'(id); iCanRxDlc = 4'(dlc); iCanRxFd = 1; iCanRxBrs = 1;
      iCanRxData = expected_payload(tag,dlc); iCanRxValid = 1;
      @(negedge iPclk); iCanRxValid = 0;
    end
  endtask
  task automatic read_rx(input integer id, input integer dlc, input integer tag);
    logic [31:0] value;
    logic [511:0] payload;
    integer k;
    begin
      payload = expected_payload(tag,dlc);
      apb_read(12'h020,0,value); check(value == 32'(id),"RX frame order / ID");
      apb_read(12'h024,0,value); check(value == (32'h30 | 32'(dlc)),"RX metadata");
      for (k=0;k<16;k=k+1) begin
        apb_read(12'(12'h080+k*4),0,value);
        check(value === payload[k*32 +: 32],"RX payload word");
      end
      // Reads never remove a frame; only RX_POP advances the head.
      apb_read(12'h020,0,value); check(value == 32'(id),"RX head stable until POP");
      apb_write(12'h01c,1,0);
    end
  endtask

  always @(posedge iPclk) begin
    if (!iPresetN) begin
      exp_head = 0;
      rStalled = 0;
    end
    else begin
      check(dut.wTxCount <= TX_DEPTH && dut.wRxCount <= RX_DEPTH,"FIFO count bounds");
      if (rStalled) begin
        check(oCanTxValid,"valid held while stalled");
        check({oCanTxId,oCanTxBrs,oCanTxFd,oCanTxDlc,oCanTxData} === rStalledFrame,"frame held while stalled");
      end
      if (oCanTxValid && iCanTxReady) begin
        check(exp_head < exp_tail,"no unexpected TX request");
        check({oCanTxId,oCanTxBrs,oCanTxFd,oCanTxDlc,oCanTxData} === rExpectedTx[exp_head],"TX scoreboard exact frame");
        exp_head = exp_head + 1;
        accepted_total = accepted_total + 1;
      end
      rStalled = oCanTxValid && !iCanTxReady;
      rStalledFrame = {oCanTxId,oCanTxBrs,oCanTxFd,oCanTxDlc,oCanTxData};
    end
  end

  initial begin
    if (!$value$plusargs("VCD=%s",rVcdPath)) rVcdPath = "results/bridge.vcd";
    `ifndef XSIM
    $dumpfile(rVcdPath);
    $dumpvars(0,tb_apb_can_bridge);
    `endif
    if (!$value$plusargs("SEED=%d",seed)) seed = 20261009;
    random_state = seed;
    reset_dut();

    start_case("reset and register defaults");
    apb_read(12'h000,0,rReadValue); check(rReadValue==32'h0001_0000,"version");
    apb_read(12'h004,0,rReadValue); check(rReadValue==32'h0000_000a,"empty defaults");
    check(!oIrq && !oCanTxValid,"reset outputs");

    start_case("illegal addresses, directions, alignment and reserved bits");
    apb_write(12'h000,1,1); apb_write(12'h004,1,1);
    apb_write(12'h010,32'h800,1); apb_write(12'h014,32'h40,1);
    apb_write(12'h008,32'h10,1); apb_write(12'h00c,32'h10,1);
    apb_write(12'h041,32'hffff_ffff,1); apb_read(12'hffc,1,rReadValue);
    apb_read(12'h018,1,rReadValue); apb_read(12'h01c,1,rReadValue);
    apb_read(12'h020,1,rReadValue); apb_read(12'h080,1,rReadValue);
    apb_write(12'h01c,1,1); apb_write(12'h018,0,1);
    apb_read(12'h040,0,rReadValue); check(rReadValue==0,"error write is atomic");

    start_case("SETUP-only abort has no side effect");
    @(negedge iPclk); iPsel=1; iPenable=0; iPwrite=1; iPaddr=12'h010; iPwdata=32'h555;
    tick(2);
    @(negedge iPclk); iPsel=0;
    apb_read(12'h010,0,rReadValue); check(rReadValue==0,"SETUP does not write");

    start_case("back-to-back APB transfers with PSEL held high");
    @(negedge iPclk); iPsel=1; iPenable=0; iPwrite=1; iPaddr=12'h010; iPwdata=32'h123;
    @(negedge iPclk); iPenable=1;
    @(posedge iPclk); check(!oPslverr,"back-to-back write 1");
    @(negedge iPclk); iPenable=0; iPaddr=12'h014; iPwdata=32'h30;
    @(negedge iPclk); iPenable=1;
    @(posedge iPclk); check(!oPslverr,"back-to-back write 2");
    @(negedge iPclk); iPsel=0; iPenable=0;
    apb_read(12'h010,0,rReadValue); check(rReadValue==32'h123,"first write retained");
    apb_read(12'h014,0,rReadValue); check(rReadValue==32'h30,"second write retained");

    start_case("incomplete payload and invalid Classic CAN format rejected");
    apb_write(12'h014,32'h3f,0); apb_write(12'h018,1,1);
    stage_frame(1,9,0,0,1); apb_write(12'h018,1,1);
    stage_frame(1,0,0,1,1); apb_write(12'h018,1,1);
    reset_dut();

    start_case("all FD DLC values, partial word zero padding, fresh word tracking");
    @(negedge iPclk); rCoreAllow=1;
    for (idx=0;idx<16;idx=idx+1) begin
      enqueue_frame(32'h100+idx,idx,1,1,idx);
      drain_tx();
      if (idx>0) apb_write(12'h018,1,1);
    end

    start_case("Classic CAN data frames 0 through 8 bytes");
    for (idx=0;idx<=8;idx=idx+1) begin
      enqueue_frame(32'h200+idx,idx,0,0,idx+20);
      drain_tx();
    end

    start_case("CAN backpressure and staging-buffer isolation");
    @(negedge iPclk); rCoreAllow=0;
    enqueue_frame(32'h321,15,1,1,44);
    stage_frame(32'h456,8,1,0,55);
    tick(12);
    @(negedge iPclk); rCoreAllow=1;
    drain_tx();

    start_case("TX full reject and simultaneous full FIFO push/pop");
    reset_dut();
    for (idx=0;idx<TX_DEPTH;idx=idx+1) enqueue_frame(32'h100+idx,1,1,0,idx);
    stage_frame(32'h600,1,1,0,66);
    apb_write(12'h018,1,1);
    check(dut.wTxCount==TX_DEPTH,"full write preserves count");
    expect_frame(32'h600,1,1,0,66);
    @(negedge iPclk); iPsel=1; iPenable=0; iPwrite=1; iPaddr=12'h018; iPwdata=1;
    @(negedge iPclk); iPenable=1; rCoreAllow=1;
    #1; check(!oPslverr,"full FIFO accepts replacement on pop edge");
    @(posedge iPclk); #1; check(dut.wTxCount==TX_DEPTH,"simultaneous TX count unchanged");
    @(negedge iPclk); iPsel=0; iPenable=0;
    drain_tx();

    start_case("RX all FD lengths, stable head and explicit POP");
    for (idx=0;idx<16;idx=idx+1) begin
      inject_rx(32'h400+idx,idx,idx+100);
      read_rx(32'h400+idx,idx,idx+100);
    end
    apb_write(12'h01c,1,1);

    start_case("RX overflow drops newest and preserves queued frames");
    reset_dut();
    for (idx=0;idx<RX_DEPTH;idx=idx+1) inject_rx(32'h300+idx,15,idx);
    inject_rx(32'h777,15,77);
    apb_read(12'h00c,0,rReadValue); check(rReadValue[3],"overflow sticky");
    check(!oIrq,"IRQ masked by default");
    apb_write(12'h008,8,0); check(oIrq,"pending event asserts when unmasked");
    apb_write(12'h00c,8,0); check(!oIrq,"W1C overflow");
    for (idx=0;idx<RX_DEPTH;idx=idx+1) read_rx(32'h300+idx,15,idx);

    start_case("RX full simultaneous POP and arrival keeps new frame");
    for (idx=0;idx<RX_DEPTH;idx=idx+1) inject_rx(32'h500+idx,2,idx);
    @(negedge iPclk); iPsel=1; iPenable=0; iPwrite=1; iPaddr=12'h01c; iPwdata=1;
    @(negedge iPclk); iPenable=1; iCanRxValid=1; iCanRxId=11'h666; iCanRxDlc=2;
    iCanRxFd=1; iCanRxBrs=1; iCanRxData=expected_payload(66,2);
    #1; check(!oPslverr,"RX simultaneous pop accepted");
    @(posedge iPclk); #1; check(dut.wRxCount==RX_DEPTH,"RX full replacement count");
    @(negedge iPclk); iPsel=0; iPenable=0; iCanRxValid=0;
    apb_read(12'h00c,0,rReadValue); check(!rReadValue[3],"no false overflow on POP edge");
    for (idx=1;idx<RX_DEPTH;idx=idx+1) read_rx(32'h500+idx,2,idx);
    read_rx(32'h666,2,66);

    start_case("RX available is level-sensitive; empty POP plus arrival is rejected");
    apb_write(12'h008,1,0);
    @(negedge iPclk); iPsel=1; iPenable=0; iPwrite=1; iPaddr=12'h01c; iPwdata=1;
    @(negedge iPclk); iPenable=1; iCanRxValid=1; iCanRxId=11'h123; iCanRxDlc=0; iCanRxData=0;
    #1; check(oPslverr,"empty POP cannot consume just-arriving frame");
    @(posedge iPclk); #1; check(dut.wRxCount==1,"arrival retained on invalid POP");
    @(negedge iPclk); iPsel=0; iPenable=0; iCanRxValid=0;
    check(oIrq,"RX available IRQ");
    apb_write(12'h00c,1,0); check(oIrq,"W1C cannot clear level source");
    read_rx(32'h123,0,0); check(!oIrq,"POP clears RX level IRQ");

    start_case("hardware event wins over simultaneous W1C");
    for (idx=0;idx<RX_DEPTH;idx=idx+1) inject_rx(idx,0,0);
    @(negedge iPclk); iPsel=1; iPenable=0; iPwrite=1; iPaddr=12'h00c; iPwdata=8;
    @(negedge iPclk); iPenable=1; iCanRxValid=1;
    @(negedge iPclk); iPsel=0; iPenable=0; iCanRxValid=0;
    apb_read(12'h00c,0,rReadValue); check(rReadValue[3],"event beats W1C");

    start_case("TX success/error interrupts and stray completion ignored");
    reset_dut();
    @(negedge iPclk); rInjectDone=1;
    @(negedge iPclk); rInjectDone=0;
    apb_read(12'h00c,0,rReadValue); check(rReadValue==0,"stray done ignored");
    apb_write(12'h008,6,0);
    @(negedge iPclk); rCoreAllow=1; rCoreFail=1;
    enqueue_frame(1,8,1,0,1); drain_tx();
    apb_read(12'h00c,0,rReadValue); check(rReadValue==4 && oIrq,"TX error IRQ");
    apb_write(12'h00c,4,0); check(!oIrq,"TX error W1C");
    @(negedge iPclk); rCoreFail=0;
    enqueue_frame(2,8,1,0,2); drain_tx();
    apb_read(12'h00c,0,rReadValue); check(rReadValue==2 && oIrq,"TX success IRQ");
    apb_write(12'h00c,2,0); check(!oIrq,"TX success W1C");

    start_case("completion on acceptance edge");
    @(negedge iPclk); rCoreAllow=0;
    enqueue_frame(3,0,1,0,0);
    @(negedge iPclk); rCoreAllow=1; rInjectDone=1;
    @(posedge iPclk); #1; check(dut.u_tx_ctrl.rCurState==0,"immediate completion returns IDLE");
    @(negedge iPclk); rInjectDone=0;
    drain_tx(); tick(12); // Later model completion must be ignored while idle.

    start_case("reset flushes queued RX and in-flight TX");
    @(negedge iPclk); rCoreLatency=100;
    enqueue_frame(4,15,1,1,4);
    inject_rx(4,15,4);
    check(dut.u_tx_ctrl.rCurState==2,"TX is outstanding before reset");
    reset_dut();
    apb_read(12'h004,0,rReadValue); check(rReadValue==10,"reset flushes FIFOs and FSM");
    apb_read(12'h00c,0,rReadValue); check(rReadValue==0,"reset clears interrupts");

    start_case("reset during SEND cancels a stalled unaccepted frame");
    enqueue_frame(5,8,1,1,5);
    tick(3);
    check(oCanTxValid && !iCanTxReady,"request stalled before reset");
    reset_dut();
    check(!oCanTxValid && dut.wTxEmpty,"stalled request flushed by reset");
    @(negedge iPclk); rCoreAllow=1;
    tick(12);
    check(exp_head==0,"no stale request after reset");

    start_case("RX invalid writes and invalid POP preserve the unread frame");
    inject_rx(6,7,96);
    apb_write(12'h020,32'h777,1);
    apb_write(12'h024,32'h3f,1);
    apb_write(12'h080,32'hffff_ffff,1);
    apb_write(12'h01c,0,1);
    read_rx(6,7,96);

    start_case("completion without ready cannot consume a stalled request");
    @(negedge iPclk); rCoreAllow=0;
    apb_write(12'h00c,14,0);
    enqueue_frame(7,0,1,0,0);
    @(negedge iPclk); rInjectDone=1;
    tick(1);
    check(oCanTxValid && dut.wTxCount==1,"done without acceptance leaves frame pending");
    @(negedge iPclk); rInjectDone=0;
    apb_read(12'h00c,0,rReadValue);
    check(rReadValue==0,"unaccepted completion does not set IRQ status");
    @(negedge iPclk); rCoreAllow=1;
    drain_tx();

    start_case("seeded concurrent TX/RX, stalls, errors and wraparound");
    @(negedge iPclk); rCoreAllow=1;
    fork
      begin
        for (idx=0;idx<80;idx=idx+1) begin
          random_state = random_state ^ (random_state << 13);
          random_state = random_state ^ (random_state >> 17);
          random_state = random_state ^ (random_state << 5);
          random_value = random_state & 32'h7fff_ffff;
          @(negedge iPclk);
          rCoreLatency = 8'(1 + random_value%25);
          rCoreFail = (random_value%7==0);
          rCoreAllow = 0;
          enqueue_frame(idx,random_value%16,1,1,idx+200);
          tick(1+random_value%8);
          @(negedge iPclk); rCoreAllow=1;
          drain_tx();
        end
      end
      begin
        for (jdx=0;jdx<120;jdx=jdx+1) begin
          tick(13);
          inject_rx(jdx,jdx%16,jdx+300);
        end
      end
    join
    check(exp_head==exp_tail,"all expected TX frames accepted");
    check(dut.wRxCount==RX_DEPTH,"concurrent RX filled FIFO");
    for (idx=0;idx<RX_DEPTH;idx=idx+1) read_rx(idx,idx%16,idx+300);
    apb_read(12'h00c,0,rReadValue); check(rReadValue[3],"concurrent overflow detected");

    $display("PASS bridge: cases=%0d checks=%0d accepted=%0d tx_depth=%0d rx_depth=%0d seed=%0d",
      cases,checks,accepted_total,TX_DEPTH,RX_DEPTH,seed);
    $finish;
  end
  initial begin
    #5000000;
    $fatal(1,"global watchdog timeout");
  end
endmodule

`default_nettype wire
