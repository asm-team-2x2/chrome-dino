; ========== pins ==========
D	EQU	P1
E	BIT	P2.0
RW	BIT	P2.1
RS	BIT	P2.2

; ========== variables ==========
JUMP_DURATION	DATA	20H
FLOOR_L	DATA	21H
FLOOR_R	DATA	22H

; ========== constants ==========
SPACE	EQU	20H
DINO	EQU	0H
CACTUS	EQU	1H
BIRD	EQU	2H

; ========== macros ==========
; sends a command to the LCDs data pins
CMD	MACRO	CMD_CODE
	SETB	E
	MOV	D, CMD_CODE
	CLR	E
ENDM

; print cactus to LCD if cond bit is set, else print space
printc	macro	cond
	local	print_space
	local	print_cactus
	jnb	cond, print_space
	cmd	#cactus
	jmp	print_cactus
print_space:
	cmd	#space
print_cactus:
endm

; ========== code ==========
	ORG	0H
	JMP	INIT

	ORG	3H		; interrupt service routine for external interrupt
	MOV	JUMP_DURATION, #3	; set number of cycles for dino to stay in the air
	RETI

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
	CMD	#38H		; two lines, 5x7 matrix

; load custom characters
;	CMD	#40H		; set CGRAM address
;	SETB	RS		; select data register
;	MOV	DPTR, #CHARS
;	MOV	R0, #0
;LOAD_CHARACTERS:
;	MOV	A, R0
;	INC	R0
;	MOVC	A, @A+DPTR
;	CMD	A
;	CJNE	R0, #24, LOAD_CHARACTERS

; print birds
	CLR	RS		; select command register
	cmd #87h		; move cursor to the middle of the sky
	SETB	RS		; select data register
	cmd #bird
	cmd #space
	cmd #space
	cmd #bird
	cmd #space
	cmd #bird

; load floor
	MOV	FLOOR_R, #00100011B
	MOV	FLOOR_L, #00010011B

GAME_LOOP:
; decrement jump duration while above 0
	MOV	A, JUMP_DURATION
	JZ	DURATION_NO_UPDATE
	DEC	JUMP_DURATION
DURATION_NO_UPDATE:

; shift map position
	MOV	A, FLOOR_R	; move right side of floor
	RLC	A
	MOV	FLOOR_R, A
	MOV	A, FLOOR_L	; move left side of floor
	RLC	A
	MOV	FLOOR_L, A
	MOV	FLOOR_R.0, C

; repaint
	CLR	RS		; select command register
	CMD	#81H		; second line,
	SETB	RS		; select data register

; dino up
	MOV	A, JUMP_DURATION
	JZ	DINO_UP_0
	CMD	#DINO
	JMP	DINO_UP_1

DINO_UP_0:
	CMD	#SPACE
DINO_UP_1:

	CLR	RS		; select command register
	CMD	#0C1H		; second line
	SETB	RS		; select data register

; dino down
	MOV	A, JUMP_DURATION
	JNZ	DINO_DOWN_0
	CMD	#DINO
	JMP	DINO_DOWN_1

DINO_DOWN_0:
	CMD	#SPACE
DINO_DOWN_1:

; repaint cacti
	printc	floor_l.6
	printc	floor_l.5
	printc	floor_l.4
	printc	floor_l.3
	printc	floor_l.2
	printc	floor_l.1
	printc	floor_l.0
	printc	floor_r.7
	printc	floor_r.6
	printc	floor_r.5
	printc	floor_r.4
	printc	floor_r.3
	printc	floor_r.2
	printc	floor_r.1
	printc	floor_r.0

	JMP	GAME_LOOP
	END