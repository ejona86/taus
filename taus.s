;
; Tetris AUS mod: Actually Useful Stats
;

.include "build/tetris.inc"
.include "ips.inc"
.include "chart.inc"

;TESTING_POST_GAME_STATS = 1

.segment "HUNK1HDR"
        ips_hunkhdr     "HUNK1"

.segment "HUNK1"

; at incrementPieceStat, replaces lda
       jmp statsPerBlock
afterJmpResetStatMod:

.segment "BSS"

copyToPpuDuringRenderAddr:
        .res    2

.segment "GAMEBSS"

DHT_index = $00
DHT := statsByType + DHT_index * 2
BRN_index = $01
BRN := statsByType + BRN_index * 2
EFF_index = $02
EFF := statsByType + EFF_index * 2
TRT_index = $03
TRT := statsByType + TRT_index * 2

; stored as little endian bcd
TRNS:
        .res    3
tetrisLines:
        .res    1
; stored as little endian binary, divided by 2
lvl0Score:
        .res    2
; stored as little endian binary; 9 bits
binaryLines:
        .res    2

; Maxes out at $0A, at which point gets set back to 0
chartLevelLines:
        .res    1
chartLevelPoints:
        .res    2
levelEffIdx:
        .res    1
chartDrawn:
        .res    1

.segment "CODEHDR"
        ips_hunkhdr     "CODE"

.segment "CODE"

renderMod:
        jsr     render

        lda     copyToPpuDuringRenderAddr+1
        beq     @ret
        sta     tmp2
        lda     copyToPpuDuringRenderAddr
        sta     tmp1
        jsr     copyToPpu
        lda     #$00
        sta     copyToPpuDuringRenderAddr
        sta     copyToPpuDuringRenderAddr+1
@ret:
        rts

initGameState_mod:
.import __GAMEBSS_SIZE__, __GAMEBSS_RUN__
        jsr     memset_page
        lda     #$00
        ldx     #<__GAMEBSS_SIZE__
@clearByte:
        sta     __GAMEBSS_RUN__-1,x
        dex
        bne     @clearByte

.ifdef TESTING_POST_GAME_STATS
        lda     #$0A
        sta     player1_playState
        lda     #300/2
        jsr     chartEffConvert
.if 1
        ; Various test cases

        ; separate; left larger, right larger
        sta     levelEffs
        sta     levelEffs+3
        lda     #14
        sta     levelEffs+1
        sta     levelEffs+2

        ; together; left larger, right larger
        lda     #16
        sta     levelEffs+4
        sta     levelEffs+7
        lda     #14
        sta     levelEffs+5
        sta     levelEffs+6

        ; exactly a difference of 8; left larger, right larger
        lda     #16
        sta     levelEffs+8
        sta     levelEffs+11
        lda     #8
        sta     levelEffs+9
        sta     levelEffs+10

        ; short
        ; together, left larger
        lda     #9
        sta     levelEffs+12
        lda     #8
        sta     levelEffs+13
        ; separate, right is zero
        sta     levelEffs+14
.elseif 0
        ; All maxed out
        ldx     #$00
@initTestEffs:
        sta     levelEffs,x
        inx
        cpx     #chartBarCount
        bne     @initTestEffs
.else
        ; Descending
        ldx     #$00
        lda     #$30
@initTestEffs:
        sta     levelEffs,x
        inx
        sta     levelEffs,x
        inx
        sec
        sbc     #$01
        cpx     #chartBarCount
        bne     @initTestEffs
.endif
.endif
        rts

statsPerBlock:
        lda     tetriminoTypeFromOrientation,x
        cmp     #$06 ; i piece
        beq     @clearDrought
        lda     #$00
        jmp     afterJmpResetStatMod
@clearDrought:
        lda     #$00
        sta     DHT
        sta     DHT+1
        rts

statsPerLineClear:
; Manage the burn
        lda     completedLines
        jsr     switch_s_plus_2a
        .addr   statsPerLineClearDone
        .addr   @worstenBurn1
        .addr   @worstenBurn2
        .addr   @worstenBurn3
        .addr   @healBurn
@healBurn:
        lda     #$00
        sta     BRN
        sta     BRN+1
        jmp     @afterBurnUpdated
@worstenBurn3:
        lda     #BRN_index
        jsr     afterJmpResetStatMod
@worstenBurn2:
        lda     #BRN_index
        jsr     afterJmpResetStatMod
@worstenBurn1:
        lda     #BRN_index
        jsr     afterJmpResetStatMod

@afterBurnUpdated:
        ; update lines
        lda     completedLines
        clc
        adc     binaryLines
        sta     binaryLines
        bcc     @updateScore
        inc     binaryLines+1

@updateScore:
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

;updateLevelEff:
        ldx     completedLines
        ldy     scorePerLineTable,x
@addToLevelScore:
        tya
        clc
        adc     chartLevelPoints
        sta     chartLevelPoints
        lda     #$00
        adc     chartLevelPoints+1
        sta     chartLevelPoints+1
        inc     chartLevelLines
        lda     chartLevelLines
        cmp     #$0A
        bne     @addToLevelScore_iter
        ; compute level EFF
        txa
        pha
        tya
        pha
        lda     chartLevelPoints
        sta     tmp1
        lda     chartLevelPoints+1
        sta     tmp2
        lda     chartLevelLines
        jsr     divmod
        lda     tmp1
        jsr     chartEffConvert
        ldx     levelEffIdx
        cpx     #chartBarCount
        beq     @dontSave
        sta     levelEffs,x
        inc     levelEffIdx
@dontSave:
        lda     #$00
        sta     chartLevelLines
        sta     chartLevelPoints
        sta     chartLevelPoints+1
        pla
        tay
        pla
        tax
@addToLevelScore_iter:
        dex
        bne     @addToLevelScore

@updateEff:
        lda     lvl0Score
        sta     tmp1
        lda     lvl0Score+1
        sta     tmp2
        lda     binaryLines+1
        beq     @loadLines

        lsr     tmp2
        ror     tmp1
        lda     binaryLines
        sec
        ror     a
        jmp     doDiv
@loadLines:
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

        rol     tmp1
        lda     #$00
        rol     a
        jsr     binaryToBcd
        sta     EFF
        lda     tmp2
        sta     EFF+1

@updateTrt:
        lda     completedLines
        cmp     #$04
        bne     @calcTrt
        lda     tetrisLines
        clc
        adc     #$04
        sta     tetrisLines
@calcTrt:
        lda     tetrisLines
        sta     tmp1
        lda     #$00
        sta     tmp2
        jsr     multiplyBy100
        lda     binaryLines
        jsr     divmod
        lda     #$00
        jsr     binaryToBcd
        sta     TRT
        lda     tmp2
        sta     TRT+1

;@checkForTrns:
        lda     TRNS
        bne     @doneCheckingTrns
        lda     TRNS+1
        bne     @doneCheckingTrns
        lda     TRNS+2
        bne     @doneCheckingTrns
        lda     startLevel
        cmp     levelNumber
        beq     @doneCheckingTrns
        lda     score
        sta     TRNS
        lda     score+1
        sta     TRNS+1
        lda     score+2
        sta     TRNS+2
@doneCheckingTrns:

statsPerLineClearDone:
        lda     #$00
        sta     completedLines
        rts

binaryPointsTable: ; in binary, not bcd. All values pre-divided by 2
        .word   0, 40/2, 100/2, 300/2, 1200/2
scorePerLineTable: ; All values pre-divided by 2
        .byte   0, 40/1/2, 100/2/2, 300/3/2, 1200/4/2

renderStats:
        lda     TRNS
        bne     @hasTrns
        lda     TRNS+1
        bne     @hasTrns
        lda     TRNS+2
        bne     @hasTrns
        beq     @ret
@hasTrns:
        lda     #$22
        sta     PPUADDR
        lda     #$C4
        sta     PPUADDR
        lda     TRNS+2
        jsr     twoDigsToPPU
        lda     TRNS+1
        jsr     twoDigsToPPU
        lda     TRNS
        jsr     twoDigsToPPU
@ret:
        lda     #$00
        sta     $B0
        rts

postGameStats:
        lda     chartDrawn
        bne     @chartOnPlayfield
        inc     chartDrawn
        jsr     drawChartBackground

@chartOnPlayfield:
        jsr     drawChartSprites

        lda     frameCounter
        and     #$03
        bne     @checkInput
        lda     #20
        sec
        sbc     chartDrawn
        beq     @checkInput
        sta     vramRow
        inc     chartDrawn
.import chart_attributetable_patch
        cmp     #20-6-2
        bne     @checkInput
        lda     #<chart_attributetable_patch
        sta     copyToPpuDuringRenderAddr
        lda     #>chart_attributetable_patch
        sta     copyToPpuDuringRenderAddr+1

@checkInput:
        ; require pressing start independent of score
        lda     newlyPressedButtons_player1
        cmp     #$10
        bne     @ret
        lda     player1_score+2
        cmp     #$03
        bcc     @exitGame
        jsr     endingAnimation_maybe
@exitGame:
        jmp     $9A64
@ret:   rts


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

@while:
        tax
        and     #$0F
        cmp     #$05
        txa                     ; Does not change carry
        bcc     @tensDigit
        ; carry is set, so it will add +1
        adc     #$02
        tax
@tensDigit:
        cmp     #$50
        bcc     @shift
        clc
        adc     #$30
@shift:
        asl     tmp1
        rol     a
        rol     tmp2
        dey
        bne     @while

        rts

; Divide 16 bit number by 8 bit number; result must fit in 8 bits
; tmp1: (input)  binary dividend LO
;       (output) quotient
; tmp2: (input) binary dividend HI
;       (output) remainder
; reg a: divisor
divmod:
        sta     tmp3
        ldx     #$08
@while:
        asl     tmp1
        rol     tmp2
        lda     tmp2
        bcs     @withCarry
        sec
        sbc     tmp3
        bcc     @checkDone
        sta     tmp2
        inc     tmp1
        jmp     @checkDone
@withCarry:
        sec
        sbc     tmp3
        bcs     @checkDone
        sta     tmp2
        inc     tmp1
@checkDone:
        dex
        bne     @while
        lda     tmp1
        rts

; Multiply 16 bit number by 100
; tmp1: (input)  LO
;       (output) LO
; tmp2: (input)  HI
;       (output) HI
multiplyBy100:
        asl     tmp1    ; input =<< 2
        rol     tmp2
        asl     tmp1
        rol     tmp2

        lda     tmp1    ; output = input
        ldx     tmp2

        asl     tmp1    ; input =<< 3
        rol     tmp2
        asl     tmp1
        rol     tmp2
        asl     tmp1
        rol     tmp2

        clc             ; output += input
        adc     tmp1
        tay
        txa
        adc     tmp2
        tax
        tya

        asl     tmp1    ; input =<< 1
        rol     tmp2

        clc             ; output += input
        adc     tmp1
        tay
        txa
        adc     tmp2

        sty     tmp1
        sta     tmp2
        rts

.segment "GAME_BGHDR"
        ips_hunkhdr     "GAME_BG"

.segment "GAME_BG"

; game_nametable
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
.byte   $22,$40,$20,$71,$3B,$1D,$1B,$1D,$FF,$00,$00,$00,$54,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$35,$36,$36,$36,$36,$37,$87,$67,$77
.byte   $22,$60,$20,$81,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$38,$39,$39,$39,$39,$39,$3A,$77,$87
.byte   $22,$80,$20,$7A,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3B,$15,$0E,$1F,$0E,$15,$3C,$77,$78
.byte   $22,$A0,$20,$7A,$3B,$1D,$1B,$17,$1C,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3B,$FF,$FF,$FF,$FF,$FF,$3C,$87,$67
.byte   $22,$C0,$20,$67,$3B,$FF,$FF,$24,$24,$24,$24,$24,$24,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$3D,$3E,$3E,$3E,$3E,$3E,$3F,$78,$85
.byte   $22,$E0,$20,$83,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$67,$78,$75,$7A,$67,$72,$79,$7A,$87
.byte   $23,$00,$20,$73,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$74,$7A,$87,$78,$85,$87,$67,$78,$79
.byte   $23,$20,$20,$77,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$33,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$34,$87,$78,$79,$73,$87,$72,$83,$72,$7A
.byte   $23,$40,$20,$87,$3D,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3F,$35,$36,$36,$36,$36,$36,$36,$36,$36,$36,$36,$37,$67,$70,$71,$87,$67,$87,$78,$83,$67
.byte   $23,$60,$20,$67,$67,$78,$75,$7A,$72,$79,$7A,$67,$78,$73,$78,$73,$67,$72,$7A,$72,$79,$7A,$78,$79,$79,$7A,$77,$80,$81,$78,$85,$67,$78,$79,$83
.byte   $23,$80,$20,$77,$82,$73,$87,$67,$87,$67,$72,$83,$67,$82,$7A,$77,$77,$77,$67,$87,$67,$70,$71,$72,$7A,$67,$80,$7A,$78,$73,$87,$77,$78,$79,$79
.byte   $23,$A0,$20,$80,$7A,$87,$78,$84,$7A,$77,$87,$78,$84,$7A,$67,$87,$77,$87,$77,$72,$83,$80,$81,$77,$67,$82,$79,$7A,$67,$77,$78,$83,$72,$7A,$67

;attributes
.byte   $23,$C0,$20,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte               $FF,$FF,$FF,$AF,$AF,$EF,$FF,$FF
.byte               $BF,$2F,$CF,$AA,$AA,$EE,$FF,$FF
.byte               $FF,$33,$CC,$AA,$AA,$EE,$FF,$FF
.byte   $23,$E0,$20,$FF,$33,$CC,$AA,$AA,$EE,$FF,$FF
.byte               $BF,$03,$CC,$AA,$AA,$EE,$FF,$FF
.byte               $FB,$F2,$FC,$FA,$FA,$FE,$FF,$FF
.byte               $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
.byte   $FF

.segment "STATS_NUMBERHDR"
        ips_hunkhdr     "STATS_NUMBER"

.segment "STATS_NUMBER"

; Only show 3 stats
        cmp     #$04


.segment "JMP_STATS_PER_LINE_CLEARHDR"
        ips_hunkhdr     "JMP_STATS_PER_LINE_CLEAR"

.segment "JMP_STATS_PER_LINE_CLEAR"

; at end of addLineClearPoints, replaces "lda #0; sta completedLines"
        jsr statsPerLineClear
        nop

.segment "JMP_INIT_GAME_STATEHDR"
        ips_hunkhdr     "JMP_INIT_GAME_STATE"

.segment "JMP_INIT_GAME_STATE"

; at beginning of initGameState, replaces "jsr memset_page"
        jsr initGameState_mod

.segment "JMP_POST_GAME_STATSHDR"
        ips_hunkhdr     "JMP_POST_GAME_STATS"

.segment "JMP_POST_GAME_STATS"

; within @curtainFinished of playState_updateGameOverCurtain, replacing
; "lda player1_score+2; cmp #$03"
        jmp     postGameStats
        nop

.segment "JMP_RENDER_MODHDR"
        ips_hunkhdr     "JMP_RENDER_MOD"

.segment "JMP_RENDER_MOD"

; within nmi, replaces "jsr render"
        jsr     renderMod

.segment "JMP_RENDER_STATSHDR"
        ips_hunkhdr     "JMP_RENDER_STATS"

.segment "JMP_RENDER_STATS"

; within render_play_digits, after L9639, replaces "lda #$00; sta $B0"
        jsr     renderStats
        nop

.segment "IPSCHR"

        ips_tilehdr CHR01+CHR_RIGHT,$54
        ; percent
        .incbin "build/taus.chrs/00"
