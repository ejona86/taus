;
; iNES header
;

.segment "HEADER"

INES_MAPPER = 1 ; 0 = NROM
INES_MIRROR = 0 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0 ; 1 = battery backed SRAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; ID
.byte $02 ; 16k PRG chunk count
.byte $02 ; 8k CHR chunk count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

;
; CHR ROM
;

.segment "CHR"
.incbin "tetris-CHR-00.bin"
.incbin "tetris-CHR-01.bin"

.segment "BSS"
nmt_update: .res 256 ; nametable update entry buffer for PPU update
palette:    .res 32  ; palette buffer for PPU update

.segment "OAM"
oam: .res 256        ; sprite OAM data to be uploaded by DMA

.segment "ZEROPAGE"

.include "tetris-PRG.s"


;
; IPS Mod
;

IPSPRGOFFSET = -16+$8000

.segment "IPSHEADER"
.byte 'P', 'A', 'T', 'C', 'H'

.segment "IPSEOF"
.byte 'E', 'O', 'F'

.segment "HUNK1HDR"
.import __HUNK1_RUN__, __HUNK1_SIZE__
.byte 0
.dbyt __HUNK1_RUN__-IPSPRGOFFSET
.dbyt __HUNK1_SIZE__

.segment "HUNK1"

; at incrementPieceStat, replaces lda
       jmp resetStatMod
afterJmpResetStatMod:

.segment "HUNK2HDR"
.import __HUNK2_RUN__, __HUNK2_SIZE__
.byte 0
.dbyt __HUNK2_RUN__-IPSPRGOFFSET
.dbyt __HUNK2_SIZE__

.segment "HUNK2"

resetStatMod:
       lda     tetriminoTypeFromOrientation,x
       cmp     #$6 ; i piece
       beq     clearStats
       lda     #$6
       jmp     afterJmpResetStatMod
clearStats:
       lda     #$0
       ldy     #14
clearByte:
       sta     statsByType-1,y
       dey
       bne     clearByte

       lda     #$0
       rts
