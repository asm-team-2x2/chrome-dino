; ========== pins ==========
D	EQU	P1
E	BIT	P2.0
RW	BIT	P2.1
RS	BIT	P2.2

; ========== variables ==========
JUMP_DURATION	EQU	20H

; ========== macros ==========
; sends a command to the LCDs data pins
CMD	MACRO	CMD_CODE
	SETB	E
	MOV	D, CMD_CODE
	CLR	E
ENDM

; ========== code ==========
	ORG	0H
	JMP	INIT

	ORG	3H
	JMP	JUMP

CHARS:	DB	00H, 07H, 07H, 0CH, 1EH, 1CH, 14H, 12H, 04H, 04H, 05H, 17H, 1EH, 0EH, 06H, 06H, 0H, 10H, 1CH, 0FH, 0CH, 08H, 00H, 00H	; custom characters to display game entities

INIT:
; initialize external interrupt
	SETB	IT0		; trigger on falling edge
	SETB	EX0		; enable external interrupt
	SETB	EA		; enable interrupts

; initialize LCD display
	MOV	D, #0		; clear data pins
	CLR	RW		; write mode for display
	CLR	RS		; select command register
	CMD	#01H		; clear display
	CMD	#02H		; cursor home
	CMD	#0CH		; display on, cursor off
	CMD	#1EH		; cursor/display shift

; load custom characters
	CMD	#40H		; set CGRAM address
	SETB	RS		; select data register
	MOV	DPTR, #CHARS
	MOV	R0, #0
load_characters:
	MOV	A, R0
	INC	R0
	MOVC	A, @A+DPTR
	CMD	A
	CJNE	R0, #24, load_characters

	JMP	GAME_LOOP	; start game

JUMP:				; interrupt service routine for external interrupt
	SETB	C		; move dino in the air
	MOV	JUMP_DURATION, #3	; set number of cycles for dino to stay in the air
	RETI

GAME_LOOP:
; update dino position
	MOV	A, JUMP_DURATION
	JNZ	DINO_IN_AIR	; dino is in the air if duration != 0
	JMP	DINO_NO_CHANGE	; do nothing if dino is on the floor

DINO_IN_AIR:
	DJNZ	JUMP_DURATION, DINO_NO_CHANGE	; decrement duration, do nothing if still in the air
	CLR	C		; move dino to the floor if duration was set to 0

DINO_NO_CHANGE:
	JMP	GAME_LOOP

	END