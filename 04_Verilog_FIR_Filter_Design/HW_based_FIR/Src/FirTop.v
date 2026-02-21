module FirTop (
	// Clock & reset
	input             iClk12M,            // Rising edge
	input             iRsn,               // Sync. & low reset
	input             iEnSample600k,      // Rising edge
	// Update flag
	input             iCoeffUpdateFlag,   // 1'b1: Write, 1'b0: Accmulation
	// Input for SP-SRAM 
	input             iCsnRam,
	input             iWrnRam,
	input      [ 5:0] iAddrRam,
	input signed [15:0] iWrDtRam,
	input      [ 5:0] iNumOfCoeff,

	input signed [ 2:0] iFirIn,

	output signed [15:0] oFirOut
);

wire [15:0] wRdDtRam0;
wire [15:0] wRdDtRam1;
wire [15:0] wRdDtRam2;
wire [15:0] wRdDtRam3;
wire signed [ 2:0] wDelay0, wDelay1, wDelay2, wDelay3, wDelay4, wDelay5;
wire signed [ 2:0] wDelay6, wDelay7, wDelay8, wDelay9, wDelay10;
wire signed [ 2:0] wDelay11, wDelay12, wDelay13, wDelay14, wDelay15;
wire signed [ 2:0] wDelay16, wDelay17, wDelay18, wDelay19, wDelay20;
wire signed [ 2:0] wDelay21, wDelay22, wDelay23, wDelay24, wDelay25;
wire signed [ 2:0] wDelay26, wDelay27, wDelay28, wDelay29, wDelay30;
wire signed [ 2:0] wDelay31, wDelay32, wDelay33, wDelay34, wDelay35;
wire signed [ 2:0] wDelay36, wDelay37, wDelay38, wDelay39;

wire signed [15:0] oMul_0,oMul_1,oMul_2,oMul_3,oMul_4,oMul_5,oMul_6,oMul_7,oMul_8,oMul_9;
wire signed [15:0] oMul_10,oMul_11,oMul_12,oMul_13,oMul_14,oMul_15,oMul_16,oMul_17,oMul_18,oMul_19;
wire signed [15:0] oMul_20,oMul_21,oMul_22,oMul_23,oMul_24,oMul_25,oMul_26,oMul_27,oMul_28,oMul_29;
wire signed [15:0] oMul_30,oMul_31,oMul_32,oMul_33,oMul_34,oMul_35,oMul_36,oMul_37,oMul_38,oMul_39;

wire signed [15:0] wAccu0,wAccu1,wAccu2,wAccu3;

wire        wCsnRam0, wCsnRam1, wCsnRam2, wCsnRam3;
wire        wWrnRam0, wWrnRam1, wWrnRam2, wWrnRam3;
wire [ 3:0] wAddRam0,wAddRam1,wAddRam2,wAddRam3;
wire [15:0] wWtDtRam0,wWtDtRam1,wWtDtRam2,wWtDtRam3;
wire        wEnMul0,wEnMul1,wEnMul2,wEnMul3;
wire        wEnAdd0,wEnAdd1,wEnAdd2,wEnAdd3;
wire        wEnAcc0,wEnAcc1,wEnAcc2,wEnAcc3;
wire        wEnDelay;


SpSram #(
	// Parameter
	.SRAM_DEPTH      (10),
	.DATA_WIDTH      (16)
	) SpSram0 (

	// Clock & reset
	.iClk            (iClk12M),
	.iRsn            (iRsn),


	// SP-SRAM interface
	.iCsn            (wCsnRam0),
	.iWrn            (wWrnRam0),
	.iAddr           (wAddRam0),

	.iWrDt           (wWtDtRam0),
	.oRdDt           (wRdDtRam0)
);
SpSram #(
	// Parameter
	.SRAM_DEPTH      (10),
	.DATA_WIDTH      (16)
	) SpSram1 (

	// Clock & reset
	.iClk            (iClk12M),
	.iRsn            (iRsn),


	// SP-SRAM interface
	.iCsn            (wCsnRam1),
	.iWrn            (wWrnRam1),
	.iAddr           (wAddRam1),

	.iWrDt           (wWtDtRam1),
	.oRdDt           (wRdDtRam1)
);
SpSram #(
	// Parameter
	.SRAM_DEPTH      (10),
	.DATA_WIDTH      (16)
	) SpSram2 (

	// Clock & reset
	.iClk            (iClk12M),
	.iRsn            (iRsn),


	// SP-SRAM interface
	.iCsn            (wCsnRam2),
	.iWrn            (wWrnRam2),
	.iAddr           (wAddRam2),

	.iWrDt           (wWtDtRam2),
	.oRdDt           (wRdDtRam2)
);
SpSram #(
	// Parameter
	.SRAM_DEPTH      (10),
	.DATA_WIDTH      (16)
	) SpSram3 (

	// Clock & reset
	.iClk            (iClk12M),
	.iRsn            (iRsn),


	// SP-SRAM interface
	.iCsn            (wCsnRam3),
	.iWrn            (wWrnRam3),
	.iAddr           (wAddRam3),

	.iWrDt           (wWtDtRam3),
	.oRdDt           (wRdDtRam3)
);

controller controller(
	.iClk12M(iClk12M), 
	.iEnSample600k(iEnSample600k), 
	.iRsn(iRsn	),

	.iCoeffUpdateFlag(iCoeffUpdateFlag), 
	.iCsnRam(iCsnRam), 
	.iWrnRam(iWrnRam),
	.iAddrRam(iAddrRam), 
	.iWrDtRam(iWrDtRam), 
	.iNumOfCoeff(iNumOfCoeff),

	.oCsnRam_0(wCsnRam0), .oCsnRam_1(wCsnRam1), .oCsnRam_2(wCsnRam2), .oCsnRam_3(wCsnRam3),
	.oWrnRam_0(wWrnRam0), .oWrnRam_1(wWrnRam1), .oWrnRam_2(wWrnRam2), .oWrnRam_3(wWrnRam3),
	.oAddrRam_0(wAddRam0), .oAddrRam_1(wAddRam1), .oAddrRam_2(wAddRam2), .oAddrRam_3(wAddRam3),
	.oWtDtRam_0(wWtDtRam0), .oWtDtRam_1(wWtDtRam1), .oWtDtRam_2(wWtDtRam2), .oWtDtRam_3(wWtDtRam3),

	.oEnMul_0(wEnMul0), .oEnMul_1(wEnMul1), .oEnMul_2(wEnMul2), .oEnMul_3(wEnMul3),
	.oEnAdd_0(wEnAdd0), .oEnAdd_1(wEnAdd1), .oEnAdd_2(wEnAdd2), .oEnAdd_3(wEnAdd3),
	.oEnAcc_0(wEnAcc0), .oEnAcc_1(wEnAcc1), .oEnAcc_2(wEnAcc2), .oEnAcc_3(wEnAcc3),

	.oEnDelay(wEnDelay)
);

delayChain delaychain0 (
	.iClk12M(iClk12M),
	.iRsn(iRsn),
	.iEnDelay(wEnDelay),
	.iEnSample600k(iEnSample600k),
	.iFirIn(iFirIn),
	.wDelay0(wDelay0), .wDelay1(wDelay1), .wDelay2(wDelay2), .wDelay3(wDelay3), .wDelay4(wDelay4), .wDelay5(wDelay5),
	.wDelay6(wDelay6), .wDelay7(wDelay7), .wDelay8(wDelay8), .wDelay9(wDelay9), .wDelay10(wDelay10),
	.wDelay11(wDelay11), .wDelay12(wDelay12), .wDelay13(wDelay13), .wDelay14(wDelay14), .wDelay15(wDelay15),
	.wDelay16(wDelay16), .wDelay17(wDelay17), .wDelay18(wDelay18), .wDelay19(wDelay19), .wDelay20(wDelay20),
	.wDelay21(wDelay21), .wDelay22(wDelay22), .wDelay23(wDelay23), .wDelay24(wDelay24), .wDelay25(wDelay25),
	.wDelay26(wDelay26), .wDelay27(wDelay27), .wDelay28(wDelay28), .wDelay29(wDelay29), .wDelay30(wDelay30),
	.wDelay31(wDelay31), .wDelay32(wDelay32), .wDelay33(wDelay33), .wDelay34(wDelay34), .wDelay35(wDelay35),
	.wDelay36(wDelay36), .wDelay37(wDelay37), .wDelay38(wDelay38), .wDelay39(wDelay39)
);

Multiplier multi0(///000000000000
	.iCoeff(wRdDtRam0),

	.iDelay_0(wDelay0),
	.iDelay_1(wDelay1),
	.iDelay_2(wDelay2),
	.iDelay_3(wDelay3),
	.iDelay_4(wDelay4),
	.iDelay_5(wDelay5),
	.iDelay_6(wDelay6),
	.iDelay_7(wDelay7),
	.iDelay_8(wDelay8),
	.iDelay_9(wDelay9),


	.iEnMul(wEnMul0),
	.iClk12M(iClk12M),
	.iRsn(iRsn),

	.oMul_0(oMul_0),
	.oMul_1(oMul_1),
	.oMul_2(oMul_2),
	.oMul_3(oMul_3),
	.oMul_4(oMul_4),
	.oMul_5(oMul_5),
	.oMul_6(oMul_6),
	.oMul_7(oMul_7),
	.oMul_8(oMul_8),
	.oMul_9(oMul_9)
);
Accumulator accumul0(
	.iClk12M(iClk12M),
	.iMul_0(oMul_0),
	.iMul_1(oMul_1),
	.iMul_2(oMul_2),
	.iMul_3(oMul_3),
	.iMul_4(oMul_4),
	.iMul_5(oMul_5),
	.iMul_6(oMul_6),
	.iMul_7(oMul_7),
	.iMul_8(oMul_8),
	.iMul_9(oMul_9),
	.iEnMul(wEnMul0),
	.iEnAdd(wEnAdd0),
	.iEnAcc(wEnAcc0),
	.oAccOut(wAccu0)
);

Multiplier multi1(////////////111111111111111111
	.iCoeff(wRdDtRam1),

	.iDelay_0(wDelay10),
	.iDelay_1(wDelay11),
	.iDelay_2(wDelay12),
	.iDelay_3(wDelay13),
	.iDelay_4(wDelay14),
	.iDelay_5(wDelay15),
	.iDelay_6(wDelay16),
	.iDelay_7(wDelay17),
	.iDelay_8(wDelay18),
	.iDelay_9(wDelay19),

	.iEnMul(wEnMul1),
	.iClk12M(iClk12M),
	.iRsn(iRsn),

	.oMul_0(oMul_10),
	.oMul_1(oMul_11),
	.oMul_2(oMul_12),
	.oMul_3(oMul_13),
	.oMul_4(oMul_14),
	.oMul_5(oMul_15),
	.oMul_6(oMul_16),
	.oMul_7(oMul_17),
	.oMul_8(oMul_18),
	.oMul_9(oMul_19)
);
Accumulator accumul1(
	.iClk12M(iClk12M),
	.iMul_0(oMul_10),
	.iMul_1(oMul_11),
	.iMul_2(oMul_12),
	.iMul_3(oMul_13),
	.iMul_4(oMul_14),
	.iMul_5(oMul_15),
	.iMul_6(oMul_16),
	.iMul_7(oMul_17),
	.iMul_8(oMul_18),
	.iMul_9(oMul_19),
	.iEnMul(wEnMul1),
	.iEnAdd(wEnAdd1),
	.iEnAcc(wEnAcc1),
	.oAccOut(wAccu1)
);

Multiplier multi2(//222222222222222222
	.iCoeff(wRdDtRam2),

	.iDelay_0(wDelay20),
	.iDelay_1(wDelay21),
	.iDelay_2(wDelay22),
	.iDelay_3(wDelay23),
	.iDelay_4(wDelay24),
	.iDelay_5(wDelay25),
	.iDelay_6(wDelay26),
	.iDelay_7(wDelay27),
	.iDelay_8(wDelay28),
	.iDelay_9(wDelay29),

	.iEnMul(wEnMul2),
	.iClk12M(iClk12M),
	.iRsn(iRsn),

	.oMul_0(oMul_20),
	.oMul_1(oMul_21),
	.oMul_2(oMul_22),
	.oMul_3(oMul_23),
	.oMul_4(oMul_24),
	.oMul_5(oMul_25),
	.oMul_6(oMul_26),
	.oMul_7(oMul_27),
	.oMul_8(oMul_28),
	.oMul_9(oMul_29)
);
Accumulator accumul2(
	.iClk12M(iClk12M),
	.iMul_0(oMul_20),
	.iMul_1(oMul_21),
	.iMul_2(oMul_22),
	.iMul_3(oMul_23),
	.iMul_4(oMul_24),
	.iMul_5(oMul_25),
	.iMul_6(oMul_26),
	.iMul_7(oMul_27),
	.iMul_8(oMul_28),
	.iMul_9(oMul_29),
	.iEnMul(wEnMul2),
	.iEnAdd(wEnAdd2),
	.iEnAcc(wEnAcc2),
	.oAccOut(wAccu2)
);

Multiplier multi3(//3333333333333
	.iCoeff(wRdDtRam3),

	.iDelay_0(wDelay30),
	.iDelay_1(wDelay31),
	.iDelay_2(wDelay32),
	.iDelay_3(wDelay33),
	.iDelay_4(wDelay34),
	.iDelay_5(wDelay35),
	.iDelay_6(wDelay36),
	.iDelay_7(wDelay37),
	.iDelay_8(wDelay38),
	.iDelay_9(wDelay39),

	.iEnMul(wEnMul3),
	.iClk12M(iClk12M),
	.iRsn(iRsn),

	.oMul_0(oMul_30),
	.oMul_1(oMul_31),
	.oMul_2(oMul_32),
	.oMul_3(oMul_33),
	.oMul_4(oMul_34),
	.oMul_5(oMul_35),
	.oMul_6(oMul_36),
	.oMul_7(oMul_37),
	.oMul_8(oMul_38),
	.oMul_9(oMul_39)
);
Accumulator accumul3(
	.iClk12M(iClk12M),
	.iMul_0(oMul_30),
	.iMul_1(oMul_31),
	.iMul_2(oMul_32),
	.iMul_3(oMul_33),
	.iMul_4(oMul_34),
	.iMul_5(oMul_35),
	.iMul_6(oMul_36),
	.iMul_7(oMul_37),
	.iMul_8(oMul_38),
	.iMul_9(oMul_39),
	.iEnMul(wEnMul3),
	.iEnAdd(wEnAdd3),
	.iEnAcc(wEnAcc3),
	.oAccOut(wAccu3)
);
Sum Sum(
	.iMac_1(wAccu0),
	.iMac_2(wAccu1),
	.iMac_3(wAccu2),
	.iMac_4(wAccu3),

	.iClk12M(iClk12M),
	.iRsn(iRsn),
	.iEnDelay(wEnDelay),
	.iEnSample600k(iEnSample600k), 

	.oFirOut(oFirOut)
);


endmodule