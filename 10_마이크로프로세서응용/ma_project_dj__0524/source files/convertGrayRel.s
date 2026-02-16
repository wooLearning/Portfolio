	AREA	CODE, READONLY, CODE
	ENTRY
	EXPORT	convertGrayRelAsm
	
	;	void convertGrayRelAsm(uint16_t* toSave, uint8_t* targetR, uint8_t* targetG, uint8_t* targetB, int size)
    ;   *toSave = 3 * (uint16_t)r + 6 * (uint16_t)g + (uint16_t)b
	;	r0 = toSave
	;	r1 = targetR
	;	r2 = targetG
	;	r3 = targetB
	;	r4 = size
	;	r5 = r
	;	r6 = g
	;	r7 = b
	;	r8 = buf1
	;	r9 = buf2
	;	r10 = targetLow
	;	r11 = targetHigh
	;	r12 = WordCnt

convertGrayRelAsm
    STMFD	sp!, {r4-r12, lr}
    LDR		r4, [sp, #40]		 ; r4 ← size

    MOV		r12, r4, LSR #2		 ; r12 = size / 4
	SUB	 	r4, r4, r12, LSL #2	 ; r2 = size % 4

	; skip GRAY_BLOCK_LOOP
    CMP   r12, #0
    BEQ   GRAY_BYTE_LOOP

GRAY_BLOCK_LOOP
    ; R, G, B block load (4 bytes each)
    LDR   r5, [r1], #4         ; r5 = R0 R1 R2 R3
    LDR   r6, [r2], #4         ; r6 = G0 G1 G2 G3
    LDR   r7, [r3], #4         ; r7 = B0 B1 B2 B3

    ; --- Pixel 0 ---
	AND   r8, r5, #0xFF
	ADD   r8, r8, r8, LSL #1         ; R × 3

	AND   r9, r6, #0xFF
	ADD   r9, r9, r9, LSL #1
	ADD   r8, r8, r9, LSL #1         ; G × 6

	AND   r9, r7, #0xFF
	ADD   r8, r8, r9                 ; gray0

    MOV   r10, r8        ; gray0

    ; --- Pixel 1 ---
	MOV   r8, r5, ROR #8
	AND   r8, r8, #0xFF
	ADD   r8, r8, r8, LSL #1         ; R × 3

	MOV   r9, r6, ROR #8
	AND   r9, r9, #0xFF
	ADD   r9, r9, r9, LSL #1
	ADD   r8, r8, r9, LSL #1         ; G × 6

	MOV   r9, r7, ROR #8
	AND   r9, r9, #0xFF
	ADD   r8, r8, r9                 ; gray1

	LSL   r8, r8, #16
	ORR   r10, r10, r8               ; gray1<<16 | gray0

    ; --- Pixel 2 ---
	MOV   r8, r5, ROR #16
	AND   r8, r8, #0xFF
	ADD   r8, r8, r8, LSL #1         ; R × 3

	MOV   r9, r6, ROR #16
	AND   r9, r9, #0xFF
	ADD   r9, r9, r9, LSL #1
	ADD   r8, r8, r9, LSL #1         ; G × 6

	MOV   r9, r7, ROR #16
	AND   r9, r9, #0xFF
	ADD   r8, r8, r9                 ; gray2

    MOV   r11, r8        ; gray2

    ; --- Pixel 3 ---
	MOV   r8, r5, ROR #24
	AND   r8, r8, #0xFF
	ADD   r8, r8, r8, LSL #1         ; R × 3

	MOV   r9, r6, ROR #24
	AND   r9, r9, #0xFF
	ADD   r9, r9, r9, LSL #1
	ADD   r8, r8, r9, LSL #1         ; G × 6

	MOV   r9, r7, ROR #24
	AND   r9, r9, #0xFF
	ADD   r8, r8, r9                 ; gray3

	LSL   r8, r8, #16
	ORR   r11, r11, r8               ; gray3<<16 | gray2

    STMIA r0!, {r10, r11}      ; 저장: gray0~3

    SUBS  r12, r12, #1
    BGT   GRAY_BLOCK_LOOP

GRAY_BYTE_LOOP
    CMP   r4, #0
    BEQ   GRAY_EXIT

GRAY_BYTE_LOOP_BODY
    LDRB  r5, [r1], #1
    LDRB  r6, [r2], #1
    LDRB  r7, [r3], #1
    MOV   r8, r5
    ADD   r8, r8, r5, LSL #1
    MOV   r9, r6, LSL #1
    ADD   r9, r9, r6, LSL #2
    ADD   r8, r8, r9
    ADD   r8, r8, r7
    STRH  r8, [r0], #2
    SUBS  r12, r12, #1
    BGT   GRAY_BYTE_LOOP_BODY

GRAY_EXIT
    LDMFD sp!, {r4-r12, pc}
