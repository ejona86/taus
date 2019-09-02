;
; Two-player Tetris Mod
;


; TODO:
; Enable two players by second player pressing start on level-select screen. Start or (b) may turn it back to 1 player.
; Fix on-screen display: score, level, next piece, lines
; Fix palette. Palette is broken for both players now. Will need to use a separate palette for second player.
; Handle end-game. If one player dies, if the player behind in score is still playing, they can keep playing. Unclear if score should be the only way. People may care about lines, or some other such. Need to think about it more. If let both players go to end, then may want to let 2nd player enter high score
; Separate RNG for both players. Keep current RNG updating, but don't draw pieces from it. Save another RNG to let the behind player catch up.
; Fix nextPiece usage for 2nd player. nextPiece_2player
; Let player2 hold down (a) when player1 presses start to start on level+10
; Allow second player to disable next piece display (minor)

; Integrations:
; Have handicap support 2 players
; Any way to fit stats on screen? Seems like there's no room.
; No room for A/B-Type, high score

.include "build/tetris.inc"
.include "ips.inc"

.segment "BSS"


.segment "GAMEBSS"


.segment "CODEHDR"
        ips_hunkhdr     "CODE"

.segment "CODE"

initGameState_mod:
.import __GAMEBSS_SIZE__, __GAMEBSS_RUN__
        jsr     memset_page
        lda     #$00
        ldx     #<__GAMEBSS_SIZE__
@clearByte:
        sta     __GAMEBSS_RUN__-1,x
        dex
        bne     @clearByte

        rts

initGameBackground_mod:
        lda     numberOfPlayers
        cmp     #$01
        bne     @twoPlayers
        jsr     bulkCopyToPpu
        .addr   game_nametable
        rts
@twoPlayers:
        jsr     copyNametableToPpu
        .addr   twoplayer_game_nametable
        rts

copyNametableToPpu:
        jsr     copyAddrAtReturnAddressToTmp_incrReturnAddrBy2
        ldx     PPUSTATUS
        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        jsr     copyPageToPpu
        inc     tmp2
        jsr     copyPageToPpu
        inc     tmp2
        jsr     copyPageToPpu
        inc     tmp2
        jsr     copyPageToPpu
        rts

copyPageToPpu:
        ldy     #$00
@copyByte:
        lda     (tmp1),y
        sta     PPUDATA
        iny
        bne     @copyByte
        rts

twoplayer_game_nametable:
        .incbin "twoplayer_game.nam"

.segment "JMP_INIT_GAME_STATEHDR"
        ips_hunkhdr     "JMP_INIT_GAME_STATE"

.segment "JMP_INIT_GAME_STATE"

; at beginning of initGameState, replaces "jsr memset_page"
        jsr initGameState_mod

.segment "SET_NUMBER_OF_PLAYERSHDR"
        ips_hunkhdr     "SET_NUMBER_OF_PLAYERS"

.segment "SET_NUMBER_OF_PLAYERS"

; just before @mainLoop, replaces "lda #$01"
        lda     #$02

.segment "JMP_INIT_GAME_BACKGROUNDHDR"
        ips_hunkhdr     "JMP_INIT_GAME_BACKGROUND"

.segment "JMP_INIT_GAME_BACKGROUND"

; in gameModeState_initGameBackground, replaces "jsr bulkCopyToPpu; .addr game_nametable"
        jsr     initGameBackground_mod
        nop
        nop


; TODO: in copyPlayfieldRowToVRAM
; before @playerTwo, set sbc to #$04
; at @playerTwo. Set adc to #$0E
; unreferenced_orientationToSpriteTable is probably the player2 table

; in stageSpriteForCurrentPiece
; change #$40 to #$50
; chang 6F to 8F

; in showHighScores. change "lda numberOfPlayers" to "lda #$01"
