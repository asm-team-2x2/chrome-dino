; very basic demonstration example for hd44780 simulator
; * click on "virtual hw" in the main menu,
; * choose "open",
; * change filter to vh component,
; * open "lcd.vhc",
; * press f2,
; * press f6,
; * enjoy ... :-)
; * press f2 to end.
;
; note: simulated delays are skipped in this example.
;
	ORG	0
	JMP	init

RS	BIT	P3.0
RW	BIT	P3.1
E	BIT	P3.2
D	EQU	P1

CMD	MACRO	CMD_CODE
	SETB	E
	MOV	D, CMD_CODE
	CLR	E
ENDM

DINO:	DB	00h, 07h, 07h, 0ch, 1eh, 1ch, 14h, 12h, 0ffh

init:	MOV	D, #0
	CLR	RW		; write mode for display
	CLR	RS		; command mode
	CMD	#01H		; clear display
	;CMD	#02H		; cursor home
	;CMD	#06H		; entry mode set
	CMD	#0CH		; display on, cursor off
	CMD	#00011110B	; cursor/display shift
	;cmd	#00111100b	; function set
	;cmd	#10000001b	; set ddram address

	; print the dino
	cmd	#38h		; two lines and 5x7 matrix
	cmd	#80h		; DDRAM address 0 (cursor to beginning of first line)
	cmd	#40h		; CGRAM address 0
	setb	rs		; data mode
	mov	dptr, #dino
	mov	r0, #0
print:
	mov	a, r0
	inc	r0
	movc	a, @a+dptr
	cmd	a
	cjne	a, #11111111b, print
	cmd	#1h
	end

	; print the string ...
;	SETB	RS
;	MOV	R0, #0
;PRINT:	MOV	A, R0
;	INC	R0
;	MOVC	A, @A+DPTR
;	CMD	A
;	CJNE	A, #0, PRINT
;	SJMP	MAIN

