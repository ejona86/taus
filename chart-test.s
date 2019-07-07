;
; Shell to display EFF chart, for testing
;

.include "build/tetris.inc"
.include "ips.inc"
.include "chart.inc"

.segment "JMP_MAIN_LOOP_ITERHDR"
        ips_hunkhdr     "JMP_MAIN_LOOP_ITER"

.segment "JMP_MAIN_LOOP_ITER"

; at mainLoop, replaces "jsr branchOnGameMode"
       jsr      mainLoopIterMod


.segment "CODEHDR"
        ips_hunkhdr     "CODE"

.segment "CODE"

backgroundRendered := levelNumber

mainLoopIterMod:
        lda     backgroundRendered
        beq     @drawBackground
        jmp     @return
@drawBackground:
        inc     backgroundRendered
        jsr     load_background

        ldx     #chartBarCount
@copyEffs:
        txa
        pha
        lda     levelEffsRaw-1,x
        jsr     chartEffConvert
        tay
        pla
        tax
        tya

        sta     levelEffs-1,x
        dex
        bne     @copyEffs

        jmp     drawChartBackground
@return:
        jsr     drawChartSprites
        lda     #$01
        sta     $A7     ; wait for vsync
        rts

load_background:
        jsr     updateAudioWaitForNmiAndDisablePpuRendering
        jsr     disableNmi
        lda     #$10
        jsr     setMMC1Control
        lda     #$03
        jsr     changeCHRBank0
        lda     #$03
        jsr     changeCHRBank1
        jsr     bulkCopyToPpu
        .addr   game_palette
        jsr     bulkCopyToPpu
        .addr   game_nametable

        jsr     waitForVBlankAndEnableNmi
        jsr     updateAudioWaitForNmiAndEnablePpuRendering
        rts

levelEffsRaw:
        .byte   300/2,40/2
        .byte   200/2,300/2
        .byte   100/2,283/2
        .byte   123/2,40/2
        .byte   90/2,48/2
        .byte   230/2,90/2
        .byte   280/2,250/2
        .byte   50/2,80/2
        .byte   120/2,160/2
        .byte   200/2,240/2
