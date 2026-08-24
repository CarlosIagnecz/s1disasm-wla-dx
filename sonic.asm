;  =========================================================================
; |           Sonic the Hedgehog Disassembly for Sega Mega Drive            |
;  =========================================================================
;
; Disassembly created by Hivebrain
; thanks to drx, Stealth and Esrael L.G. Neto
; Patched to be compiled with WLA-Z80

; ---------------------------------------------------------------------------
; WARNING:
; this disassembly will not generate an accurate result!

; ---------------------------------------------------------------------------
; NOTE:
; Set your editor's tab width to 8 characters wide for viewing this file.

; ===========================================================================
; ASSEMBLY OPTIONS:

.DEFINE Revision 1
; Sets the disassembly to build a specific version of the game
; REVXB has been ommited in favour of readability
;	| 0 -> Original version, REV00
;	| 1 -> Updated release, REV01
; Changes: Major improvements for most of the codebase & some visual touches.

.DEFINE ChecksumSkip 0
; 0 -> Preserves checksum, used in all revisions.
; 1 -> Removes slow checksum at a hard reset.

.DEFINE ZoneCount = 6
; Used for the zonewarning macro. Reflects playable zones
; (GHZ, LZ, MZ, SLZ, SYZ & SBZ)

; ===========================================================================
;
; Sega Mega Drive/Genesis MC68000 Memory Map (WLA-DX repository)
; 

.MEMORYMAP
DEFAULTSLOT 0
	SLOT 0 START $000000 SIZE $400000 NAME "ROM"   ; 4MB ROM / Cartridge RAM / Cartridge
	SLOT 1 START $A00000 SIZE   $2000 NAME "ZRAM"  ; 8KB Z80 RAM
	SLOT 2 START $FF0000 SIZE  $10000 NAME "WRAM"  ; 64KB Work RAM
.ENDME

.ROMBANKSIZE $0FFFFF
.ROMBANKS 1

; ===========================================================================
; Simplifying macros and functions
.INCLUDE "Libraries/Macros.asm"

; ===========================================================================
; Equates section - Names for variables
.INCLUDE "Variables.asm"

; ===========================================================================
; Expressing sprite mappings and DPLCs in a portable and human-readable form
.INCLUDE "Libraries/Map Macros.asm"

; ===========================================================================
; start of ROM



.MDVECTORS
	INITIALSP v_systemstack&$FFFFFF 
	RESET	EntryPoint
	DEFAULT ErrorExcept ; SPURIOUS
	BUSERROR BusError
	ADDRERROR AddressError
	ILLEGAL IllegalInstr
	DIVZERO ZeroDivide
	CHK ChkInstr
	TRAPV TrapvInstr
	PRIVILEGE PrivilegeViol
	TRACE Trace
	LINE1010 Line1010Emu ; aka. Line A
	LINE1111 Line1111Emu ; aka, Line F
	LEVEL1 ErrorTrap
	EXTERNAL ErrorTrap ; Level 2 IRQ
	LEVEL3 ErrorTrap
	HBLANK  HBlank ; Level 4 IRQ
	LEVEL5 ErrorTrap
	VBLANK  VBlank ; Level 6 IRQ
	LEVEL7 ErrorTrap
	TRAP0 ErrorTrap
	TRAP1 ErrorTrap
	TRAP2 ErrorTrap
	TRAP3 ErrorTrap
	TRAP4 ErrorTrap
	TRAP5 ErrorTrap
	TRAP6 ErrorTrap
	TRAP7 ErrorTrap
	TRAP8 ErrorTrap
	TRAP9 ErrorTrap
	TRAP10 ErrorTrap
	TRAP11 ErrorTrap
	TRAP12 ErrorTrap
	TRAP13 ErrorTrap
	TRAP14 ErrorTrap
	TRAP15 ErrorTrap
.ENDMDVECTORS

.DEFINE SerialNumber "GM 00001009-00"   ; Serial/version number (Rev 0)

.IF Revision == 1
	.REDEFINE SerialNumber "GM 00004049-01" ; Serial/version number (Rev non-0)
.ENDIF

.SMDHEADER
	COPYRIGHT	"(C)SEGA 1991.APR" ; Copyright holder and release date (generally year)
	TITLEDOMESTIC	"SONIC THE               HEDGEHOG                " ; Domestic name
	TITLEOVERSEAS	"SONIC THE               HEDGEHOG                " ; International name
	SERIALNUMBER	SerialNumber
	DEVICESUPPORT	"J            "
	RAMADDRESSRANGE $FF0000, $FFFFFF
	EXTRAMEMORY	"RA", $A0, $20, 0, 0
	REGIONSUPPORT	"JUE"
.ENDSMD

.ORGA $200

; Data from here is named AC.SN1 in Sonic Jam (Devon's finding in SSRG)
; (All code is in AC.SN1)
.SECTION "EntryPoint"	FORCE ALIGN $200 

; ===========================================================================
; Crash/Freeze the 68000. Unlike Sonic 2, Sonic 1 uses the 68000 for playing music, so it stops too
ErrorTrap:
		nop	
		nop	
		bra.b	ErrorTrap

; ===========================================================================

EntryPoint:
		tst.l	(port_1_control_hi).l	; test port A & B control registers
		bne.b	PortA_Ok
		tst.w	(expansion_control_hi).l ; test port C control register
PortA_Ok:	bne.b	SkipSetup		; skip the VDP and Z80 setup code if this is a soft-reset

		lea	SetupValues(pc),a5	; load setup values array address
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	-$10FF(a1),d0	; get hardware version (from $A10001)
		andi.b	#$F,d0
		beq.b	SkipSecurity	; If the console has no TMSS, skip the security stuff.
		move.l	#double_char('S','E','G','A'),$2F00(a1) ; move "SEGA" to TMSS register ($A14000)

SkipSecurity:
		move.w	(a4),d0	; clear write-pending flag in VDP to prevent issues if the 68k has been reset in the middle of writing a command long word to the VDP.
		moveq	#0,d0	; clear d0
		movea.l	d0,a6	; clear a6
		move.l	a6,usp	; set usp to $0

		moveq	#$17,d1
VDPInitLoop:
		move.b	(a5)+,d5	; add $8000 to value
		move.w	d5,(a4)		; move value to VDP register
		add.w	d7,d5		; next register
		dbf	d1,VDPInitLoop
		
		move.l	(a5)+,(a4)
		move.w	d0,(a3)		; clear the VRAM
		move.w	d7,(a1)		; stop the Z80
		move.w	d7,(a2)		; reset the Z80

WaitForZ80:
		btst	d0,(a1)		; has the Z80 stopped?
		bne.b	WaitForZ80	; if not, branch

		moveq	#$25,d2
Z80InitLoop:
		move.b	(a5)+,(a0)+
		dbf	d2,Z80InitLoop
		
		move.w	d0,(a2)
		move.w	d0,(a1)		; start the Z80
		move.w	d7,(a2)		; reset the Z80

ClrRAMLoop:
		move.l	d0,-(a6)	; clear 4 bytes of RAM
		dbf	d6,ClrRAMLoop	; repeat until the entire RAM is clear
		move.l	(a5)+,(a4)	; set VDP display mode and increment mode
		move.l	(a5)+,(a4)	; set VDP to CRAM write

		moveq	#$1F,d3	; set repeat times
ClrCRAMLoop:
		move.l	d0,(a3)	; clear 2 palettes
		dbf	d3,ClrCRAMLoop	; repeat until the entire CRAM is clear
		move.l	(a5)+,(a4)	; set VDP to VSRAM write

		moveq	#$13,d4
ClrVSRAMLoop:
		move.l	d0,(a3)	; clear 4 bytes of VSRAM.
		dbf	d4,ClrVSRAMLoop	; repeat until the entire VSRAM is clear
		moveq	#3,d5

PSGInitLoop:
		move.b	(a5)+,$11(a3)	; reset the PSG
		dbf	d5,PSGInitLoop	; repeat for other channels
		move.w	d0,(a2)
		movem.l	(a6),d0-d7/a0-a6	; clear all registers
		disable_ints

SkipSetup:
		bra.b	GameProgram	; begin game

; ===========================================================================
SetupValues:	.DW $8000		; VDP register start number
		.DW $3FFF		; size of RAM/4
		.DW $100		; VDP register diff

		.DD z80.RAM		; start of Z80 RAM
		.DD z80.Bus_Request	; Z80 bus request
		.DD z80.Reset		; Z80 reset
		.DD VDP.Data		; VDP data
		.DD VDP.Control		; VDP control

		.DB 4			; VDP $80 - 8-colour mode
		.DB $14			; VDP $81 - Megadrive mode, DMA enable
		.DB ($C000>>10)		; VDP $82 - foreground nametable address
		.DB ($F000>>10)		; VDP $83 - window nametable address
		.DB ($E000>>13)		; VDP $84 - background nametable address
		.DB ($D800>>9)		; VDP $85 - sprite table address
		.DB 0			; VDP $86 - unused
		.DB 0			; VDP $87 - background colour
		.DB 0			; VDP $88 - unused
		.DB 0			; VDP $89 - unused
		.DB 255			; VDP $8A - Scanlines until next HBlank
		.DB 0			; VDP $8B - full screen scroll
		.DB $81			; VDP $8C - 40 cell display
		.DB ($DC00>>10)		; VDP $8D - hscroll table address
		.DB 0			; VDP $8E - unused
		.DB 1			; VDP $8F - VDP increment
		.DB 1			; VDP $90 - 64 cell hscroll size
		.DB 0			; VDP $91 - window h position
		.DB 0			; VDP $92 - window v position
		.DW $FFFF		; VDP $93/94 - DMA length
		.DW 0			; VDP $95/96 - DMA source
		.DB $80		; VDP $97 - DMA fill VRAM
		.DD $40000080		; VRAM address 0

		.INCBIN "Build/z80_boot.z80" FSIZE z80_Boot_Routine_Size

		.DW $8104		; VDP display mode
		.DW $8F02		; VDP increment
		.DD $C0000000		; CRAM write mode
		.DD $40000010		; VSRAM address 0

		.DB $9F, $BF, $DF, $FF	; values for PSG channel volumes
; ===========================================================================
.ENDS  ; End of section 'EntryPoint'

; Data from here is named AC.SN1
.SECTION "GameProgram"	 FORCE ALIGN $200
; ===========================================================================

GameProgram:
		tst.w	(VDP.Control).l
		btst	#6,(expansion_control).l
		beq.b	CheckSumCheck
		cmpi.l	#double_char('i','n','i','t'),(v_init).w ; has checksum routine already run?
		beq.w	GameInit	; if yes, branch

CheckSumCheck:
	.IFEQ ChecksumSkip 0
		movea.l	#EndOfHeader,a0	; start checking bytes after the header ($200)
		movea.l	#RomEndLoc,a1	; stop at end of ROM
		move.l	(a1),d0
		moveq	#0,d1
@loop:
		add.w	(a0)+,d1
		cmp.l	a0,d0
		bcc.b	@loop
		movea.l	#Checksum,a1	; read the checksum
		cmp.w	(a1),d1		; compare checksum in header to ROM
		bne.w	CheckSumError	; if they don't match, branch
	.ENDIF

CheckSumOk:
		lea	(v_crossresetram).w,a6
		moveq	#0,d7
		move.w	#(v_ram_end-v_crossresetram)/4-1,d6
@clearRAM:
		move.l	d7,(a6)+
		dbf	d6,@clearRAM	; clear RAM ($FE00-$FFFF)

		move.b	(console_version).l,d0
		andi.b	#$C0,d0
		move.b	d0,(v_megadrive).w ; get region setting
		move.l	#double_char('i','n','i','t'),(v_init).w ; set flag so checksum won't run again

GameInit:
		lea	(v_ram_start).l,a6
		moveq	#0,d7
		move.w	#(v_crossresetram-v_ram_start_def)/4-1,d6
@clearRAM:
		move.l	d7,(a6)+
		dbf	d6,@clearRAM	; clear RAM ($0000-$FDFF)

		bsr.w	VDPSetupGame
		bsr.w	DACDriverLoad
		bsr.w	JoypadInit
		move.b	#id_Sega,(v_gamemode).w ; set Game Mode to Sega Screen

MainGameLoop:
		move.b	(v_gamemode).w,d0 ; load Game Mode
		andi.w	#$1C,d0	; limit Game Mode value to $1C max (change to a maximum of 7C to add more game modes)
		;jsr	GameModeArray(d0.w,pc) ; jump to apt location in ROM
		.DW $4EBB,*-GameModeArray ; temporary replacement until ACTUAL mneumonic is found
		bra.b	MainGameLoop	; loop indefinitely
; ===========================================================================
; ---------------------------------------------------------------------------
; Main game mode array
; ---------------------------------------------------------------------------

GameModeArray:

ptr_GM_Sega:	bra.w	GM_Sega		; Sega Screen ($00)

ptr_GM_Title:	bra.w	GM_Title	; Title Screen ($04)

ptr_GM_Demo:	bra.w	GM_Level	; Demo Mode ($08)

ptr_GM_Level:	bra.w	GM_Level	; Normal Level ($0C)

ptr_GM_Special:	bra.w	GM_Special	; Special Stage ($10)

ptr_GM_Cont:	bra.w	GM_Continue	; Continue Screen ($14)

ptr_GM_Ending:	bra.w	GM_Ending	; End of game sequence ($18)

ptr_GM_Credits:	bra.w	GM_Credits	; Credits ($1C)

		rts
.ENDS	; End of section 'GameProgram'

.SECTION "Interrupts"	FORCE ALIGN $200
; ===========================================================================
	if ChecksumSkip=0
CheckSumError:
		bsr.w	VDPSetupGame
		move.l	#$C0000000,(vdp_control_port).l ; set VDP to CRAM write
		moveq	#($80)/2-1,d7

.fillred:
		move.w	#cRed,(vdp_data_port).l ; fill palette with red
		dbf	d7,.fillred	; repeat until CRAM is filled

		bra.b	* ; Endless loop
	endif
; ===========================================================================

BusError:
		move.b	#2,(v_errortype).w
		bra.b	loc_43A

AddressError:
		move.b	#4,(v_errortype).w
		bra.b	loc_43A

IllegalInstr:
		move.b	#6,(v_errortype).w
		addq.d	#2,2(sp)
		bra.b	loc_462

ZeroDivide:
		move.b	#8,(v_errortype).w
		bra.b	loc_462

ChkInstr:
		move.b	#10,(v_errortype).w
		bra.b	loc_462

TrapvInstr:
		move.b	#12,(v_errortype).w
		bra.b	loc_462

PrivilegeViol:
		move.b	#14,(v_errortype).w
		bra.b	loc_462

Trace:
		move.b	#16,(v_errortype).w
		bra.b	loc_462

Line1010Emu:
		move.b	#18,(v_errortype).w
		addq.d	#2,2(sp)
		bra.b	loc_462

Line1111Emu:
		move.b	#20,(v_errortype).w
		addq.d	#2,2(sp)
		bra.b	loc_462

ErrorExcept:
		move.b	#0,(v_errortype).w
		bra.b	loc_462
; ===========================================================================

loc_43A:
		disable_ints
		addq.w	#2,sp
		move.d	(sp)+,(v_spbuffer).w
		addq.w	#2,sp
		movem.d	d0-a7,(v_regbuffer).w
		bsr.w	ShowErrorMessage
		move.d	2(sp),d0
		bsr.w	ShowErrorValue
		move.d	(v_spbuffer).w,d0
		bsr.w	ShowErrorValue
		bra.b	loc_478
; ===========================================================================

loc_462:
		disable_ints
		movem.d	d0-a7,(v_regbuffer).w
		bsr.w	ShowErrorMessage
		move.d	2(sp),d0
		bsr.w	ShowErrorValue

loc_478:
		bsr.w	ErrorWaitForC
		movem.d	(v_regbuffer).w,d0-a7
		enable_ints
		rte	

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


ShowErrorMessage:
		lea	(vdp_data_port).l,a6
		locVRAM	ArtTile_Error_Handler_Font*tile_size
		lea	(Art_Text).l,a0
		move.w	#(Art_Text_End-Art_Text-tile_size)/2-1,d1 ; strangely, this does not load the final tile
.loadgfx:
		move.w	(a0)+,(a6)
		dbf	d1,.loadgfx

		moveq	#0,d0		; clear d0
		move.b	(v_errortype).w,d0 ; load error code
		move.w	ErrorText(pc,d0.w),d0
		lea	ErrorText(pc,d0.w),a0
		locVRAM	vram_fg+$604
		moveq	#19-1,d1		; number of characters (minus 1)

.showchars:
		moveq	#0,d0
		move.b	(a0)+,d0
		addi.w	#-'0'+ArtTile_Error_Handler_Font,d0 ; rebase from ASCII to a VRAM index
		move.w	d0,(a6)
		dbf	d1,.showchars	; repeat for number of characters
		rts
; End of function ShowErrorMessage

; ===========================================================================
ErrorText:	dc.w .exception-ErrorText, .bus-ErrorText
		dc.w .address-ErrorText, .illinstruct-ErrorText
		dc.w .zerodivide-ErrorText, .chkinstruct-ErrorText
		dc.w .trapv-ErrorText, .privilege-ErrorText
		dc.w .trace-ErrorText, .line1010-ErrorText
		dc.w .line1111-ErrorText
.exception:	dc.b "ERROR EXCEPTION    "
.bus:		dc.b "BUS ERROR          "
.address:	dc.b "ADDRESS ERROR      "
.illinstruct:	dc.b "ILLEGAL INSTRUCTION"
.zerodivide:	dc.b "@ERO DIVIDE        "
.chkinstruct:	dc.b "CHK INSTRUCTION    "
.trapv:		dc.b "TRAPV INSTRUCTION  "
.privilege:	dc.b "PRIVILEGE VIOLATION"
.trace:		dc.b "TRACE              "
.line1010:	dc.b "LINE 1010 EMULATOR "
.line1111:	dc.b "LINE 1111 EMULATOR "
		even

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


ShowErrorValue:
		move.w	#ArtTile_Error_Handler_Font+10,(a6)	; display "$" symbol
		moveq	#8-1,d2

.loop:
		rol.d	#4,d0
		bsr.s	.shownumber	; display 8 numbers
		dbf	d2,.loop
		rts
; End of function ShowErrorValue


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


.shownumber:
		move.w	d0,d1
		andi.w	#$F,d1
		cmpi.w	#$A,d1
		blo.s	.chars0to9
		addq.w	#7,d1		; add 7 for characters A-F

.chars0to9:
		addi.w	#ArtTile_Error_Handler_Font,d1
		move.w	d1,(a6)
		rts
; End of function sub_5CA


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


ErrorWaitForC:
		bsr.w	ReadJoypads
		cmpi.b	#btnC,(v_jpadpress1).w ; is button C pressed?
		bne.w	ErrorWaitForC	; if not, branch
		rts
; End of function ErrorWaitForC

; ===========================================================================

Art_Text:	binclude	"artunc/menutext.bin" ; text used in level select and debug mode
Art_Text_End:	even

.ENDS	; End of section 'Interrupts'

; (TODO)
HBlank:
VBlank:
