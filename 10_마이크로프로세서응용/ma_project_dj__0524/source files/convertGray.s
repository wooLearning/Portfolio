	AREA	CODE, READONLY, CODE
	ENTRY
	EXPORT	convertGrayAsm

    ;   void convertGray(uint8_t* origin, uint16_t* toSave, int size) {
    ;   *toSave = 3 * (uint16_t)r + 6 * (uint16_t)g + (uint16_t)b
	;	r0 = baseAddress
	;	r1 = targetAddress
	;	r2 = maxCount
	;	r3 = converted
	;
	;	r4 = buf

convertGrayAsm
	STMFD sp!, {r4, lr}
CGA_L1
	; r3 = r * 3
	LDRB	r3, [r0], #1
	ADD		r3, r3, r3, LSL #1
	; r3 += g * 6
	LDRB	r4, [r0], #1
	ADD 	r4, r4, r4, LSL #1
	ADD 	r3, r3, r4, LSL #1
	; r3 += b
	LDRB	r4, [r0], #2
	ADD 	r3, r3, r4
	; [r1] = r3
	STRH	r3, [r1], #2

	SUBS	r2, r2, #1
	BGT		CGA_L1
	LDMFD sp!, {r4, pc}
	; BX lr;
	
END
