;
; Display the various screens of Tetris
;

.include "build/tetris.inc"

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

; at nmi, replaces "jsr render"
        nop
        nop
        nop

.segment "JMP_MAIN_LOOP_ITERHDR"
.import __JMP_MAIN_LOOP_ITER_RUN__, __JMP_MAIN_LOOP_ITER_SIZE__
.byte 0
.dbyt __JMP_MAIN_LOOP_ITER_RUN__-IPSPRGOFFSET
.dbyt __JMP_MAIN_LOOP_ITER_SIZE__

.segment "JMP_MAIN_LOOP_ITER"

; at mainLoop, replaces "jsr branchOnGameMode"
       jsr      mainLoopIterMod


.segment "MAINHDR"
.import __MAIN_RUN__, __MAIN_SIZE__
.byte 0
.dbyt __MAIN_RUN__-IPSPRGOFFSET
.dbyt __MAIN_SIZE__

.segment "MAIN"

screenToDisplay := levelNumber
backgroundRendered := levelNumber+1

mainLoopIterMod:
        lda     newlyPressedButtons
        beq     checkForRender
        lda     #$00
        sta     backgroundRendered
        inc     screenToDisplay
        lda     screenToDisplay
        cmp     #screens
        bne     checkForRender
        lda     #$00
        sta     screenToDisplay

checkForRender:
        lda     backgroundRendered
        bne     mainLoopIterMod_return
        inc     backgroundRendered
        jsr     load_background

mainLoopIterMod_return:
        lda     #$00    ; wait for vsync
        sta     $A7
        rts


load_background:
        jsr     setPPUColorControl
        jsr     disableNmi
        lda     #$10
        jsr     setMMC1Control
        ldx     screenToDisplay
        lda     bank0s,x
        jsr     changeCHRBank0
        ldx     screenToDisplay
        lda     bank1s,x
        jsr     changeCHRBank1
        lda     screenToDisplay
        jsr     my_bulkCopyToPpu
        lda     screenToDisplay
        clc
        adc     #screens
        jsr     my_bulkCopyToPpu

        ; screen-specific hacks
        lda     screenToDisplay
        cmp     #$03
        bne     continue
        ; level menu, type a
        jsr     bulkCopyToPpu
        .addr   height_menu_nametablepalette_patch
        jsr     bulkCopyToPpu
        .addr   high_scores_nametable

continue:
        jsr     waitForVBlankAndDisableNMI
        jsr     waitForVerticalBlankingInterval
        jsr     updateAudioAndWaitForVBlankTwiceAndDisableNMI
        jsr     waitForVerticalBlankingInterval
        rts

; index passed as 'a'
my_bulkCopyToPpu:
        asl     a
        tax
        lda     palettes,x ; will read into nametables as well
        sta     tmp1
        lda     palettes+1,x
        sta     tmp2
        jsr     LAAF2
        rts

screens = 10
bank0s:
        .byte   0, 0, 0, 0, 0, 3, 0, 2, 2, 1
bank1s:
        .byte   0, 0, 0, 0, 0, 3, 0, 2, 2, 1
palettes:
        .addr   legal_screen_palette
        .addr   menu_palette
        .addr   menu_palette
        .addr   menu_palette
        .addr   menu_palette
        .addr   game_palette
        .addr   menu_palette
        .addr   ending_palette
        .addr   ending_palette
        .addr   ending_palette
nametables:
        .addr   legal_screen_nametable
        .addr   title_screen_nametable
        .addr   game_type_menu_nametable
        .addr   level_menu_nametable
        .addr   level_menu_nametable
        .addr   game_nametable
        .addr   enter_high_score_nametable
        .addr   type_a_ending_nametable
        .addr   type_b_ending_nametable
        .addr   type_b_lvl9_ending_nametable