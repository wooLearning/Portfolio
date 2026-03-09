	AREA	CODE, READONLY, CODE
	ENTRY
	EXPORT	countRedRelAsm

	; int countRedRelAsm(uint8_t* origin, int size)
	;	r0 = baseAddress
	;	r1 = size
	; return: int (r0)
	;	r1 = ByteCnt
	;	r2 = WordCnt
	;	r3 = RedCnt
	;	r4 = masker
	;	r5-12 = data

countRedRelAsm
	STMFD	sp!, {r4-r12, lr}

	MOV		r2, r1, LSR #5		 ; r2 = size / 32
	SUB	 	r1, r1, r2, LSL #5	 ; r1 = size % 32
	MOV		r3, #0;

	; skip CNT_BLOCK_LOOP
	CMP		r2, #0
	BEQ		CNT_BYTE_LOOP

CNT_BLOCK_LOOP
	LDMIA		r0!, {r5-r12} ; info variable
	
	; ========= word_0 ==========
	; pixel 0
	MOV		r4, #128
	TST		r5, r4; masking if is 0 then <128
	ADDNE	r3,	r3,	#1; sum++; when Z bit not 1
	; pixel 1
	MOV		r4, r4, LSL #8
	TST		r5, r4
	ADDNE	r3, r3, #1
	; pixel 2
	MOV		r4, r4, LSL #8
	TST		r5, r4
	ADDNE	r3, r3, #1
	; pixel 3
	MOV		r4, r4, LSL #8
	TST		r5, r4
	ADDNE	r3, r3, #1

	; ========= word_1 ==========
	; pixel 0
	MOV		r4, #128
	TST		r6, r4; masking if is 0 then <128
	ADDNE	r3,	r3,	#1; sum++; when Z bit not 1
	; pixel 1
	MOV		r4, r4, LSL #8
	TST		r6, r4
	ADDNE	r3, r3, #1
	; pixel 2
	MOV		r4, r4, LSL #8
	TST		r6, r4
	ADDNE	r3, r3, #1
	; pixel 3
	MOV		r4, r4, LSL #8
	TST		r6, r4
	ADDNE	r3, r3, #1

	; ========= word_2 ==========
	; pixel 0
	MOV		r4, #128
	TST		r7, r4; masking if is 0 then <128
	ADDNE	r3,	r3,	#1; sum++; when Z bit not 1
	; pixel 1
	MOV		r4, r4, LSL #8
	TST		r7, r4
	ADDNE	r3, r3, #1
	; pixel 2
	MOV		r4, r4, LSL #8
	TST		r7, r4
	ADDNE	r3, r3, #1
	; pixel 3
	MOV		r4, r4, LSL #8
	TST		r7, r4
	ADDNE	r3, r3, #1

	; ========= word_3 ==========
	; pixel 0
	MOV		r4, #128
	TST		r8, r4; masking if is 0 then <128
	ADDNE	r3,	r3,	#1; sum++; when Z bit not 1
	; pixel 1
	MOV		r4, r4, LSL #8
	TST		r8, r4
	ADDNE	r3, r3, #1
	; pixel 2
	MOV		r4, r4, LSL #8
	TST		r8, r4
	ADDNE	r3, r3, #1
	; pixel 3
	MOV		r4, r4, LSL #8
	TST		r8, r4
	ADDNE	r3, r3, #1

	; ========= word_4 ==========
	; pixel 0
	MOV		r4, #128
	TST		r9, r4; masking if is 0 then <128
	ADDNE	r3,	r3,	#1; sum++; when Z bit not 1
	; pixel 1
	MOV		r4, r4, LSL #8
	TST		r9, r4
	ADDNE	r3, r3, #1
	; pixel 2
	MOV		r4, r4, LSL #8
	TST		r9, r4
	ADDNE	r3, r3, #1
	; pixel 3
	MOV		r4, r4, LSL #8
	TST		r9, r4
	ADDNE	r3, r3, #1

	; ========= word_5 ==========
	; pixel 0
	MOV		r4, #128
	TST		r10, r4; masking if is 0 then <128
	ADDNE	r3,	r3,	#1; sum++; when Z bit not 1
	; pixel 1
	MOV		r4, r4, LSL #8
	TST		r10, r4
	ADDNE	r3, r3, #1
	; pixel 2
	MOV		r4, r4, LSL #8
	TST		r10, r4
	ADDNE	r3, r3, #1
	; pixel 3
	MOV		r4, r4, LSL #8
	TST		r10, r4
	ADDNE	r3, r3, #1

	; ========= word_6 ==========
	; pixel 0
	MOV		r4, #128
	TST		r11, r4; masking if is 0 then <128
	ADDNE	r3,	r3,	#1; sum++; when Z bit not 1
	; pixel 1
	MOV		r4, r4, LSL #8
	TST		r11, r4
	ADDNE	r3, r3, #1
	; pixel 2
	MOV		r4, r4, LSL #8
	TST		r11, r4
	ADDNE	r3, r3, #1
	; pixel 3
	MOV		r4, r4, LSL #8
	TST		r11, r4
	ADDNE	r3, r3, #1

	; ========= word_7 ==========
	; pixel 0
	MOV		r4, #128
	TST		r12, r4; masking if is 0 then <128
	ADDNE	r3,	r3,	#1; sum++; when Z bit not 1
	; pixel 1
	MOV		r4, r4, LSL #8
	TST		r12, r4
	ADDNE	r3, r3, #1
	; pixel 2
	MOV		r4, r4, LSL #8
	TST		r12, r4
	ADDNE	r3, r3, #1
	; pixel 3
	MOV		r4, r4, LSL #8
	TST		r12, r4
	ADDNE	r3, r3, #1

	; check loop condition
	SUBS	r2, r2, #1
	BGT		CNT_BLOCK_LOOP

CNT_BYTE_LOOP
	; skip CNT_BYTE_LOOP_BODY
	CMP		r1, #0
	BEQ		EXIT

CNT_BYTE_LOOP_BODY
	LDRB	r5, [r0], #1
	CMP	 	r5, #128
	ADDGE	r3, r3, #1
	SUBS	r1, r1, #1
	BGT		CNT_BYTE_LOOP_BODY

EXIT
	MOV		r0, r3
	LDMFD	sp!, {r4-r12, pc}