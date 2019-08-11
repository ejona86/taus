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

; The chart consists of 20 bars within the playfield. The bottom of each bar is
; drawn using the nametable. The nametable tiles are coarse, so are only used
; for each full 8 pixels of bar height. This uses 4 tiles (although we could
; reuse 2 tiles). The topmost pixel of the bar is purposefully excluded since
; it is a different color. The top of the bar (1-8 pixels) is drawn using a
; sprite, which can be placed precisely in the proper position.  We make sure
; to always have 8 pixels-worth of sprite height, since that is the maximum that
; can be missed from the nametable. The nametable handles gridlines, so the
; sprite is placed behind the nametable to let the gridline show on top of the
; bars. The gridlines require a duplicate of each nametable tile, which uses 4
; more tiles.
;
; We go well out of our way to reduce the number of sprites per scanline. For
; every two bars (8 pixels of width) we "reserve" 1 sprite per scanline. Since
; there is a maximum of 20 bars to display, this can reach the 8
; sprite-per-scanline limit after 16 bars. But that's only in the worst-case.
; Generally we can hope to "luck out" since games of 200 lines are uncommon
; and are unlikely to have consistent enough EFF to cause 9+ sprites to share a
; scanline.
;
; If we weren't concerned with the 8 sprite limit, we would only need one tile
; for the sprite. However, we choose to use 9 more tiles to reduce the sprite
; load per scanline. Eight of the tiles are for a relative difference between
; the two bars, but they may only provide 1 pixel of bar height. So we have
; another tile that provides 7 more pixels of height to both bars. Note that it
; is important to only add 7 pixels, because any more would increase the
; smallest bar size we could display.

.segment "GAMEBSS"

levelEffs:
        .res    chartBarCount

.segment "CODE"

; Playfield is unused once curtain starts falling
barScratch := playfield
barOffset = 0
barLength = $06         ; 300/chartValuePerPixel/8, rounded up

drawChartBackground:
        ; We can't draw anything less than 8 pixels high
        ldx     #$00
@checkRange:
        lda     levelEffs,x
        beq     @rangeOkay
        cmp     #$08
        bpl     @rangeOkay
        lda     #$08
        sta     levelEffs,x
@rangeOkay:
        inx
        cpx     #chartBarCount
        bne     @checkRange

        ldy     #playfieldLiteralRow*10
        ldx     #$00
@copyLiteral:
        lda     playfieldLiteral,x
        sta     playfield,y
        iny
        inx
        cpx     #playfieldLiteralSize
        bne     @copyLiteral

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

        lda     tmp1
        bne     @drawBar

        rts

; We always use two sprites per pair of columns. If the columns are close in
; size, then we use an offset double endcap plus a sprite of 7 pixels of bar.
; If the columns have over a 7 pixel difference, then we use one lone endcap
; per bar.
drawChartSprites:
        ldx     #$00
@barEndcap:
        lda     levelEffs,x
        beq     @skip

        lda     #$22    ; behind background; sprite palette 2
        sta     tmp2

        txa
        asl     a
        asl     a
        sta     spriteXOffset

        lda     levelEffs+1,x
        beq     @diffTooLarge

        sec
        sbc     levelEffs,x
        bmi     @negative
        cmp     #$08
        bmi     @positive
@diffTooLarge:
        ; Draw the two bars separately
        lda     #$F7
        sta     tmp1
        lda     levelEffs,x
        sta     spriteYOffset
        jsr     stageChartSprite

        lda     levelEffs+1,x
        beq     @skip
        sta     spriteYOffset
        lda     #$62    ; behind background; sprite palette 2; flip horiz
        sta     tmp2
        jsr     stageChartSprite

        jmp     @skip
@positive:
        sta     tmp1
        lda     levelEffs,x
        sta     spriteYOffset
        bne     @computedDiff   ; unconditional
@negative:
        cmp     #<(-$07)
        bmi     @diffTooLarge

        eor     #$FF
        clc
        adc     #$01
        sta     tmp1
        lda     levelEffs+1,x
        sta     spriteYOffset

        lda     #$62    ; behind background; sprite palette 2; flip horiz
        sta     tmp2
@computedDiff:

        lda     #$07
        clc
        adc     spriteYOffset
        sta     spriteYOffset
        lda     #$E7
        clc
        adc     tmp1
        sta     tmp1
        jsr     stageChartSprite

        lda     #$F6
        sta     tmp1
        lda     spriteYOffset
        sec
        sbc     #$08
        sta     spriteYOffset
        jsr     stageChartSprite

@skip:
        inx
        inx
        cpx     #chartBarCount
        bne     @barEndcap

        rts


; Stage sprite for chart. Does not use reg x.
; spriteYOffset: (input) relative to playfield; positive is up
; spriteXOffset: (input) relative to playfield
; tmp1:          (input) tile index
; tmp2:          (input) attributes
stageChartSprite:
        lda     #$2F+20*8
        sec
        sbc     spriteYOffset
        ldy     oamStagingLength
        sta     oamStaging,y
        inc     oamStagingLength
        iny

        lda     tmp1
        sta     oamStaging,y
        inc     oamStagingLength
        iny

        lda     tmp2
        sta     oamStaging,y
        inc     oamStagingLength
        iny

        lda     spriteXOffset
        clc
        adc     #$60+barOffset*8
        sta     oamStaging,y
        inc     oamStagingLength
        iny

        rts

PRECISION = 1
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

.segment "CHART_IPSCHR"

        ips_tilehdr CHR01+CHR_RIGHT,$E7
        ; endcap difference = 0
        .incbin "build/taus.chrs/10"

        ips_tilehdr CHR01+CHR_RIGHT,$E8
        ; endcap difference = 1
        .incbin "build/taus.chrs/11"

        ips_tilehdr CHR01+CHR_RIGHT,$E9
        ; endcap difference = 2
        .incbin "build/taus.chrs/12"

        ips_tilehdr CHR01+CHR_RIGHT,$EA
        ; endcap difference = 3
        .incbin "build/taus.chrs/13"

        ips_tilehdr CHR01+CHR_RIGHT,$EB
        ; endcap difference = 4
        .incbin "build/taus.chrs/14"

        ips_tilehdr CHR01+CHR_RIGHT,$EC
        ; endcap difference = 5
        .incbin "build/taus.chrs/15"

        ips_tilehdr CHR01+CHR_RIGHT,$ED
        ; endcap difference = 6
        .incbin "build/taus.chrs/16"

        ips_tilehdr CHR01+CHR_RIGHT,$EE
        ; endcap difference = 7
        .incbin "build/taus.chrs/17"

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

        ips_tilehdr CHR01+CHR_RIGHT,$F6
        ; || 7 pixel high
        .incbin "build/taus.chrs/19"

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
