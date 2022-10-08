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

.ifndef HIDE_GHOST_PIECE
.segment "IPSCHR"
        ips_tile_segment "IPSCHR",CHR01+CHR_RIGHT,HINT_PATTERN_INDEX

        ; hint pattern
        .incbin "hard-drop.chr"
.endif

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

drop_piece:
        ldx     tetriminoY
        stx     originalY
@tryLowerPosition:
        inc     tetriminoY
        jsr     isPositionValid
        beq     @tryLowerPosition

        dec     tetriminoY
        lda     tetriminoY
        sec
        sbc     originalY
        rts

oam_dma_page_update:
        jsr     stageSpriteForCurrentPiece
.ifndef HIDE_GHOST_PIECE
        jsr     drop_piece
        beq     @after_render_hint

        lda     originalY
        pha
        jsr     stageSpriteForCurrentPiece
        pla
        sta     tetriminoY

        lda     #HINT_PATTERN_INDEX
        ldx     oamStagingLength
        sta     oamStaging-3   ,x
        sta     oamStaging-3- 4,x
        sta     oamStaging-3- 8,x
        sta     oamStaging-3-12,x
.endif
@after_render_hint:
        rts

controls:
        jsr     shift_tetrimino
        lda     heldButtons
        and     #CONTROLLER_BIT_UP
        beq     @controller_end
        jsr     drop_piece
        sta     holdDownPoints
        lda     #$00
        sta     autorepeatY
        lda     dropSpeed
        sta     fallTimer
@controller_end:
        rts
