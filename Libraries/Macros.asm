; ---------------------------------------------------------------------------
; toggle interrupts
; ---------------------------------------------------------------------------

.MACRO disable_ints
	move.w	#$2700,sr ; disable interrupts
	.ENDM

.MACRO enable_ints
	move.w	#$2300,sr ; enable interrupts
	.ENDM

.MACRO locVRAM ARGS loc,controlport
	.IFNDEFM controlport
	.DEFINE controlport=(VDP.Control).l
	.ENDIF
	move.l	#($40000000+(((loc)&$3FFF)<<16)+(((loc)&$C000)>>14)),controlport
	.ENDM
	
; Equivalent to 'ABCD' in asm68k/asw
.FUNCTION double_char(A,B,C,D) (A<<24)|(B<<16)|(C<<8)|D

; Swap bhs with bcc
