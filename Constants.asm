; ---------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------

; Size of DAC driver and SegaPCM are already made by compiler

; Clocks
.DEFINE Master_Clock 53693175
.DEFINE M68000_Clock Master_Clock/7
.DEFINE Z80_Clock Master_Clock/15
.DEFINE FM_Sample_Rate M68000_Clock/(6*6*4)
.DEFINE PSG_Sample_Rate Z80_Clock/16

; VDP addressses
.DEFINE VDP.Data	$C00000
.DEFINE VDP.Control	$C00004
.DEFINE VDP.Counter	$C00008
.DEFINE VDP.PSG		$C00011
.DEFINE VDP.Debug	$C0001C

; Z80 addresses
.DEFINE z80.RAM		$A00000
.DEFINE _sizeof_z80.RAM	$2000
.DEFINE ym2612_a0	$A04000
.DEFINE ym2612_d0	$A04001
.DEFINE ym2612_a1	$A04002
.DEFINE ym2612_d1	$A04003
.DEFINE z80.Bus_Request	$A11100
.DEFINE z80.Reset	$A11200
