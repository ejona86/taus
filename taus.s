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

initGameState_mod:
.import __GAMEBSS_SIZE__, __GAMEBSS_RUN__
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
        ldx     #$0F
        lda     #$00
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
        beq     @checkForAddrToCopy
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
@checkForAddrToCopy:
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
        ; Handled by renderStats
        lda     #<chart_attributetable_patch
        sta     copyToPpuDuringRenderAddr
        lda     #>chart_attributetable_patch
        sta     copyToPpuDuringRenderAddr+1
        lda     outOfDateRenderFlags
        ora     #$40
        sta     outOfDateRenderFlags

@checkInput:
        ; require pressing start independent of score
        lda     newlyPressedButtons_player1
        cmp     #$10
        bne     @ret
        lda     player1_score+2
        cmp     playState_updateGameOverCurtain+$63     ; $9A50: #$03, but can be changed by Game Genie
        bcc     @exitGame
        jsr     endingAnimation_maybe
@exitGame:
        jmp     playState_updateGameOverCurtain+$53     ; $9A64
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
        .incbin "build/taus_game.nam.stripe"
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

; at beginning of initGameState, replaces "ldx #$0F; lda #$00"
        jsr initGameState_mod
        nop

.segment "JMP_POST_GAME_STATSHDR"
        ips_hunkhdr     "JMP_POST_GAME_STATS"

.segment "JMP_POST_GAME_STATS"

; within @curtainFinished of playState_updateGameOverCurtain, replacing
; "lda player1_score+2; cmp #$03"
        jmp     postGameStats
        ; This leaves the cmp cut in half, but we don't jump back to it so this
        ; is okay. We want to leave the #$03 intact to support Game Genie codes
        ; that skip the ending animation.

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
