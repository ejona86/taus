;
; Chart EFF
;

__CHARTSIMPORT = 1
.include "build/tetris.inc"
.include "ips.inc"
.include "chart.inc"

.export levelEffs
.export drawChartBackground
.export drawChartSprites
.export chartEffConvert

.segment "GAMEBSS"

levelEffs:
        .res    chartBarCount

.segment "CODE"

; Playfield is unused once curtain starts falling
barScratch := playfield
.ifndef CHART_HORIZ
barOffset = 0
barLength = $06         ; 300/chartValuePerPixel/8, rounded up
.else
barOffset = 20-chartBarCount/2
barLength = $0A         ; 300/chartValuePerPixel/8, rounded up
.endif

drawChartBackground:
.ifndef CHART_HORIZ
        ldy     #playfieldLiteralRow*10
        ldx     #$00
@copyLiteral:
        lda     playfieldLiteral,x
        sta     playfield,y
        iny
        inx
        cpx     #playfieldLiteralSize
        bne     @copyLiteral
.endif

        ldx     #chartBarCount/2
        stx     tmp1

@drawBar:
        dec     tmp1

        ldx     #barLength
        lda     #$EF
@clearCell:
        dex
        sta     barScratch,x
        bne     @clearCell

        lda     tmp1
        asl
        tax
        ldy     levelEffs,x
        beq     @skipFirst
        dey
        tya
        lsr
        lsr
        lsr
        tax
        beq     @skipFirst
        lda     #$F1
@setFirst:
        dex
        sta     barScratch,x
        bne     @setFirst

@skipFirst:
        lda     tmp1
        asl
        tax
        ldy     levelEffs+1,x
        beq     @skipSecond
        dey
        tya
        lsr
        lsr
        lsr
        tax
        beq     @skipSecond
@setSecond:
        inc     barScratch-1,x
        dex
        bne     @setSecond

@skipSecond:

.ifndef CHART_HORIZ
        lda     barScratch+1
        clc
        adc     #$F8-$EF
        sta     barScratch+1
        lda     barScratch+3
        adc     #$F8-$EF
        sta     barScratch+3
        lda     barScratch+5
        adc     #$F8-$EF
        sta     barScratch+5
.endif

.ifndef CHART_HORIZ
        lda     #(20-barLength)*10+barOffset
        clc
        adc     tmp1

        ldx     #barLength
        tay
@cellToPpu:
        lda     barScratch-1,x
        sta     playfield,y
        tya
        adc     #10
        tay
        dex
        bne     @cellToPpu
.else
        lda     #barOffset
        clc
        adc     tmp1
        tax
        lda     multBy10Table,x
        sta     playfieldAddr

        ldx     #barLength
        ldy     #$00
@cellToPpu:
        lda     barScratch,y
        sta     (playfieldAddr),y
        iny
        dex
        bne     @cellToPpu

        lda     #$00
        sta     playfieldAddr
.endif
        lda     tmp1
        bne     @drawBar

        rts

; stageSpriteForCurrentPiece for offsets
drawChartSprites:
        ldx     #chartBarCount

.ifndef CHART_HORIZ
        lda     #$60+(barOffset+chartBarCount/2)*8-4
.else
        lda     #$2F+20*8-4
.endif
        sta     tmp1
@barEndcap:
        dex

        lda     levelEffs,x
        beq     @skip

.ifndef CHART_HORIZ
        lda     #$2F+20*8
        sec
        sbc     levelEffs,x
        cmp     #$2F+20*8-8
        bmi     @withinRange
        lda     #$2F+20*8-8
@withinRange:
.else
        lda     tmp1
.endif
        ldy     oamStagingLength
        sta     oamStaging,y
        inc     oamStagingLength
        iny

        lda     #$F7
        ldy     oamStagingLength
        sta     oamStaging,y
        inc     oamStagingLength
        iny

        lda     #$22    ; behind background; sprite palette 2
        ldy     oamStagingLength
        sta     oamStaging,y
        inc     oamStagingLength
        iny

.ifndef CHART_HORIZ
        lda     tmp1
.else
        lda     #$60-8
        clc
        adc     levelEffs,x
.endif
        ldy     oamStagingLength
        sta     oamStaging,y
        inc     oamStagingLength
        iny

@skip:
        lda     tmp1
        sec
        sbc     #$04
        sta     tmp1
        txa
        bne     @barEndcap

        rts

PRECISION = 1
.ifndef CHART_HORIZ
; Divide 8 bit number by 3. Implemented via multiplying by a fixed-point 1/3.
; 1/3 is encoded as $55 in a binary byte, but since it is truncated the product
; may be too small. This produces results like 3/3 = 0 and 6/3 = 1. So instead,
; we use $56, which fixes the issue with numbers smaller than 128. To fix
; numbers up to 255, we compute two more bits of precision using $156.
;
; req a: (input) dividend
;        (output) quotient
.if 0
div3:
        sta     tmp1
        lsr
.ifdef PRECISION
        clc
        adc     tmp1
        ror
        lsr
.endif
        clc
        adc     tmp1
        ror
        lsr
        clc
        adc     tmp1
        ror
        lsr
        clc
        adc     tmp1
        ror
        lsr
        rts

chartEffConvert := div3

.else

; Divide by 3.125. Implemented by multiplying by fixed-point 1/3.125=0.32.
; Encoded as binary it is $52. That produces quite acceptable results but
; for 6 numbers it rounds up, like with 128 (the smallest failure) it produces
; 41 when the precise answer is 40.96 (all the wrong answers are off by .04).
; To fix those cases requires adding 4 more bits to have $51F.
;
; req a: (input) dividend
;        (output) quotient
div3125:
.ifndef PRECISION
        sta     tmp1
        lsr
        lsr
        lsr
        clc
        adc     tmp1
        ror
        lsr
        clc
        adc     tmp1
        ror
        lsr
        rts
.else
        sta     tmp1
        lsr
        clc
        adc     tmp1
        ror
        clc
        adc     tmp1
        ror
        clc
        adc     tmp1
        ror
        clc
        adc     tmp1
        ror
        lsr
        lsr
        lsr
        clc
        adc     tmp1
        ror
        lsr
        clc
        adc     tmp1
        ror
        lsr
        rts
.endif

chartEffConvert := div3125
.endif

.else

div2:
        lsr
        rts

chartEffConvert := div2
.endif

.ifndef CHART_HORIZ
playfieldLiteralRow = 20-6-3
playfieldLiteralSize = 30
playfieldLiteral:
.byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte   $FF,$0E,$0F,$0F,$FF,$15,$18,$10,$FF,$FF
.byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

.export chart_attributetable_patch
chart_attributetable_patch:
.byte   $23,$E3,$03,$FA,$FA,$FE
.byte   $FF
.endif

.segment "CHART_IPSCHR"

.ifndef CHART_HORIZ
        ips_tilehdr CHR01+CHR_RIGHT,$EF
        ; blank
        .incbin "build/taus.chrs/20"

        ips_tilehdr CHR01+CHR_RIGHT,$F0
        ;  |
        .incbin "build/taus.chrs/21"

        ips_tilehdr CHR01+CHR_RIGHT,$F1
        ; |
        .incbin "build/taus.chrs/22"

        ips_tilehdr CHR01+CHR_RIGHT,$F2
        ; ||
        .incbin "build/taus.chrs/23"

        ips_tilehdr CHR01+CHR_RIGHT,$F7
        ; endcap
        .incbin "build/taus.chrs/18"

        ips_tilehdr CHR01+CHR_RIGHT,$F8
        ; blank, with gridline
        .incbin "build/taus.chrs/24"

        ips_tilehdr CHR01+CHR_RIGHT,$F9
        ;  |, with gridline
        .incbin "build/taus.chrs/25"

        ips_tilehdr CHR01+CHR_RIGHT,$FA
        ; |, with gridline
        .incbin "build/taus.chrs/26"

        ips_tilehdr CHR01+CHR_RIGHT,$FB
        ; ||, with gridline
        .incbin "build/taus.chrs/27"
.else
        ips_tilehdr CHR01+CHR_RIGHT,$EF
        ; blank
        .incbin "build/taus.chrs/30"

        ips_tilehdr CHR01+CHR_RIGHT,$F0
        ; _
        .incbin "build/taus.chrs/31"

        ips_tilehdr CHR01+CHR_RIGHT,$F1
        ; -
        .incbin "build/taus.chrs/32"

        ips_tilehdr CHR01+CHR_RIGHT,$F2
        ; =
        .incbin "build/taus.chrs/33"

        ips_tilehdr CHR01+CHR_RIGHT,$F7
        ; endcap
        .incbin "build/taus.chrs/34"

        ips_tilehdr CHR01+CHR_RIGHT,$F8
        ; blank
        .incbin "build/taus.chrs/30"

        ips_tilehdr CHR01+CHR_RIGHT,$F9
        ; _
        .incbin "build/taus.chrs/31"

        ips_tilehdr CHR01+CHR_RIGHT,$FA
        ; -
        .incbin "build/taus.chrs/32"

        ips_tilehdr CHR01+CHR_RIGHT,$FB
        ; =
        .incbin "build/taus.chrs/33"
.endif
