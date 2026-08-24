; ---------------------------------------------------------------------------
; toggle interrupts
; ---------------------------------------------------------------------------

.MACRO disable_ints
	move.w	#$2700,sr ; disable interrupts
	.ENDM

.MACRO enable_ints
	move.w	#$2300,sr ; enable interrupts
	.ENDM
	
; Equivalent to 'ABCD' in asm68k/asw
.FUNCTION double_char(A,B,C,D) (A<<24)|(B<<16)|(C<<8)|D

; Swap bhs with bcc
