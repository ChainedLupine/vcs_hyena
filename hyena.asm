	processor 6502
	include "vcs.h"
	include "macro.h"


; HYENAS HYENAS HYENAS HYENAS HYENAS HYENAS HYENAS HYENAS 

; Version 2!

; Now with asymmetrical playfield rendering!

; ------------------------------------------------------------
; memory
; ------------------------------------------------------------

	seg.u Memory
	org $80

Counter			.byte $00
ScanlineCounter		.byte $00
ColorValueIdx		.byte $00
ColorAccum		.byte $00,$00

; constants
BlockHeight 	equ #8
PFDataHeight 	equ #23
PulseTableSize	equ #14

        seg
        
        seg Code
	org  $f000

; ------------------------------------------------------------
; startup
; ------------------------------------------------------------

Start	CLEAN_START


; ------------------------------------------------------------
; frame kernel
; ------------------------------------------------------------

NextFrame
; This macro efficiently gives us 3 lines of VSYNC
	VERTICAL_SYNC
	
; 37 lines of VBLANK
	ldx #37
LVBlank	sta WSYNC
	dex
	bne LVBlank
; Disable VBLANK
        stx VBLANK

; Frame is 192 scanlines
	lda #192
        sta ScanlineCounter
        
        ldy #BlockHeight	; Y is number of scanlines per PF line        
        ldx #PFDataHeight	; X is index of playfield graphic data

ScanLoop
	sta WSYNC	; wait for next scanline
        
	; do our scrolling color background
        lda ScanlineCounter 	; load A with our scanline
        sbc Counter		; dec counter for scrolling effect
        lsr			; X >> 1 (don't really have time for more now)
        sta COLUBK		; write this to our background
        
        ; access first half of playfield data
	lda LeftPF0Data,X
	sta PF0
	lda LeftPF1Data,X
	sta PF1
	lda LeftPF2Data,X
	sta PF2

	; access other half of playfield data
	lda RightPF0Data,X
	sta PF0
	lda RightPF1Data,X
	sta PF1
	lda RightPF2Data,X
	sta PF2

        dey		; decrement our block line count
	bne SkipToNextFrame
        
        ; we've drawn as many lines we want for this PF line
	ldy #BlockHeight	; Reset back to num scanlines per PF line
        dex			; dec our actual PF data line
        bpl SkipToNextFrame	; if data index line is negative, 
        ldx #PFDataHeight	; then reset back to top of data
        
SkipToNextFrame      
        ; just decrement overall scanline
	dec ScanlineCounter
	bne ScanLoop
        
; Reenable VBLANK for bottom (and top of next frame)
	lda #2
        sta VBLANK
; 30 lines of overscan
	ldx #30
LVOver	sta WSYNC
	dex
	bne LVOver
	
	inc Counter
        
        ; basically, only do color changing when counter >> 5 = 0
        lda Counter
        asl
        asl
        asl
        asl
        bne SkipColorChange
        
        ; calculate LSB of color from pulsating lookup table
        ldx ColorValueIdx
        lda ColorPulseTable,X
        sta ColorAccum		; keep around for
        
	lda ColorAccum+1	; ColorAccum+1 = hue (0xF)
        asl
        asl
        asl
        asl			; cl << 4 (0xF to 0xF0)
        adc ColorAccum		; ColorAccum = value (0xF)
        sta COLUPF
        
       	; increment our pulsating table index, and reset if needed
        inc ColorValueIdx
        lda ColorValueIdx
        cmp #PulseTableSize
        bne SkipColorChange
        
        ; reset value change
        lda #0
        sta ColorValueIdx
        
	; increment our hue
        inc ColorAccum+1
        
SkipColorChange        
	; Time to start our next frame
	jmp NextFrame
        
ColorPulseTable
	.byte 0,2,4,6,8,10,12,14,12,10,8,6,4,2

; ------------------------------------------------------------
; Output from playfield-convert.py
; -----------------------------------------------------------
; image size is 40x24

	align 256,0

LeftPF0Data
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%01010000
	.byte #%01010000
	.byte #%01010000
	.byte #%00000000
	.byte #%00000000
	.byte #%10000000
	.byte #%01000000
	.byte #%01000000
	.byte #%01000000
	.byte #%01000000
	.byte #%01000000
	.byte #%10000000
	.byte #%00000000
	.byte #%00000000

	align 256,0

LeftPF1Data
	.byte #%00000001
	.byte #%00000010
	.byte #%00000100
	.byte #%00000100
	.byte #%00001000
	.byte #%00010001
	.byte #%00100000
	.byte #%00100000
	.byte #%01000000
	.byte #%01000000
	.byte #%01100010
	.byte #%01000111
	.byte #%01101111
	.byte #%01100000
	.byte #%11000000
	.byte #%00100000
	.byte #%00110000
	.byte #%01011000
	.byte #%00100110
	.byte #%00010101
	.byte #%00001000
	.byte #%00001000
	.byte #%10010000
	.byte #%01100000

	align 256,0

LeftPF2Data
	.byte #%00000111
	.byte #%00001000
	.byte #%00010000
	.byte #%00010000
	.byte #%00100011
	.byte #%01000111
	.byte #%10000000
	.byte #%10000000
	.byte #%00000000
	.byte #%00000000
	.byte #%10001000
	.byte #%00011100
	.byte #%10111100
	.byte #%10000000
	.byte #%00000000
	.byte #%10000000
	.byte #%11000000
	.byte #%01100000
	.byte #%10011000
	.byte #%01010111
	.byte #%00100000
	.byte #%00100000
	.byte #%01000000
	.byte #%10000000

	align 256,0

RightPF0Data
	.byte #%00000000
	.byte #%10100000
	.byte #%10100000
	.byte #%10100000
	.byte #%11100000
	.byte #%10100000
	.byte #%00000000
	.byte #%00000000
	.byte #%00010000
	.byte #%00010000
	.byte #%10010000
	.byte #%10010000
	.byte #%10010000
	.byte #%00010000
	.byte #%00110000
	.byte #%01000000
	.byte #%10000000
	.byte #%10010000
	.byte #%10000000
	.byte #%10000000
	.byte #%10000000
	.byte #%01000000
	.byte #%00100000
	.byte #%00010000

	align 256,0

RightPF1Data
	.byte #%00000000
	.byte #%00100110
	.byte #%00100100
	.byte #%00100110
	.byte #%01010100
	.byte #%01010110
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%01101110
	.byte #%01101110
	.byte #%01101110
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00001000
	.byte #%00010100
	.byte #%00100010
	.byte #%00100010
	.byte #%00100010
	.byte #%00000000
	.byte #%00000000

	align 256,0

RightPF2Data
	.byte #%00000000
	.byte #%01010101
	.byte #%01010101
	.byte #%01110101
	.byte #%01010101
	.byte #%00100011
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%01110111
	.byte #%01000001
	.byte #%01100001
	.byte #%00010001
	.byte #%01110111
	.byte #%00000000
	.byte #%00000000


; start vector
	org $fffc
	.word Start
	.word Start

