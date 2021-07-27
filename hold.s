;
; Mod that allows pressing select to save a piece
;

.include "ips.inc"
.include "build/tetris.inc"

; $FF for no hold
savedPiece := $005B
savedPieceLocked := $005C
player1_savedPiece := $007B
player1_savedPieceLocked := $007C
player2_savedPiece := $009B
player2_savedPieceLocked := $009C

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
        lda     #$FF
        sta     player1_savedPiece 
        sta     player2_savedPiece 
        lda     #$00
        sta     player1_savedPieceLocked 
        sta     player2_savedPieceLocked 
        sta     player1_score
        sta     player1_score+1
        rts

playState_playerControlsActiveTetrimino_mod:
        jsr     playState_playerControlsActiveTetrimino
        lda     newlyPressedButtons
        and     #$20
        beq     @ret

        lda     savedPieceLocked
        bne     @ret

        inc     savedPieceLocked
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
        sta     savedPiece
        bmi     @noOldPiece

        stx     currentPiece
@ret:
        rts

@noOldPiece:
        ldx     nextPiece
        lda     spawnOrientationFromOrientation,x
        sta     currentPiece
        jsr     incrementPieceStat
        jsr     chooseNextTetrimino
        sta     nextPiece
        rts

unlockSavedPiece:
        lda     #$00
        sta     savedPieceLocked
        jsr     updatePlayfield
        rts

stageSpriteForSavedPiece:
        jsr     loadSpriteIntoOamStaging ; from stageSpriteForNextPiece
        lda     #$28
        sta     spriteXOffset
        lda     #$37
        sta     spriteYOffset
        ldx     savedPiece
        bmi     @ret
        lda     orientationToSpriteTable,x
        sta     spriteIndexInOamContentLookup
        jmp     loadSpriteIntoOamStaging
@ret:
        rts

