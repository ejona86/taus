;
; Tetris AUS mod: Actually Useful Stats
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "HUNK1HDR"
.import __HUNK1_RUN__, __HUNK1_SIZE__
.byte 0
.dbyt __HUNK1_RUN__-IPSPRGOFFSET
.dbyt __HUNK1_SIZE__

.segment "HUNK1"

; at incrementPieceStat, replaces lda
       jmp statsPerBlock
afterJmpResetStatMod:

.segment "CODEHDR"
.import __CODE_RUN__, __CODE_SIZE__
.byte 0
.dbyt __CODE_RUN__-IPSPRGOFFSET
.dbyt __CODE_SIZE__

.segment "CODE"

DHT_index = $00
DHT := statsByType + DHT_index * 2
BRN_index = $01
BRN := statsByType + BRN_index * 2
EFF_index = $02
EFF := statsByType + EFF_index * 2
lvl0ScoreIndex = $03 ; stored as little endian binary, divided by 2
lvl0Score := statsByType + lvl0ScoreIndex * 2
binaryLinesIndex = $04 ; stored as little endian binary; 9 bits
binaryLines := statsByType + binaryLinesIndex * 2

statsPerBlock:
        lda     tetriminoTypeFromOrientation,x
        cmp     #$06 ; i piece
        beq     clearDrought
        lda     #$00
        jmp     afterJmpResetStatMod
clearDrought:
        lda     #$00
        sta     DHT
        sta     DHT+1
        rts

statsPerLineClear:
; Manage the burn
        lda     completedLines
        jsr     switch_s_plus_2a
        .addr   statsPerLineClearDone
        .addr   worstenBurn1
        .addr   worstenBurn2
        .addr   worstenBurn3
        .addr   healBurn
healBurn:
        lda     #$00
        sta     BRN
        sta     BRN+1
        jmp     afterBurnUpdated
worstenBurn3:
        lda     #BRN_index
        jsr     afterJmpResetStatMod
worstenBurn2:
        lda     #BRN_index
        jsr     afterJmpResetStatMod
worstenBurn1:
        lda     #BRN_index
        jsr     afterJmpResetStatMod

afterBurnUpdated:
        ; update lines
        lda     completedLines
        clc
        adc     binaryLines
        sta     binaryLines
        bcc     updateScore
        inc     binaryLines+1

updateScore:
        lda     completedLines
        asl     a
        tax
        lda     binaryPointsTable,x
        clc
        adc     lvl0Score
        sta     lvl0Score
        lda     binaryPointsTable+1,x
        adc     lvl0Score+1
        sta     lvl0Score+1

updateEff:
        lda     lvl0Score
        sta     tmp1
        lda     lvl0Score+1
        sta     tmp2
        lda     binaryLines+1
        beq     loadLines

        lsr     tmp2
        ror     tmp1
        lda     binaryLines
        sec
        ror     a
        jmp     doDiv
loadLines:
        lda     binaryLines
doDiv:
        pha
        jsr     divmod

; calculate one more bit of result
        pla
        sta     tmp3
        lda     tmp2
        asl     a
        sec
        sbc     tmp3
.if 0
        lda     #$00
        rol     a
        sta     EFF ; temporary location

        lda     #$00
        sta     tmp2
        lda     #50 ; 50 because result is /2
        jsr     divmod
        lda     tmp1
        sta     EFF+1

        lda     tmp2
        sta     tmp1
        lda     #$00
        sta     tmp2
        lda     #5 ; 5 because result is /2
        jsr     divmod
        lda     tmp1
        asl     a
        asl     a
        asl     a
        clc
        adc     tmp2
        asl     a
        clc
        adc     EFF ; place lowest bit
        sta     EFF
.else
        rol     tmp1
        lda     #$00
        rol     a
        jsr     binaryToBcd
        sta     EFF
        lda     tmp2
        sta     EFF+1
.endif

statsPerLineClearDone:
        lda     #$00
        sta     completedLines
        rts

binaryPointsTable: ; in binary, not bcd. All values pre-divided by 2
        .word   0, 40/2, 100/2, 300/2, 1200/2


.if 1
; Convert 10 bit binary number (max 999) to bcd. Double dabble algorithm.
; a:    (input) 2 high bits of binary number
;       (output) low byte
; tmp1: (input) 8 low bits of binary number
; tmp2: (output) high byte
binaryToBcd:
        ldy     #00
        sty     tmp2
.if 1
        ldy     #08
.else
        ; Uses 5 bytes to save 16 cycles
        asl     tmp1
        rol     a
        rol     tmp2
        ldy     #07
.endif

binaryToBcd_while:
        tax
        and     #$0F
        cmp     #$05
        txa                     ; Does not change carry
        bcc     binaryToBcd_tensDigit
        ; carry is set, so it will add +1
        adc     #$02
        tax
binaryToBcd_tensDigit:
        cmp     #$50
        bcc     binaryToBcd_shift
        clc
        adc     #$30
binaryToBcd_shift:
        asl     tmp1
        rol     a
        rol     tmp2
        dey
        bne     binaryToBcd_while

binaryToBcd_rts:
        rts
.endif

; Divide 16 bit number by 8 bit number; result must fit in 8 bits
; tmp1: (input)  binary dividend LO
;       (output) quotient
; tmp2: (input) binary dividend HI
;       (output) remainder
; reg a: divisor
divmod:
        sta     tmp3
        ldx     #$08
divmod_while:
        asl     tmp1
        rol     tmp2
        lda     tmp2
        bcs     divmod_withCarry
        sec
        sbc     tmp3
        bcc     divmod_checkDone
        sta     tmp2
        inc     tmp1
        jmp     divmod_checkDone
divmod_withCarry:
        sec
        sbc     tmp3
        bcs     divmod_checkDone
        sta     tmp2
        inc     tmp1
divmod_checkDone:
        dex
        bne     divmod_while
        lda     tmp1
        rts

.segment "GAME_BGHDR"
.import __GAME_BG_RUN__, __GAME_BG_SIZE__
.byte 0
.dbyt __GAME_BG_RUN__-IPSPRGOFFSET
.dbyt __GAME_BG_SIZE__

.segment "GAME_BG"

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
.byte   $21,$C0,$20,$67,$3B,$0B,$1B,$17,$FF,$00,$00,$00,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$33,$FF,$FF,$FF,$FF,$34,$87,$72,$7A
.byte   $21,$E0,$20,$77,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$33,$FF,$FF,$FF,$FF,$34,$78,$83,$70
.byte   $22,$00,$20,$77,$3B,$0E,$0F,$0F,$FF,$00,$00,$00,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$33,$FF,$FF,$FF,$FF,$34,$72,$7A,$80
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

.segment "STATS_NUMBERHDR"
.import __STATS_NUMBER_RUN__, __STATS_NUMBER_SIZE__
.byte 0
.dbyt __STATS_NUMBER_RUN__-IPSPRGOFFSET
.dbyt __STATS_NUMBER_SIZE__

.segment "STATS_NUMBER"

; Only show 3 stats
        cmp     #$03


.segment "JMP_STATS_PER_LINE_CLEARHDR"
.import __JMP_STATS_PER_LINE_CLEAR_RUN__, __JMP_STATS_PER_LINE_CLEAR_SIZE__
.byte 0
.dbyt __JMP_STATS_PER_LINE_CLEAR_RUN__-IPSPRGOFFSET
.dbyt __JMP_STATS_PER_LINE_CLEAR_SIZE__

.segment "JMP_STATS_PER_LINE_CLEAR"

; at end of addLineClearPoints, replaces "lda #0; sta completedLines"
        jsr statsPerLineClear
        nop
