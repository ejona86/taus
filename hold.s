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
        ips_segment     "DISABLE_SELECT",$88A6

; Replaces "sta displayNextPiece"

        lda     displayNextPiece        ; nop

.segment "CONTROL_PIECE"
        ips_segment     "CONTROL_PIECE",$81B9

; Replaces in branchOnPlayStatePlayer1:
;       .addr   playState_playerControlsActiveTetrimino

        .addr   playState_playerControlsActiveTetrimino_mod

.segment "CONTROL_PIECE_P2"
        ips_segment     "CONTROL_PIECE_P2",$81E0

; Replaces in branchOnPlayStatePlayer2:
;       .addr   playState_player2ControlsActiveTetrimino

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
        ; Hard-drop uses bottom portion of unreferenced_data1.
        ; Twoplayer uses top portion of unreferenced_data1, with bottom portion
        ; set aside for TetrisControllerInputDisplay.
        ips_segment     "CODE",unreferenced_data1+$4C,$D0-$4C

init_hold:
        ldx     #$80
        stx     player1_savedPiece
        stx     player2_savedPiece
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
        ora     #$40
        ldx     savedPiece
        sta     savedPiece
        bmi     @noOldPiece

        stx     currentPiece
@ret:
        rts

@noOldPiece:
        ldx     nextPiece
        jmp     playState_spawnNextTetrimino+$3E ; $98CC

unlockSavedPiece:
        lda     savedPiece
        and     #<~$40
        sta     savedPiece
        jmp     updatePlayfield

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
        lda     #<@holdSprites
        sta     generalCounter
        lda     #>@holdSprites
        sta     generalCounter2
        jmp     loadSpriteIntoOamStaging+$10

@holdSprites:
        set_tbl CHR01+CHR_RIGHT
        .byte   $04,"H",$03,$F8
        .byte   $04,"O",$03,$00
        .byte   $04,"L",$03,$08
        .byte   $04,"D",$03,$10
        .byte   $FF
