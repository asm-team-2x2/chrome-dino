;GAME.ASM

JUMP_DURATION	EQU	20H

	ORG	0H
	JMP	INIT

	ORG	3H
	JMP	JUMP

INIT:
; initialize external interrupt
	SETB	IT0		; trigger on falling edge
	SETB	EX0		; enable external interrupt
	SETB	EA		; enable interrupts

	MOV	SCORE, #0
	JMP	GAME_LOOP

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