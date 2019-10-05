;
; Two-player Tetris Mod
;

; Normally player 1 uses palette 2 and 6 (zero indexed). The mod uses palettes
; 1/2 and 5/6, but has player 1 uses palette 1 so that we can just use the
; "current player" as the palette value.

; TODO:
; Rendering is exceeding the sprites-per-scanline limit
; Save another RNG to let the behind player catch up.
; Handle end-game. If one player dies, if the player behind in score is still playing, they can keep playing. Unclear if score should be the only way. People may care about lines, or some other such. Need to think about it more. If let both players go to end, then may want to let 2nd player enter high score
; Enable two players by second player pressing start on level-select screen. Start or (b) may turn it back to 1 player.
; Fix background tetrimino pattern
; Figure out what's up with twoPlayerPieceDelayCounter
; Disable/toggle garbage
; Let player2 hold down (a) when player1 presses start to start on level+10
; Allow second player to disable next piece display (minor)

; Integrations:
; Have handicap support 2 players
; Any way to fit stats on screen? Seems like there's no room.
; No room for A/B-Type, high score

.include "build/tetris.inc"

.bss


.segment "GAMEBSS"

.res 1 ; must be at least size 1 to prevent init loop from breaking

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

        .importzp personal_rng
        .importzp player1_rng
        .importzp player2_rng
; FIXME. reuses the seed at beginning of game
        lda     rng_seed
        sta     personal_rng
        sta     player1_rng
        sta     player2_rng
        lda     rng_seed+1
        sta     personal_rng+1
        sta     player1_rng+1
        sta     player2_rng+1

        ldx     #player1_rng
        ldy     #$02
        jsr     generateNextPseudorandomNumber
        ldx     #player1_rng
        ldy     #$02
        jsr     generateNextPseudorandomNumber
        ldx     #player2_rng
        ldy     #$02
        jsr     generateNextPseudorandomNumber
        ldx     #player2_rng
        ldy     #$02
        jsr     generateNextPseudorandomNumber

        rts

initGameBackground_mod:
        .export initGameBackground_mod
        lda     numberOfPlayers
        cmp     #$01
        bne     @twoPlayers
        jsr     bulkCopyToPpu
        .addr   game_nametable
        .import after_initGameBackground_mod_player1
        jmp     after_initGameBackground_mod_player1

@twoPlayers:
        jsr     copyNametableToPpu
        .addr   twoplayer_game_nametable
        .import after_initGameBackground_mod_player2
        jmp     after_initGameBackground_mod_player2

twoplayer_game_nametable:
        .incbin "twoplayer_game.nam"

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
        ; Only update level on odd frames
        lda     frameCounter
        and     #$01
        bne     @renderScore
        lda     #$20
        sta     PPUADDR
        lda     #$EF
        sta     PPUADDR
        ldx     player1_levelNumber
        lda     levelDisplayTable,x
        jsr     twoDigsToPPU
        jsr     updatePaletteForLevel
        lda     #$22
        sta     PPUADDR
        lda     #$50
        sta     PPUADDR
        ldx     player2_levelNumber
        lda     levelDisplayTable,x
        jsr     twoDigsToPPU
        jsr     updatePaletteForLevel_player2
        lda     outOfDateRenderFlags
        and     #$FD
        sta     outOfDateRenderFlags

@renderScore:
        lda     outOfDateRenderFlags
        and     #$04
        beq     @ret
        ; Only update score on even frames
        lda     frameCounter
        and     #$01
        beq     @ret

        lda     #$20
        sta     PPUADDR
        lda     #$66
        sta     PPUADDR
        lda     player1_score+2
        jsr     twoDigsToPPU
        lda     player1_score+1
        jsr     twoDigsToPPU
        lda     player1_score
        jsr     twoDigsToPPU

        lda     #$20
        sta     PPUADDR
        lda     #$78
        sta     PPUADDR
        lda     player2_score+2
        jsr     twoDigsToPPU
        lda     player2_score+1
        jsr     twoDigsToPPU
        lda     player2_score
        jsr     twoDigsToPPU

        lda     outOfDateRenderFlags
        and     #$FB
        sta     outOfDateRenderFlags

@ret:
        lda     #$00
        rts

updatePaletteForLevel_player2:
        lda     player2_levelNumber
@mod10: cmp     #$0A
        bmi     @copyPalettes
        sec
        sbc     #$0A
        jmp     @mod10

@copyPalettes:
        asl     a
        asl     a
        tax
        lda     #$00
        sta     generalCounter
@copyPalette:
        lda     #$3F
        sta     PPUADDR
        lda     #$08
        clc
        adc     generalCounter
        sta     PPUADDR
        lda     colorTable,x
        sta     PPUDATA
        lda     colorTable+1,x
        sta     PPUDATA
        lda     colorTable+1+1,x
        sta     PPUDATA
        lda     colorTable+1+1+1,x
        sta     PPUDATA
        lda     generalCounter
        clc
        adc     #$10
        sta     generalCounter
        cmp     #$20
        bne     @copyPalette
        rts

; A faster implementation of copying to the VRAM, by 75 cycles.
; An unmodified implementation of render_mode_play_and_demo, but with 2 players
; enabled, would not fit within a vsync, because this method is run 8 times.
; After some additions, it was taking 2549 cycles, which is well over the 2270
; cycles available per vsync and that is even before it starts the OAMDMA. This
; implementation reduces number of cycles by 75, saving 600 overall per frame.
; For the moment, that lends a much more comfortable 1949 cycles.
copyPlayfieldRowToVRAM_fast:
        .export copyPlayfieldRowToVRAM_fast
        lda     #$04
        sta     generalCounter
        ldx     vramRow
        cpx     #$15
        bmi     @skipRts
        rts
@skipRts:
        lda     multBy10Table,x
        tay
        txa
        asl     a
        tax
        inx
        lda     vramPlayfieldRows,x
        sta     PPUADDR
        dex
        lda     numberOfPlayers
        cmp     #$01
        beq     @onePlayer
        lda     playfieldAddr+1
        cmp     #$05
        beq     @playerTwo
        lda     vramPlayfieldRows,x
        sec
        sbc     #$04
        sta     PPUADDR
        jmp     @copyRowForPlayer1

@playerTwo:
        lda     vramPlayfieldRows,x
        clc
        adc     #$0E
        sta     PPUADDR
        .repeat 10,I
        lda     playfieldForSecondPlayer+I,y
        sta     PPUDATA
        .endrepeat
        jmp     @doneWithRow

@onePlayer:
        lda     vramPlayfieldRows,x
        clc
        adc     #$06
        sta     PPUADDR
@copyRowForPlayer1:
        .repeat 10,I
        lda     playfield+I,y
        sta     PPUDATA
        .endrepeat
@doneWithRow:
        inc     vramRow
        lda     vramRow
        cmp     #$14
        bmi     @ret
        lda     #$20
        sta     vramRow
@ret:   rts


.segment "CODE2"

stageSpriteForNextPiece_player1_mod:
        .export stageSpriteForNextPiece_player1_mod
        lda     displayNextPiece
        bne     @ret
        lda     numberOfPlayers
        bne     @twoPlayers
        lda     #$C8
        sta     spriteXOffset
        lda     #$77
        sta     spriteYOffset
        jmp     @stage
@twoPlayers:
        lda     #$78
        sta     spriteXOffset
        lda     #$53
        sta     spriteYOffset
@stage:
        .importzp player1_nextPiece
        ldx     player1_nextPiece
        lda     orientationToSpriteTable,x
        sta     spriteIndexInOamContentLookup
        jmp     loadSpriteIntoOamStaging

@ret:   rts

savePlayer2State_mod:
        .export savePlayer2State_mod
        jsr     savePlayer2State
        jsr     stageSpriteForNextPiece_player2
        rts

stageSpriteForNextPiece_player2:
        lda     displayNextPiece
        bne     @ret
        lda     #$80
        sta     spriteXOffset
        lda     #$AB
        sta     spriteYOffset
        .importzp player2_nextPiece
        ldx     player2_nextPiece
        lda     orientationToSpriteTable,x
        sta     spriteIndexInOamContentLookup
        jmp     loadSpriteIntoOamStaging_player2

@ret:   rts


loadSpriteIntoOamStaging_player2:
        lda     oamStagingLength
        sta     generalCounter3
        jsr     loadSpriteIntoOamStaging
        ldx     generalCounter3
@adjustSprite:
        inx
        inx
        inc     oamStaging,x
        inx
        inx
        cpx     oamStagingLength
        bne     @adjustSprite
        rts


pickRandomTetrimino_mod:
        .export pickRandomTetrimino_mod
        ldx     #rng_seed
        ldy     #$02
        jsr     generateNextPseudorandomNumber
        ldx     #personal_rng
        ldy     #$02
        jsr     generateNextPseudorandomNumber
        rts
