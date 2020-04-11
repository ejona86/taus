;
; Display the various screens of Tetris
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "HUNK1"
        ips_segment     "HUNK1",$800E

; at nmi, replaces "jsr render"
        nop
        nop
        nop

.segment "JMP_MAIN_LOOP_ITER"
        ips_segment     "JMP_MAIN_LOOP_ITER",$8138

; at mainLoop, replaces "jsr branchOnGameMode"
       jsr      mainLoopIterMod


.segment "CODE"
        ips_segment     "CODE",unreferenced_data1,$0637

screenToDisplay := levelNumber
backgroundRendered := levelNumber+1

mainLoopIterMod:
        lda     newlyPressedButtons_player1
        beq     @checkForRender
        lda     #$00
        sta     backgroundRendered
        inc     screenToDisplay
        lda     screenToDisplay
        cmp     #screens
        bne     @checkForRender
        lda     #$00
        sta     screenToDisplay

@checkForRender:
        lda     backgroundRendered
        bne     @return
        inc     backgroundRendered
        jsr     load_background

@return:
        lda     #$00    ; wait for vsync
        sta     $A7
        rts


load_background:
        jsr     updateAudioWaitForNmiAndDisablePpuRendering
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
        cmp     #$07
        bpl     @continue
        jsr     switch_s_plus_2a
        .addr   @continue
        .addr   @continue
        .addr   @continue
        .addr   @levelMenuTypeA
        .addr   @levelMenuTypeB
        .addr   @continue
        .addr   @highScoreEntry

@levelMenuTypeA:
        jsr     bulkCopyToPpu
        .addr   height_menu_nametablepalette_patch
        ; fall-through

@levelMenuTypeB:
@highScoreEntry:
        ; This is necessary on type a, since the height menu patch overwrites
        ; the high score table (unnecessarily). On type b it appears to have
        ; no impact. On high score entry it messes up the background (a bug).
        jsr     bulkCopyToPpu
        .addr   high_scores_nametable
        ; fall-through

@continue:
        jsr     waitForVBlankAndEnableNmi
        jsr     updateAudioWaitForNmiAndEnablePpuRendering
        rts

; index passed as 'a'
my_bulkCopyToPpu:
        asl     a
        tax
        lda     palettes,x ; will read into nametables as well
        sta     tmp1
        lda     palettes+1,x
        sta     tmp2
        jsr     copyToPpu
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
