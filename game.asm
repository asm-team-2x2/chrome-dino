; ========== pins ==========
D	EQU	P1
E	BIT	P2.0
RW	BIT	P2.1
RS	BIT	P2.2

; ========== variables ==========
JUMP_DURATION	EQU	20H
FLOOR_L	EQU	21H
FLOOR_R	EQU	22H

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

; load floor
	MOV	FLOOR_R, #00100011B
	MOV	FLOOR_L, #00010011B

GAME_LOOP:
; update dino position
	MOV	A, JUMP_DURATION
	JZ	DURATION_NO_UPDATE	; dino is on the floor if duration = 0
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
	CMD	#81H		; second line, second character
	SETB	RS		; select data register

; dino up
	MOV	A, JUMP_DURATION
	JZ	DINO_UP_0
	CMD	#0
	JMP	DINO_UP_1

DINO_UP_0:
	CMD	#3
DINO_UP_1:

	CLR	RS		; select command register
	CMD	#0C1H		; second line, second character
	SETB	RS		; select data register

; dino down
	MOV	A, JUMP_DURATION
	JNZ	DINO_DOWN_0
	CMD	#0
	JMP	DINO_DOWN_1

DINO_DOWN_1:
	CMD	#3
DINO_DOWN_0:

; floor left
	MOV	R0, #0
	MOV	A, FLOOR_L
	RL	A

REPAINT_FLOOR_L:
	JB	A.7, PRINT_FLOOR_L
	CMD	#3
	JMP	SKIP_FLOOR_L
PRINT_FLOOR_L:
	CMD	#1
SKIP_FLOOR_L:
	RL	A
	INC	R0
	CJNE	R0, #7, REPAINT_FLOOR_L

; floor right
	MOV	A, FLOOR_R

REPAINT_FLOOR_R:
	JB	A.7, PRINT_FLOOR_R
	CMD	#3
	JMP	SKIP_FLOOR_R
PRINT_FLOOR_R:
	CMD	#1
SKIP_FLOOR_R:
	RL	A
	INC	R0
	CJNE	R0, #15, REPAINT_FLOOR_R

	JMP	GAME_LOOP
	END