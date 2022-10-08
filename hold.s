;
; Mod that allows pressing select to save a piece
;

.include "ips.inc"
.include "build/tetris.inc"
.include "tetris-tbl.inc"

; $80 for no hold. $40 bit set for locked
savedPiece := $005B
player1_savedPiece := $007B
player2_savedPiece := $009B

.segment "NAMETABLE"
        ips_segment     "NAMETABLE",game_nametable,$460

        .incbin "build/hold_game.nam.stripe"

.segment "GAME_INIT"
        ips_segment     "GAME_INIT",$8707

; Replaces (a random spot in gameModeState_initGameState):
;       sta     player1_score
;       sta     player1_score+1
        jsr     init_hold
        nop

.segment "DISABLE_SELECT"
        ips_segment     "DISABLE_SELECT",$889E

; Replaces "and #$20"

        and #$00

.segment "CONTROL_PIECE"
        ips_segment     "CONTROL_PIECE",$81B9

; Replaces in branchOnPlayStatePlayer1:
;       .addr   playState_playerControlsActiveTetrimino

        .addr   playState_playerControlsActiveTetrimino_mod

.segment "UNLOCK_SAVED_PIECE"
        ips_segment     "UNLOCK_SAVED_PIECE",$9A08

; Replaces "jsr updatePlayfield" in playState_lockTetrimino
        jsr     unlockSavedPiece

.segment "STAGE_SAVED_PIECE"
        ips_segment     "STAGE_SAVED_PIECE",$8BE1

; Replaces "jmp loadSpriteIntoOamStaging"
        jmp     stageSpriteForSavedPiece

.segment "CODE"
        ips_segment     "CODE",unreferenced_data1,$0637

init_hold:
        lda     #$80
        sta     player1_savedPiece 
        sta     player2_savedPiece 
        lda     #$00
        sta     player1_score
        sta     player1_score+1
        rts

playState_playerControlsActiveTetrimino_mod:
        jsr     playState_playerControlsActiveTetrimino
        lda     newlyPressedButtons
        and     #$20
        beq     @ret

        bit     savedPiece
        bvs     @ret

        lda     #$00
        sta     autorepeatY
        sta     tetriminoY
        sta     fallTimer
        sta     twoPlayerPieceDelayCounter
        lda     #$05
        sta     tetriminoX

        ldx     currentPiece
        lda     spawnOrientationFromOrientation,x
        ldx     savedPiece
        bmi     @noOldPiece

        ora     #$40
        sta     savedPiece
        stx     currentPiece
@ret:
        rts

@noOldPiece:
        sta     savedPiece
        ldx     nextPiece
        lda     spawnOrientationFromOrientation,x
        sta     currentPiece
        jsr     incrementPieceStat
        jsr     chooseNextTetrimino
        sta     nextPiece
        rts

unlockSavedPiece:
        lda     savedPiece
        and     #<~$40
        sta     savedPiece
        jsr     updatePlayfield
        rts

stageSpriteForSavedPiece:
        jsr     loadSpriteIntoOamStaging ; from stageSpriteForNextPiece
        lda     #$28
        sta     spriteXOffset
        lda     #$30
        sta     spriteYOffset
        lda     savedPiece
        bmi     @showHold
        and     #<~$40
        tax
        lda     orientationToSpriteTable,x
        sta     spriteIndexInOamContentLookup
        jmp     loadSpriteIntoOamStaging

@showHold:
        ldx     oamStagingLength
        ldy     #$00
@byte:  lda     @holdSprites,y
        sta     oamStaging,x
        iny
        inx
        cpy     #4*4
        bne     @byte
        stx     oamStagingLength
        rts

@holdSprites:
        set_tbl CHR01+CHR_RIGHT
        .byte   $34,"H",$03,$20
        .byte   $34,"O",$03,$28
        .byte   $34,"L",$03,$30
        .byte   $34,"D",$03,$38
