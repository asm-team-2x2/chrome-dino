;GAME.ASM

INPUT	EQU	P0.0
PREVIOUS_INPUT	EQU	20H
JUMP_DURATION	EQU	21h
JUMPING	EQU	22h
SCORE	EQU 23h

	JMP	INIT

INIT:
	MOV	INPUT, #0
	MOV	PREVIOUS_INPUT, #0
	MOV	JUMP_DURATION, #5
	MOV	JUMPING, #0
	MOV	SCORE, #0
	JMP	START

START:
	JMP	GAME_LOOP

GAME_LOOP:
	CALL CHECK_INPUT
	NOP
	; REST OF THE GAME LOGIC HERE
	CALL	DECREMENT_JUMPING
	JMP	GAME_LOOP

CHECK_INPUT:
	MOV	A, INPUT
	MOV	B, PREVIOUS_INPUT
	XRL	A, B
	JNZ	INPUT_CHANGED
CHECK_INPUT_END:
	CALL SET_PREVIOUS_INPUT
	RET

INPUT_CHANGED:
	MOV	A, JUMPING
	JNZ	CHECK_INPUT_END
	MOV	JUMPING, JUMP_DURATION
	JMP	CHECK_INPUT_END

SET_PREVIOUS_INPUT:
	MOV	PREVIOUS_INPUT, INPUT
	RET

DECREMENT_JUMPING:
	MOV	A, JUMPING
	JZ	DECREMENT_JUMPING_END
	DEC	JUMPING
DECREMENT_JUMPING_END:
	RET

