;
; Two-player Tetris Mod
;


; TODO:
; Enable two players by second player pressing start on level-select screen. Start or (b) may turn it back to 1 player.
; Fix on-screen display: score, level, next piece
; Fix palette. Palette is broken for both players now. Will need to use a separate palette for second player.
; Disable/toggle garbage
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

.bss


.segment "GAMEBSS"


.code

initGameState_mod:
        .export initGameState_mod
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
        .export initGameBackground_mod
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

renderPlay_mod:
        .export renderPlay_mod
        lda     numberOfPlayers
        cmp     #$02
        beq     @twoPlayers
        rts

@twoPlayers:
        lda     outOfDateRenderFlags
        and     #$02
        beq     @renderScore
;        lda     #$20
;        sta     PPUADDR
;        lda     #$EF
;        sta     PPUADDR
;        ldx     player1_levelNumber
;        lda     levelDisplayTable,x
;        jsr     twoDigsToPPU
;        ;jsr     updatePaletteForLevel
;        lda     #$22
;        sta     PPUADDR
;        lda     #$50
;        sta     PPUADDR
;        ldx     player2_levelNumber
;        ldx     #$02
;        lda     levelDisplayTable,x
;        jsr     twoDigsToPPU
;        ;jsr     updatePaletteForLevel
        lda     outOfDateRenderFlags
        and     #$FD
        sta     outOfDateRenderFlags

@renderScore:
        lda     outOfDateRenderFlags
        and     #$04
        beq     @ret
;        lda     #$20
;        sta     PPUADDR
;        lda     #$66
;        sta     PPUADDR
;        lda     player1_score+2
;        jsr     twoDigsToPPU
;        lda     player1_score+1
;        jsr     twoDigsToPPU
;        lda     player1_score
;        jsr     twoDigsToPPU
        lda     outOfDateRenderFlags
        and     #$FB
        sta     outOfDateRenderFlags

@ret:
        lda     #$00
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

; TODO:
; unreferenced_orientationToSpriteTable is probably the player2 table
