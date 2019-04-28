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
       jmp statsPerBlock
afterJmpResetStatMod:

.segment "HUNK2HDR"
.import __HUNK2_RUN__, __HUNK2_SIZE__
.byte 0
.dbyt __HUNK2_RUN__-IPSPRGOFFSET
.dbyt __HUNK2_SIZE__

.segment "HUNK2"

statsPerBlock:
        lda     tetriminoTypeFromOrientation,x
        cmp     #$6 ; i piece
        beq     clearDrought
        lda     #$0
        jmp     afterJmpResetStatMod
clearDrought:
        lda     #$0
        sta     statsByType
        sta     statsByType+1
        rts

.segment "HUNK3HDR"
.import __HUNK3_RUN__, __HUNK3_SIZE__
.byte 0
.dbyt __HUNK3_RUN__-IPSPRGOFFSET
.dbyt __HUNK3_SIZE__

.segment "HUNK3"

; gameBackground
.byte   $20,$00,$20,$7A,$67,$77,$77,$72,$79,$7A,$78,$75,$7A,$67,$77,$78,$83,$78,$83,$77,$87,$67,$78,$73,$87,$70,$71,$67,$87,$78,$75,$7A,$72,$7A,$67
.byte   $20,$20,$20,$72,$83,$87,$77,$87,$67,$78,$73,$87,$72,$83,$87,$78,$79,$79,$7A,$87,$78,$84,$7A,$82,$7A,$80,$81,$82,$79,$7A,$87,$78,$83,$78,$85
.byte   $20,$40,$20,$87,$72,$7A,$87,$78,$84,$7A,$82,$7A,$87,$67,$38,$39,$39,$39,$39,$39,$39,$39,$39,$39,$39,$3A,$38,$39,$39,$39,$39,$39,$39,$3A,$87
.byte   $20,$60,$20,$67,$77,$38,$39,$39,$39,$39,$39,$39,$3A,$77,$3B,$FF,$15,$12,$17,$0E,$1C,$24,$FF,$FF,$FF,$3C,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$67
.byte   $20,$80,$20,$77,$87,$3B,$FF,$24,$1D,$22,$19,$0E,$3C,$77,$3D,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3F,$3B,$1D,$18,$19,$FF,$FF,$FF,$3C,$77
.byte   $20,$A0,$20,$80,$7A,$3D,$3E,$3E,$3E,$3E,$3E,$3E,$3F,$87,$30,$31,$31,$31,$31,$31,$31,$31,$31,$31,$31,$32,$3B,$00,$00,$00,$00,$00,$00,$3C,$77
.byte   $20,$C0,$20,$78,$79,$79,$7A,$67,$70,$71,$67,$78,$79,$73,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$87
.byte   $20,$E0,$20,$79,$7A,$78,$79,$83,$80,$81,$82,$79,$7A,$87,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3B,$1C,$0C,$18,$1B,$0E,$FF,$3C,$67
.byte   $21,$00,$20,$73,$38,$39,$39,$39,$39,$39,$39,$39,$39,$3A,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3B,$00,$00,$00,$00,$00,$00,$3C,$82
.byte   $21,$20,$20,$77,$3B,$69,$6A,$6B,$6C,$6D,$6E,$6F,$5F,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$67
.byte   $21,$40,$20,$87,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3D,$3E,$3E,$3E,$3E,$3E,$3E,$3F,$77
.byte   $21,$60,$20,$7A,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$78,$79,$79,$7A,$78,$79,$73,$78,$83
.byte   $21,$80,$20,$7A,$3B,$0D,$11,$1D,$FF,$00,$00,$00,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$30,$31,$31,$31,$31,$32,$87,$67,$78
.byte   $21,$A0,$20,$7A,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$33,$17,$0E,$21,$1D,$34,$72,$83,$78
.byte   $21,$C0,$20,$67,$3B,$0E,$0F,$0F,$FF,$00,$00,$00,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$33,$FF,$FF,$FF,$FF,$34,$87,$72,$7A
.byte   $21,$E0,$20,$77,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$33,$FF,$FF,$FF,$FF,$34,$78,$83,$70
.byte   $22,$00,$20,$77,$3B,$0B,$1B,$17,$FF,$00,$00,$00,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$33,$FF,$FF,$FF,$FF,$34,$72,$7A,$80
.byte   $22,$20,$20,$87,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$33,$FF,$FF,$FF,$FF,$34,$77,$78,$73
.byte   $22,$40,$20,$71,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$35,$36,$36,$36,$36,$37,$87,$67,$77
.byte   $22,$60,$20,$81,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$38,$39,$39,$39,$39,$39,$3A,$77,$87
.byte   $22,$80,$20,$7A,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3B,$15,$0E,$1F,$0E,$15,$3C,$77,$78
.byte   $22,$A0,$20,$7A,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3B,$FF,$FF,$FF,$FF,$FF,$3C,$87,$67
.byte   $22,$C0,$20,$67,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3D,$3E,$3E,$3E,$3E,$3E,$3F,$78,$85
.byte   $22,$E0,$20,$83,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$67,$78,$75,$7A,$67,$72,$79,$7A,$87
.byte   $23,$00,$20,$73,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$74,$7A,$87,$78,$85,$87,$67,$78,$79
.byte   $23,$20,$20,$77,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$87,$78,$79,$73,$87,$72,$83,$72,$7A
.byte   $23,$40,$20,$87,$3D,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3F,$35,$36,$36,$36,$36,$36,$36,$36,$36,$36,$36,$37,$67,$70,$71,$87,$67,$87,$78,$83,$67
.byte   $23,$60,$20,$67,$67,$78,$75,$7A,$72,$79,$7A,$67,$78,$73,$78,$73,$67,$72,$7A,$72,$79,$7A,$78,$79,$79,$7A,$77,$80,$81,$78,$85,$67,$78,$79,$83
.byte   $23,$80,$20,$77,$82,$73,$87,$67,$87,$67,$72,$83,$67,$82,$7A,$77,$77,$77,$67,$87,$67,$70,$71,$72,$7A,$67,$80,$7A,$78,$73,$87,$77,$78,$79,$79
.byte   $23,$A0,$20,$80,$7A,$87,$78,$84,$7A,$77,$87,$78,$84,$7A,$67,$87,$77,$87,$77,$72,$83,$80,$81,$77,$67,$82,$79,$7A,$67,$77,$78,$83,$72,$7A,$67

;attributes
.byte   $23,$C0,$20,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$AF,$AF,$EF,$FF,$FF,$BF,$2F,$CF,$AA,$AA,$EE,$FF,$FF,$FF,$33,$CC,$AA,$AA,$EE,$FF,$FF
.byte   $23,$E0,$20,$BF,$23,$CC,$AA,$AA,$EE,$FF,$FF,$BB,$22,$CC,$AA,$AA,$EE,$FF,$FF,$FB,$F2,$FC,$FA,$FA,$FE,$FF,$FF,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
.byte   $FF

.segment "HUNK4HDR"
.import __HUNK4_RUN__, __HUNK4_SIZE__
.byte 0
.dbyt __HUNK4_RUN__-IPSPRGOFFSET
.dbyt __HUNK4_SIZE__

.segment "HUNK4"

; Only show 3 stats
        cmp     #$03


.segment "HUNK5HDR"
.import __HUNK5_RUN__, __HUNK5_SIZE__
.byte 0
.dbyt __HUNK5_RUN__-IPSPRGOFFSET
.dbyt __HUNK5_SIZE__

.segment "HUNK5"

; Allow skipping legal screen
        lda     #$00

.segment "DEFAULT_HIGH_SCORESHDR"
.import __DEFAULT_HIGH_SCORES_RUN__, __DEFAULT_HIGH_SCORES_SIZE__
.byte 0
.dbyt __DEFAULT_HIGH_SCORES_RUN__-IPSPRGOFFSET
.dbyt __DEFAULT_HIGH_SCORES_SIZE__

.segment "DEFAULT_HIGH_SCORES"

; replace defaultHighScoresTable
; # Convert ALPHA string to hex:
; list(map(lambda x: hex(ord(x)-64), "CHEATR"))
        ; NAME
        .byte   $0C,$01,$0E,$03,$05,$2B ; "LANCE "
        .byte   $09,$13,$2B,$01,$2B,$2B ; "IS A  "
        .byte   $03,$08,$05,$01,$14,$12 ; "CHEATR"
        .byte   $00,$00,$00,$00,$00,$00
        .byte   $01,$0C,$05,$18,$2B,$2B
        .byte   $14,$0F,$0E,$19,$2B,$2B
        .byte   $0E,$09,$0E,$14,$05,$0E
        .byte   $00,$00,$00,$00,$00,$00
        ; SCORE
        .byte   $01,$00,$00
        .byte   $00,$75,$00
        .byte   $00,$50,$00
        .byte   $00,$00,$00
        .byte   $00,$20,$00
        .byte   $00,$10,$00
        .byte   $00,$05,$00
        .byte   $00,$00,$00
        ; LV
        .byte   $09,$05,$00,$00
        .byte   $09,$05,$00,$00
        .byte   $FF

