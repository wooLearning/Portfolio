	AREA	CODE, READONLY, CODE
	ENTRY
	EXPORT	convertReverseRelAsm

	;	void convertReverseRelAsm(uint8_t* origin, uint8_t* toSave, int size)
	;	r0 = origin
	;	r1 = toSave
	;	r2 = size
	;
	;	r3 = size / 32; L1
	;	r2 = mod(size % 32); L2

convertReverseRelAsm
	STMFD   sp!, {r4-r12, lr}

	MOV	 	r3, r2, LSR #5		 ; r3 = size / 32
	SUB	 	r2, r2, r3, LSL #5	 ; r2 = size % 32

	; skip REV_BLOCK_LOOP
	CMP		r3, #0
	BEQ		REV_BYTE_LOOP

REV_BLOCK_LOOP
	; invert block
	LDMIA	r0!, {r5-r12}
	MVN		r5, r5
	MVN		r6, r6
	MVN		r7, r7
	MVN		r8, r8
	MVN		r9, r9
	MVN		r10, r10
	MVN		r11, r11
	MVN		r12, r12
	STMIA	r1!, {r5-r12}

	; check loop condition
	SUBS	r3, r3, #1
	BGT		REV_BLOCK_LOOP

REV_BYTE_LOOP
	; skip REV_BYTE_LOOP_BODY
	CMP		r2, #0
	BEQ		REV_EXIT

REV_BYTE_LOOP_BODY
	LDRB	r3, [r0], #1
	MVN		r3, r3
	STRB	r3, [r1], #1
	SUBS	r2, r2, #1
	BGT		REV_BYTE_LOOP_BODY

REV_EXIT
	LDMFD	sp!, {r4-r12, pc}