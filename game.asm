; ========== pins ==========
D	EQU	P1
E	BIT	P2.0
RW	BIT	P2.1
RS	BIT	P2.2

; ========== variables ==========
CACTI_L	DATA	20H
CACTI_R	DATA	21H
; R0: iteration variable
; R1: jump duration (greater than 0 while dino is in the air)

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

; move cursor to the given position
CURSOR	MACRO	POSITION
	CLR	RS		; select command register
	CMD	POSITION	; move cursor to the given position
	SETB	RS		; select data register
ENDM

; print cactus to LCD if cond bit is set, else print space
PRINTC	MACRO	COND
	LOCAL	PRINT_SPACE
	LOCAL	PRINT_CACTUS
	JNB	COND, PRINT_SPACE
	CMD	#CACTUS
	JMP	PRINT_CACTUS
print_space:			; IMPORTANT ! These labels have to be in lower case, otherwise the precompiler will fail!
	CMD	#SPACE
print_cactus:
ENDM

; clear LCD display
CLEAR	MACRO
	CLR	RS		; select command register
	CMD	#01H		; clear display
ENDM

; ========== code ==========
	ORG	0H
	JMP	INIT

	ORG	3H		; interrupt service routine for external interrupt
	MOV	R1, #2		; set number of cycles for dino to stay in the air
	RETI

chars:	DB	00H, 07H, 07H, 0CH, 1EH, 1CH, 14H, 12H, 04H, 04H, 05H, 17H, 1EH, 0EH, 06H, 06H, 0H, 10H, 1CH, 0FH, 0CH, 08H, 00H, 00H	; custom characters to display game entities
text:	DB	'GAME  OVER'

init:
; initialize external interrupt
	SETB	IT0		; trigger on falling edge
	SETB	EX0		; enable external interrupt
	SETB	EA		; enable interrupts

; initialize LCD display
	MOV	D, #0		; clear data pins
	CLR	RW		; write mode for display
	CLR	RS		; select command register
	CMD	#02H		; cursor home
	CMD	#0CH		; display on, cursor off
	CMD	#1EH		; cursor/display shift
	CMD	#38H		; two lines, 5x7 matrix

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
	CJNE	R0, #24, LOAD_CHARACTERS

restart:
; load cacti positions
	MOV	CACTI_L, #00001001B
	MOV	CACTI_R, #10010011B

; print birds
	CLEAR
	CURSOR	#87H		; move to the middle of the sky
	CMD	#BIRD
	CMD	#SPACE
	CMD	#SPACE
	CMD	#BIRD
	CMD	#SPACE
	CMD	#BIRD

game_loop:
; repaint dino
	CURSOR	#81H		; move to first line

	CJNE	R1, #0H, DINO_UP
	CMD	#SPACE		; print space if dino is on the floor
	CURSOR	#0C1H		; move to second line
	CMD	#DINO
	SETB	EX0		; enable interrupt when dino is on the floor
	JMP	DINO_DOWN
dino_up:
	CLR	EX0		; disable interrupt while dino is in the air
	DEC	R1		; decrement jump duration while above 0
	CMD	#DINO
	CURSOR	#0C1H		; move to second line
	PRINTC	CACTI_L.7
dino_down:

; repaint cacti
	PRINTC	CACTI_L.6
	PRINTC	CACTI_L.5
	PRINTC	CACTI_L.4
	PRINTC	CACTI_L.3
	PRINTC	CACTI_L.2
	PRINTC	CACTI_L.1
	PRINTC	CACTI_L.0
	PRINTC	CACTI_R.7
	PRINTC	CACTI_R.6
	PRINTC	CACTI_R.5
	PRINTC	CACTI_R.4
	PRINTC	CACTI_R.3
	PRINTC	CACTI_R.2
	PRINTC	CACTI_R.1
	PRINTC	CACTI_R.0

; check for collision
	MOV	C, EX0
	ANL	C, CACTI_L.7
	JC	GAME_OVER

; shift cacti positions
	MOV	A, CACTI_R	; move right side of cacti
	RLC	A
	MOV	CACTI_R, A
	MOV	A, CACTI_L	; move left side of cacti
	RLC	A
	MOV	CACTI_L, A
	MOV	CACTI_R.0, C

	JMP	GAME_LOOP

game_over:
; print "GAME OVER" text
	CLEAR
	CURSOR	#84H
	MOV	DPTR, #TEXT
	MOV	R0, #0
print_text:
	MOV	A, R0
	MOVC	A, @A+DPTR
	CMD	A
	INC	R0
	CJNE	R0, #10, PRINT_TEXT

; wait until player jumps to restart the game
	MOV	R1, #0
wait:
	MOV	A, R1
	JZ	WAIT

	MOV	R1, #0
	JMP	RESTART

	END