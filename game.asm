; ========== pins ==========
D	EQU	P1
E	BIT	P2.0
RW	BIT	P2.1
RS	BIT	P2.2

; ========== registers ==========
; R0: iteration variable
; R1: jump duration (greater than 0 while dino is in the air)
; R2: score
; R3: highscore

; ========== variables ==========
CACTI_1	DATA	20H
CACTI_2	DATA	21H
CACTI_3	DATA	22H

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

; ========== routines ==========
; print the first 3 decimal digits of the accu to the LCD
printn:
	MOV	R0, #3
modulo_loop:
	MOV	B, #10
	DIV	AB		; calculate three decimal digits with a modulo operation
	PUSH	B		; store decimal digits on the stack to print in reverse order
	DJNZ	R0, MODULO_LOOP

	MOV	R0, #3
printn_loop:
	POP	A
	ADD	A, #30H		; add 0x30 to every digit to conver to ASCII
	CMD	A		; print digit
	DJNZ	R0, PRINTN_LOOP
	RET

; ========== code ==========
	ORG	0H
	JMP	INIT

; interrupt service routine for external interrupt
	ORG	3H
	MOV	R1, #2		; set number of cycles for dino to stay in the air
	RETI

chars:	DB	00H, 07H, 07H, 0CH, 1EH, 1CH, 14H, 12H, 04H, 04H, 05H, 17H, 1EH, 0EH, 06H, 06H, 0H, 10H, 1CH, 0FH, 0CH, 08H, 00H, 00H	; custom characters to display game entities
text:	DB	'GAME OVER!'

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
characters_loop:
	MOV	A, R0
	INC	R0
	MOVC	A, @A+DPTR
	CMD	A
	CJNE	R0, #24, CHARACTERS_LOOP

restart:
; reset score
	MOV	R2, #0

; load cacti positions
	MOV	CACTI_1, #00001001B
	MOV	CACTI_2, #10010011B
	MOV	CACTI_3, #00011011B

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
	PRINTC	CACTI_1.7
dino_down:

; repaint cacti
	PRINTC	CACTI_1.6
	PRINTC	CACTI_1.5
	PRINTC	CACTI_1.4
	PRINTC	CACTI_1.3
	PRINTC	CACTI_1.2
	PRINTC	CACTI_1.1
	PRINTC	CACTI_1.0
	PRINTC	CACTI_2.7
	PRINTC	CACTI_2.6
	PRINTC	CACTI_2.5
	PRINTC	CACTI_2.4
	PRINTC	CACTI_2.3
	PRINTC	CACTI_2.2
	PRINTC	CACTI_2.1
	PRINTC	CACTI_2.0

; check for collision
	MOV	C, EX0
	ANL	C, CACTI_1.7
	JC	GAME_OVER

; increase score
	INC	R2

; shift cacti positions
	MOV	A, CACTI_3	; move right side of cacti
	RLC	A
	MOV	CACTI_3, A

	MOV	A, CACTI_2	; move middle side of cacti
	RLC	A
	MOV	CACTI_2, A

	MOV	A, CACTI_1	; move left side of cacti
	RLC	A
	MOV	CACTI_1, A
	MOV	CACTI_3.0, C

	JMP	GAME_LOOP

game_over:
; print "GAME OVER" text
	CLEAR
	CURSOR	#81H
	MOV	DPTR, #TEXT
	MOV	R0, #0
text_loop:
	MOV	A, R0
	MOVC	A, @A+DPTR
	CMD	A
	INC	R0
	CJNE	R0, #10, TEXT_LOOP

; update highscore
	MOV	A, R3
	SUBB	A, R2
	JNC	NO_HIGHSCORE
	MOV	A, R2		; move higscore via accu because register to register move is not possible
	MOV	R3, A
no_highscore:

; print score and highscore
	CURSOR	#0C1H		; move to second line
	CMD	#53H		; print 'S'
	CMD	#63H		; print 'c'
	CMD	#3AH		; print ':'
	MOV	A, R2
	CALL	PRINTN		; print score
	CMD	#30H		; print '0'
	CMD	#SPACE
	CMD	#SPACE

	CMD	#48H		; print 'H'
	CMD	#69H		; print 'i'
	CMD	#3AH		; print ':'
	MOV	A, R3
	CALL	PRINTN		; print highscore
	CMD	#30H		; print '0'

; wait until player jumps to restart the game
	MOV	R1, #0
wait_loop:
	MOV	A, R1
	JZ	WAIT_LOOP
	MOV	R1, #0
	JMP	RESTART

	END