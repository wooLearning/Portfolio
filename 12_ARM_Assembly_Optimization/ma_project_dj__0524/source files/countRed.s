	AREA	CODE, READONLY, CODE
	ENTRY
	EXPORT	countRedAsm

	; int countRedAsm(unsigned char* baseAddress, int maxCount)
	;	r0 = baseAddress
	;	r1 = maxCount
	; return: int (r0)
	;	r2 = cnt
	;	r3 = buf

countRedAsm
	MOV		r2, #0
CRA_L1
	LDRB	r3, [r0], #4
	CMP	 	r3, #128
	ADDGE	r2, r2, #1
	SUBS	r1, r1, #1
	BGT		CRA_L1
	MOV		r0, r2
	BX lr
	
END
	