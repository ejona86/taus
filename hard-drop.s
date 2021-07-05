;
; Hard drop
; Originally by Stephen Sherratt (stevebob)
; Reimplemented from https://github.com/stevebob/mos6502/tree/master/tetris-hard-drop-patcher
;

.include "build/tetris.inc"
.include "ips.inc"

HINT_PATTERN_INDEX = $FA
EMPTY_TILE = $EF
BOARD_HEIGHT = 20
CONTROLLER_BIT_UP = $08

.segment "IPSCHR"
        ips_tile_segment "IPSCHR",CHR01+CHR_RIGHT,HINT_PATTERN_INDEX

        ; hint pattern
        .incbin "hard-drop.chr"

.segment "stageSpriteForCurrentPiecePlayer1"
        ips_segment     "stageSpriteForCurrentPiecePlayer1",gameModeState_updatePlayer1+6

; replaces "jsr stageSpriteForCurrentPiece"
        jsr oam_dma_page_update

.segment "stageSpriteForCurrentPiecePlayer2"
        ips_segment     "stageSpriteForCurrentPiecePlayer2",gameModeState_updatePlayer2+12

; replaces "jsr stageSpriteForCurrentPiece"
        jsr oam_dma_page_update

.segment "playState_playerControlsActiveTetrimino"
        ips_segment     "playState_playerControlsActiveTetrimino",playState_playerControlsActiveTetrimino

; replaces "jsr shift_tetrimino"
        jsr     controls

.segment "playState_player2ControlsActiveTetrimino"
        ips_segment     "playState_player2ControlsActiveTetrimino",playState_player2ControlsActiveTetrimino

; replaces "jsr shift_tetrimino"
        jsr     controls

.segment "CODE"
        ips_segment     "CODE",unreferenced_data1+$17,$0637-$17

compute_hard_drop_distance:
        lda     currentPiece
        clc
        rol     a
        rol     a
        sta     $20
        rol     a
        adc     $20
        tax
        .repeat 4,I
        lda     orientationTable,x
        clc
        adc     tetriminoY
        sta     $21+(I*2)
        inx
        inx
        lda     orientationTable,x
        clc
        adc     tetriminoX
        sta     $20+(I*2)
        inx
        .endrepeat
        ldx     #$00
@start_hint_depth_loop:
        .repeat 4,I
        inc     $21+(I*2)
        lda     $21+(I*2)
        cmp     #BOARD_HEIGHT
        bpl     @end_hint_depth_loop
        asl     a
        sta     $28
        asl     a
        asl     a
        clc
        adc     $28
        adc     $20+(I*2)
        tay
        lda     (playfieldAddr),y
        cmp     #EMPTY_TILE
        bne     @end_hint_depth_loop
        .endrepeat
        inx
        jmp     @start_hint_depth_loop

@end_hint_depth_loop:
        txa
        rts

oam_dma_page_update:
        jsr     stageSpriteForCurrentPiece
.ifndef HIDE_GHOST_PIECE
        jsr     compute_hard_drop_distance
        beq     @after_render_hint
        sta     $28
        jsr     render_hint
.endif
@after_render_hint:
        rts

render_hint:
        lda     tetriminoY
        clc
        adc     $28
        sta     tetriminoY
        jsr     stageSpriteForCurrentPiece
        lda     tetriminoY
        sec
        sbc     $28
        sta     tetriminoY

        lda     #HINT_PATTERN_INDEX
        ldx     oamStagingLength
        sta     oamStaging-3   ,x
        sta     oamStaging-3- 4,x
        sta     oamStaging-3- 8,x
        sta     oamStaging-3-12,x
        rts

controls:
        jsr     shift_tetrimino
        lda     heldButtons
        and     #CONTROLLER_BIT_UP
        beq     @controller_end
        jsr     compute_hard_drop_distance
        sta     holdDownPoints
        clc
        adc     tetriminoY
        sta     tetriminoY
        lda     #$00
        sta     autorepeatY
        lda     dropSpeed
        sta     fallTimer
@controller_end:
        rts

.res $80
