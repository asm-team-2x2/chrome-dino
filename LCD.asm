; sends a command to the LCDs data pins
CMD	MACRO	CMD_CODE
	SETB	E
	MOV	D, CMD_CODE
	CLR	E
ENDM

	ORG	0
	JMP	START

RS	BIT	P2.2
RW	BIT	P2.1
E	BIT	P2.0
D	EQU	P1

CHARS:	DB	00H, 07H, 07H, 0CH, 1EH, 1CH, 14H, 12H, 04H, 04H, 05H, 17H, 1EH, 0EH, 06H, 06H, 0H, 10H, 1CH, 0FH, 0CH, 08H, 00H, 00H

START:
	MOV	D, #0		; clear data pins
	CLR	RW		; write mode for display
	CLR	RS		; select command register
	CMD	#01H		; clear display
	CMD	#02H		; cursor home
	CMD	#0CH		; display on, cursor off
	CMD	#1EH		; cursor/display shift
	cmd #38h

; load custom characters
	CMD	#40H		; set CGRAM address
	SETB	RS		; select data register
	MOV	DPTR, #CHARS
	MOV	R0, #0
LOOP_0:
	MOV	A, R0
	INC	R0
	MOVC	A, @A+DPTR
	CMD	A
	CJNE	R0, #24, LOOP_0

; test print characters
	CLR	RS		; select command register
	CMD	#0c1H		; set DDRAM address (cursor to beginning of first line)
	SETB	RS		; select data register
	CMD	#0
	CMD	#1
	CMD	#2
	SJMP	END

END:	SJMP	END