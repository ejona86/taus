;
; Two-player Tetris Mod
;

; Player 1 uses palette 2 and 6 (zero indexed) and Player 2 uses palette 1
; and 5. This keeps player 1 palettes the same as original Tetris.

; TODO:
; Save another RNG to let the behind player catch up.
; Allow toggling on garbage?

; Integrations:
; Any way to fit stats on screen? Seems like there's no room.
; No room for A/B-Type, high score

.include "build/tetris.inc"
.include "tetris-tbl.inc"
__TWOPLAYERSIMPORT = 1
.include "twoplayer.inc"

.ifdef TOURNAMENT_MODE
.include "tournament.romlayout.inc"
.endif

.segment "CHR"
        .incbin "build/tetris-CHR-00.chr"
        .incbin "build/twoplayer-CHR-01.chr"

.bss


.segment "GAMEBSS"

; 0 for both players demo
demo_playingPlayer:
        .res    1
demoIndex_player2:
        .res    1

.ifdef TOURNAMENT_MODE
tetrisCount_P1:
        .res    1
tetrisCount_P2:
        .res    1
binaryLines_P1:
        .res    1
binaryLines_P2:
        .res    1
binaryLines_P1_HI:
        .res    1
binaryLines_P2_HI:
        .res    1
.endif

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
        .importzp spawnID_
        .importzp spawnCount_
        .importzp player1_rng
        .importzp player1_spawnID_
        .importzp player1_spawnCount_
        .importzp player2_rng
        .importzp player2_spawnID_
        .importzp player2_spawnCount_
; FIXME. reuses the seed at beginning of game
        lda     rng_seed
        sta     personal_rng
        sta     player1_rng
        sta     player2_rng
        lda     rng_seed+1
        sta     personal_rng+1
        sta     player1_rng+1
        sta     player2_rng+1
        lda     spawnID_
        sta     player1_spawnID_
        sta     player2_spawnID_
        lda     spawnCount_
        sta     player1_spawnCount_
        sta     player2_spawnCount_

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
        jsr     copyRleNametableToPpu
        .addr   twoplayer_game_nametable
        .import after_initGameBackground_mod_player2
        jmp     after_initGameBackground_mod_player2

twoplayer_game_nametable:
.ifdef  TOURNAMENT_MODE
        .incbin "build/tournament.nam.rle"
.elseif .defined(NEXT_ON_TOP)
        .incbin "build/twoplayer_game_top.nam.rle"
.else
        .incbin "build/twoplayer_game.nam.rle"
.endif

copyRleNametableToPpu:
        .export copyRleNametableToPpu
        jsr     copyAddrAtReturnAddressToTmp_incrReturnAddrBy2
        ldx     PPUSTATUS
        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        .import rleDecodeToPpu
        jmp     rleDecodeToPpu

renderPlay_mod:
        .export renderPlay_mod
        lda     numberOfPlayers
        cmp     #$02
        beq     @twoPlayers
        .import after_renderPlay_mod
        jmp     after_renderPlay_mod

@twoPlayers:
        ; Update level/palette on a different frame than score (and implicitly
        ; lines) is updated. This reduces the number of updates on the same
        ; frame to help squeeze updates within vsync. The wrong palette is not
        ; visible the first frame of the game in two-player because the game
        ; logic runs after rendering, so the first frame has no sprites. In
        ; one-player the statistics will have the wrong palette for an extra
        ; frame.
        lda     outOfDateRenderFlags
        eor     #$02
        and     #$06
        bne     @renderScore

        lda     #>INGAME_LAYOUT_P1_LEVEL
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P1_LEVEL
        sta     PPUADDR

        ldx     player1_levelNumber
        lda     levelDisplayTable,x
        jsr     twoDigsToPPU
        jsr     updatePaletteForLevel

        lda     #>INGAME_LAYOUT_P2_LEVEL
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P2_LEVEL
        sta     PPUADDR

        ldx     player2_levelNumber
        lda     levelDisplayTable,x
        jsr     twoDigsToPPU
        ; updatePaletteForLevel_player2
        lda     player2_levelNumber
        ldy     #$04
        .import updatePaletteForLevel_postConf
        jsr     updatePaletteForLevel_postConf
        lda     outOfDateRenderFlags
        and     #$FD
        sta     outOfDateRenderFlags

.ifdef TOURNAMENT_MODE
        ;in tourmanent mode we try to reduce updates
        ;so we update only one set of numbers at once
        ;if we updated level, we just leave
        lda     #$00
        jmp     after_renderPlay_mod

.endif

@renderScore:
        lda     outOfDateRenderFlags
        and     #$04
        beq     @ret

        lda     #>INGAME_LAYOUT_P1_SCORE
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P1_SCORE
        sta     PPUADDR
        lda     player1_score+2
        jsr     twoDigsToPPU
        lda     player1_score+1
        jsr     twoDigsToPPU
        lda     player1_score
        jsr     twoDigsToPPU

        lda     #>INGAME_LAYOUT_P2_SCORE
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P2_SCORE
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
.ifdef TOURNAMENT_MODE
        ;in tourmanent mode we try to reduce updates
        ;so we update only one set of numbers at once
        ;if we updated score, we just leave
        lda     #$00
        jmp     after_renderPlay_mod
@ret:
        ;we did no update so far, lets see if the
        ;tournament statistics need update
        jsr     updateTournamentRendering
.else
@ret:
 .endif
        lda     #$00
        jmp     after_renderPlay_mod

.import vramPlayfieldRowsHi
.import vramPlayfieldRowsLo
.define FASTROWTOVRAM 2
.if FASTROWTOVRAM = 1
; A faster implementation of copying to the VRAM, by 92 cycles (from 246
; cycles down to 154).
;
; An unmodified implementation of render_mode_play_and_demo, but with 2 players
; enabled, does not fit within a vsync because 8 rows are copied which totals
; 1968 cycles by itself. The optimization here brings it down to 1232 cycles
; which may still be tight but isn't too much more than the 984 cycles
; normally used for 1 player.
copyPlayfieldRowToVRAM_fast:
        .export copyPlayfieldRowToVRAM_fast
        ldx     vramRow
        cpx     #$15
        bmi     @skipRts
        rts
@skipRts:
        ldy     multBy10Table,x
        lda     vramPlayfieldRowsHi,x
        sta     PPUADDR
        lda     numberOfPlayers
        cmp     #$01
        beq     @onePlayer
        lda     playfieldAddr+1
        cmp     #$05
        beq     @playerTwo
        lda     vramPlayfieldRowsLo,x
        sec
        sbc     #$04
        sta     PPUADDR
        jmp     @copyRowForPlayer1

@playerTwo:
        lda     vramPlayfieldRowsLo,x
        clc
        adc     #$0E
        sta     PPUADDR
        .repeat 10,I
        lda     playfieldForSecondPlayer+I,y
        sta     PPUDATA
        .endrepeat
        jmp     @doneWithRow

@onePlayer:
        lda     vramPlayfieldRowsLo,x
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

.elseif FASTROWTOVRAM = 2
; A batched implementation of copying playfield to the VRAM, saving 76 cycles
; compared to copying each row individually (from 635 cycles down to 559,
; including boilerplate in caller).
;
; reg x: (input/output) vramRow
; reg a: (input) 0=player 1, 1=player 2
;
copyPlayfieldRowToVRAM4:
        ; generalCounter is off-limits as it is used by multiple callers of
        ; updateAudioWaitForNmiAndResetOamStaging, which waits for render.
        ; Specifically, it breaks Type B via initPlayfieldIfTypeB. While
        ; generalCounter is used by parts of render (e.g., @renderLevel,
        ; twoDigsToPPU, updateLineClearingAnimation), those render paths aren't
        ; taken in cases like Type B init. But this copying code path is taken.
        .export copyPlayfieldRowToVRAM4
        cpx     #$20
        bmi     @skipRts
        rts
@skipRts:
        sta     tmp3
        tay
        beq     @playerOne
;playerTwo:
        lda     #$0E
        sta     tmp2
        bne     @continueSetup

@playerOne:
        ldy     numberOfPlayers
        lda     @offsetTable-1,y
        sta     tmp2

@continueSetup:
        lda     #$04
        sta     tmp1
; reg x: vramRow
; reg y: playfield offset for row
; tmp1: loop counter
; tmp2: VRAM LO offset
; tmp3: 0=player 1, 1=player 2
@loop:
        lda     vramPlayfieldRowsHi,x
        sta     PPUADDR
        lda     vramPlayfieldRowsLo,x
        clc
        adc     tmp2
        sta     PPUADDR

        ldy     multBy10Table,x
        lda     tmp3
        bne     @playerTwoCopy
        .repeat 10,I
        lda     playfield+I,y
        sta     PPUDATA
        .endrepeat
        jmp     @nextIter
@playerTwoCopy:
        .repeat 10,I
        lda     playfieldForSecondPlayer+I,y
        sta     PPUDATA
        .endrepeat

@nextIter:
        inx
        cpx     #$14
        bpl     @doneWithAllRows
@vramInRange:
        dec     tmp1
        beq     @ret
        jmp     @loop

@doneWithAllRows:
        ldx     #$20
@ret:
        rts

@offsetTable:
        .byte   $06,(-$04)&$FF
.endif

copyOamStagingToOam_mod:
        .export copyOamStagingToOam_mod
        lda     #$00
        sta     OAMADDR
        lda     #$02
        sta     OAMDMA
        .import after_copyOamStagingToOam_mod
        jmp     after_copyOamStagingToOam_mod

gameModeState_updateCountersAndNonPlayerState_mod:
        .export gameModeState_updateCountersAndNonPlayerState_mod
        lda     newlyPressedButtons_player2
        and     #$20
        beq     @continue
        lda     displayNextPiece
        eor     #$02
        sta     displayNextPiece
@continue:
        lda     newlyPressedButtons_player1
        and     #$20
        rts

stageSpriteForNextPiece_player1_mod:
        .export stageSpriteForNextPiece_player1_mod
        lda     displayNextPiece
        and     #$01
        bne     @ret
        lda     numberOfPlayers
        cmp     #$01
        bne     @twoPlayers
        lda     #$C8
        sta     spriteXOffset
        lda     #$77
        sta     spriteYOffset
        jmp     @stage
@twoPlayers:
        lda     #INGAME_LAYOUT_P1_PREVIEW_X
        sta     spriteXOffset
        lda     #INGAME_LAYOUT_P1_PREVIEW_Y
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
        ; fix recent result of stageSpriteForCurrentPiece
        jsr     adjustLast4SpritesInOamPlayer1PaletteToPlayer2
        jsr     savePlayer2State
        jsr     stageSpriteForNextPiece_player2

.ifndef NEXT_ON_TOP
        ; Alternate draw order to flicker on conflict
        lda     frameCounter
        and     #$0F
        jsr     moveSpriteToEndOfOamStaging
        lda     frameCounter
        and     #$0F
        eor     #$08
        jsr     moveSpriteToEndOfOamStaging
.endif
.ifdef TOURNAMENT_MODE
        jmp     tournamentLeadCheck
.else
        rts
.endif

stageSpriteForNextPiece_player2:
        lda     displayNextPiece
        and     #$02
        bne     @ret
        lda     #INGAME_LAYOUT_P2_PREVIEW_X
        sta     spriteXOffset
        lda     #INGAME_LAYOUT_P2_PREVIEW_Y
        sta     spriteYOffset
        .importzp player2_nextPiece
        ldx     player2_nextPiece
        lda     orientationToSpriteTable,x
        sta     spriteIndexInOamContentLookup
        jsr     loadSpriteIntoOamStaging
        jsr     adjustLast4SpritesInOamPlayer1PaletteToPlayer2

@ret:   rts

adjustLast4SpritesInOamPlayer1PaletteToPlayer2:
        lda     oamStagingLength
        sec
        sbc     #4*4
        tax
@adjustSprite:
        inx
        inx
        dec     oamStaging,x
        inx
        inx
        cpx     oamStagingLength
        bne     @adjustSprite
        rts


.ifndef NEXT_ON_TOP
; Move a sprite in oamStaging to end of oamStaging.
;
; reg a: sprite number in oamStaging to move
moveSpriteToEndOfOamStaging:
        asl     a
        asl     a
        tax
        ldy     oamStagingLength
        lda     #$04
        sta     generalCounter
@copySprite:
        lda     oamStaging,x
        sta     oamStaging,y
        lda     #$FF
        sta     oamStaging,x
        inx
        iny
        dec     generalCounter
        bne     @copySprite

        sty     oamStagingLength
        rts
.endif


pickRandomTetrimino_mod:
        .export pickRandomTetrimino_mod
        ldx     #personal_rng
        ldy     #$02
        jsr     generateNextPseudorandomNumber
        ldx     #personal_rng
        ldy     #$02
        jsr     generateNextPseudorandomNumber
        ldx     #personal_rng
        ldy     #$02
        jsr     generateNextPseudorandomNumber
        rts


isStartNewlyPressed:
        .export isStartNewlyPressed
        lda     newlyPressedButtons_player1
        ora     newlyPressedButtons_player2
        and     #$10
        cmp     #$10
        rts


.segment "CODE2"

legal_screen_nametable_rle:
        .export legal_screen_nametable_rle
        .incbin "build/legal_screen_nametable.nam.rle"

demo_pollController_mod_after := $9D66
demo_pollController_mod_skip := $9D6A
demo_pollController_mod:
        .export demo_pollController_mod
        jsr     pollController
        lda     newlyPressedButtons_player1
        ora     newlyPressedButtons_player2
        and     #$10
        bne     @ret

        lda     numberOfPlayers
        cmp     #$02
        bne     @done
        lda     demo_playingPlayer
        cmp     #$01
        beq     @player1Playing
        cmp     #$02
        beq     @player2Playing

        ; check for starting player
        lda     newlyPressedButtons_player1
        bne     @startPlayer1
        lda     newlyPressedButtons_player2
        beq     @bothPlayersDemo

@startPlayer2:
        lda     #$02
        sta     demo_playingPlayer
@player2Playing:
@done:
        lda     #$00
@ret:
        jmp     demo_pollController_mod_after

@startPlayer1:
        inc     demo_playingPlayer
@player1Playing:
        ; copy player1 input to player2
        lda     newlyPressedButtons_player1
        sta     newlyPressedButtons_player2
        lda     heldButtons_player1
        sta     heldButtons_player2
        jsr     demo_pollController_mod_skip
        ; now swap player1 and player2 input
        lda     newlyPressedButtons_player2
        sta     tmp1
        lda     newlyPressedButtons_player1
        sta     newlyPressedButtons_player2
        lda     tmp1
        sta     newlyPressedButtons_player1

        lda     heldButtons_player2
        sta     tmp1
        lda     heldButtons_player1
        sta     heldButtons_player2
        lda     tmp1
        sta     heldButtons_player1
        rts

@bothPlayersDemo:
        jsr     demo_pollController_mod_skip
        lda     newlyPressedButtons_player1
        sta     newlyPressedButtons_player2
        lda     heldButtons_player1
        sta     heldButtons_player2
        rts


chooseNextTetrimino_mod:
        .export chooseNextTetrimino_mod
        ; Assume that when demoIndex is 0/1, this is being called from
        ; gameModeState_initGameState and that it applies to both players
        lda     demoIndex
        cmp     #$02
        bmi     @bothPlayers
        lda     activePlayer
        cmp     #$01
        bne     @player2
        ldx     demoIndex
        inc     demoIndex
        rts
@bothPlayers:
        inc     demoIndex
@player2:
        ldx     demoIndex_player2
        inc     demoIndex_player2
        rts


gameMode_levelMenu_nametable_mod:
        .export gameMode_levelMenu_nametable_mod
        jsr     bulkCopyToPpu
        .addr   level_menu_nametable
        lda     numberOfPlayers
        cmp     #$01
        bne     @twoPlayers

        jsr     bulkCopyToPpu
        .addr   player2PressStartPatch
        jmp     @levelMenuInit

@twoPlayers:
        jsr     bulkCopyToPpu
        .addr   player1ActivePatch

@levelMenuInit:
        lda     player2_startLevel
@forceStartLevelToRange:
        sta     player2_startLevel
        sec
        sbc     #$0A
        bcs     @forceStartLevelToRange

        rts

gameMode_levelMenu_processPlayer1Navigation_processPlayer2:
        .export gameMode_levelMenu_processPlayer1Navigation_processPlayer2
        lda     newlyPressedButtons_player2
        and     #$90    ; Start or A. A is required for Famicom
        beq     @checkBPressed
        lda     numberOfPlayers
        cmp     #$01
        bne     @checkBPressed
        inc     numberOfPlayers
        lda     #$08
        sta     soundEffectSlot1Init
        jmp     gameMode_levelMenu
@checkBPressed:
        lda     newlyPressedButtons_player2
        cmp     #$40
        bne     @ret
        lda     numberOfPlayers
        cmp     #$02
        bne     @ret
        dec     numberOfPlayers
        lda     #$01
        sta     soundEffectSlot3Init
        jmp     gameMode_levelMenu
@ret:
        jsr     updateAudioWaitForNmiAndResetOamStaging
        jmp     gameMode_levelMenu_processPlayer1Navigation

player2PressStartPatch:
        set_tbl $0000
        .byte   $20,$A4,$18
        .byte   "     P2 PRESS START!    "
        .byte   $FF
player1ActivePatch:
        .byte   $20,$A4,$18
        .byte   "        PLAYER 1        "
        .byte   $FF
player2ActivePatch:
        .byte   $20,$A4,$18
        .byte   "        PLAYER 2        "
        .byte   $FF

gameMode_levelMenu_processPlayer2Navigation:
        .export gameMode_levelMenu_processPlayer2Navigation
        lda     numberOfPlayers
        cmp     #$01
        bne     @twoPlayers
        inc     gameMode
        rts

@twoPlayers:
        jsr     updateAudioWaitForNmiAndDisablePpuRendering
        jsr     disableNmi
        jsr     bulkCopyToPpu
        .addr   player2ActivePatch
        jsr     waitForVBlankAndEnableNmi
        jsr     updateAudioWaitForNmiAndEnablePpuRendering

@afterPatch:
        lda     #$00
        sta     activePlayer
        lda     player2_startLevel
        sta     startLevel
        lda     player2_startHeight
        sta     startHeight
        lda     originalY
        sta     selectingLevelOrHeight
        lda     newlyPressedButtons_player2
        sta     newlyPressedButtons
        jsr     gameMode_levelMenu_handleLevelHeightNavigation
        lda     startLevel
        sta     player2_startLevel
        lda     startHeight
        sta     player2_startHeight
        lda     selectingLevelOrHeight
        sta     originalY
        lda     newlyPressedButtons_player2
        ; allow player1 to press start for Famicom
        ora     newlyPressedButtons_player1
        and     #$10
        beq     @checkBPressed
        lda     heldButtons_player2
        and     #$80
        beq     @startAndANotPressed
        lda     player2_startLevel
        clc
        adc     #$0A
        sta     player2_startLevel
@startAndANotPressed:
        lda     #$00
        sta     gameModeState
        lda     #$02
        sta     soundEffectSlot1Init
        inc     gameMode
        rts

@checkBPressed:
        lda     newlyPressedButtons_player2
        cmp     #$40
        bne     @doneProcessing
        lda     #$02
        sta     soundEffectSlot1Init
        jsr     updateAudioWaitForNmiAndResetOamStaging
        jmp     gameMode_levelMenu

@doneProcessing:
        jsr     updateAudioWaitForNmiAndResetOamStaging
        jmp     @afterPatch


gameModeState_handleGameOver_mod:
        .export gameModeState_handleGameOver_mod
        lda     numberOfPlayers
        cmp     #$01
        bne     @twoPlayers
        ldx     #$00 ; player score offset for handleHighScoreIfNecessary
        stx     tmp3
        jmp     gameModeState_handleGameOver

@twoPlayers:
        lda     player1_playState
        ora     player2_playState
        beq     @gameOver
        ; put known data in a, to avoid it from matching "cmp gameModeState" in
        ; @mainLoop. In 1 player mode, numberOfPlayers will be in a.
        lda     #$00
        inc     gameModeState
        rts

@gameOver:
        ldx     #$00 ; player score offset for handleHighScoreIfNecessary
        stx     tmp3
        jsr     handleHighScoreIfNecessary
        ldx     #player2_score-player1_score
        stx     tmp3
        jsr     handleHighScoreIfNecessary

        jmp     gameModeState_handleGameOver

highScoreEntryScreen_render:
        .export highScoreEntryScreen_render
        lda     numberOfPlayers
        cmp     #$01
        beq     @ret
        lda     tmp3
        bne     @player2
        jsr     bulkCopyToPpu
        .addr   player1ActivePatch
        jmp     @ret
@player2:
        jsr     bulkCopyToPpu
        .addr   player2ActivePatch

@ret:
        jsr     waitForVBlankAndEnableNmi
        rts

highScoreEntryScreen_get_player:
        .export highScoreEntryScreen_get_player
        jsr     loadSpriteIntoOamStaging
        ldx     tmp3
        beq     @ret
        ; copy start presses from player1 to player2 for famicom
        lda     newlyPressedButtons_player1
        and     #$10    ; start
        ora     newlyPressedButtons_player2
        sta     newlyPressedButtons_player2
        ldx     #$01
@ret:
        rts

updateMusicSpeed_noBlockInRow_mod:
        .export updateMusicSpeed_noBlockInRow_mod
        tax
        and     activePlayer
        eor     allegro
        sta     allegro
        txa
        cmp     activePlayer
        rts

updateMusicSpeed_foundBlockInRow_mod:
        .export updateMusicSpeed_foundBlockInRow_mod
        tax
        ora     activePlayer
        sta     allegro
        txa
        cmp     #$00
        rts

playState_updateGameOverCurtain_curtainFinished_mod:
        .export playState_updateGameOverCurtain_curtainFinished_mod
        sta     playState

        lda     numberOfPlayers
        cmp     #$02
        bne     @ret

        ; playState has not yet been copied to player*_playState.
        ; If a player has already died, then this would make two.
        lda     player1_playState
        beq     @bothPlayersDead
        lda     player2_playState
        beq     @bothPlayersDead
        jmp     updateMusicSpeed_playerDied

@bothPlayersDead:
        ; Wait for a player to press start
        jsr     updateAudioWaitForNmiAndResetOamStaging
        lda     newlyPressedButtons_player1
        ora     newlyPressedButtons_player2
        and     #$10
        bne     @ret
        jmp     @bothPlayersDead
@ret:
        ; Prevent start button from counting as pause
        lda     #$00
        sta     newlyPressedButtons_player1
        sta     newlyPressedButtons_player2
        rts

updateMusicSpeed_playerDied:
        lda     allegro
        and     activePlayer
        eor     allegro
        sta     allegro
        bne     @fast

        ldx     musicType
        lda     musicSelectionTable,x
        jsr     setMusicTrack
        rts

@fast:
        lda     musicType
        clc
        adc     #$04
        tax
        lda     musicSelectionTable,x
        jsr     setMusicTrack
        rts

;--------------------------------------------------------------------
; Tournament Mode Mod - additional code
;--------------------------------------------------------------------
.ifdef  TOURNAMENT_MODE

;this is the update of stats for the tournament play mode
statsPerBlock_tournamentMode:
        .export statsPerBlock_tournamentMode
        tay
        lda     activePlayer
        clc
        adc     #DROUGHT_P1 - 1
        tax
        lda     tetriminoTypeFromOrientation,y
        cmp     #$06 ; i piece
        beq     @clearDrought
        lda     #1
        jsr     increaseBCDStatsToF9
        jmp     @rts
@clearDrought:
        lda     #$00
        sta     statsByType, x
@rts:
        ;request render update
        lda     tournamentRenderFlags-DROUGHT_P1, x
        ora     #tournamentRenderFlagsDrought
        sta     tournamentRenderFlags-DROUGHT_P1, x

        rts


statsPerLineClear_tournamentMode:
        .export statsPerLineClear_tournamentMode
        lda     completedLines
        cmp     #$00
        beq     @rts
        tay
        lda     activePlayer
        clc
        adc     #BURN_P1 - 1
        tax
        tya
        cmp     #$04
        beq     @clearBurn
        jsr     increaseBCDStatsToF9
        jmp     @updateLines
@clearBurn:
        lda     #$00
        sta     statsByType, x
        inc     tetrisCount_P1 - BURN_P1, x
        inc     tetrisCount_P1 - BURN_P1, x
@updateLines:
        lda     completedLines
        clc
        adc     binaryLines_P1 - BURN_P1, x
        sta     binaryLines_P1 - BURN_P1, x
        bcc     @dirtyRenderFlags
        inc     binaryLines_P1_HI - BURN_P1, x
@dirtyRenderFlags:
        ;request render update
        lda     tournamentRenderFlags-BURN_P1, x
        ora     #tournamentRenderFlagsBurn|tournamentRenderFlagsTetrisRate
        sta     tournamentRenderFlags-BURN_P1, x

        lda     binaryLines_P1 - BURN_P1, x
        sta     tmp1
        lda     binaryLines_P1_HI - BURN_P1, x
        lsr     a
        lda     tetrisCount_P1 - BURN_P1, x
        bcs     @halfresTetrisRate
        asl     a
        bcc     @calculateTetrisRate

@halfresTetrisRate:
        ror     tmp1

@calculateTetrisRate:
        jsr     calculateTetrisRateBCD
        lda     activePlayer
        tax
        lda     tmp2
        sta     statsByType + TRATE_P1 - 1, x

@rts:
        lda     #$00
        sta     completedLines
        inc     playState
        rts

;check who is in lead and what point difference is there
tournamentLeadCheck:
        lda     outOfDateRenderFlags
        and     #$04
        beq     @rts
        ;score needs update, so we also need to update lead
        lda     #$80
        ldx     player2_score+2
        cpx     player1_score+2
        bne     @calcResult
        ldx     player2_score+1
        cpx     player1_score+1
        bne     @calcResult
        ldx     player2_score
        cpx     player1_score
@calcResult:
        beq     @equal
        rol     a
@equal:
        cmp     statsByType + LEADERID
        beq     @calcLead
        sta     statsByType + LEADERID
        lda     tournamentRenderFlags
        ora     #tournamentRenderFlagsLeadArrow
        sta     tournamentRenderFlags
@calcLead:
        lda     #0
        ldx     statsByType + LEADERID
        beq    @player1InLead

        ;this should toggle between p1 and p2 score adress
        eor     #player2_score-player1_score
@player1InLead:
        ;start with lowest byte
        tax
        sec
        jsr     TournamentLeadSubstractInner
        jsr     TournamentLeadSubstractInner
        jsr     TournamentLeadSubstractInner
        lda     tournamentRenderFlags
        ora     #tournamentRenderFlagsLead
        sta     tournamentRenderFlags
@rts:
        rts

;this reads two BCD number which are part of the scores
;substracts them and puts result into the lead display
;it also prepares the next step of the calculation
;(inc x and set carry)
;x - player + offset of higher score
TournamentLeadSubstractInner:
        ldy     player1_score, x
        txa
        eor     #player2_score-player1_score
        tax
        tya
        sbc     player1_score, x
        bcs     @noCarry
        sbc     #$5f
        clc
@noCarry:
        ror     tmp3
        sta     tmp1
        and     #$0f
        sta     tmp2
        tya
        and     #$0f
        cmp     tmp2
        bcs     @noCarryOnes
        lda     tmp1
        sbc     #$05
        sta     tmp1
@noCarryOnes:
        txa
        eor     #player2_score-player1_score
        tax
        and     #player2_score-player1_score-1
        tay
        lda     tmp1
        sta     statsByType + SCORELEAD, y
        inx
        rol     tmp3
        rts

;increases a bcd value, but the first value can increase to F
;the value will go up to F9 and then stop increasing
;the number to add is stored in a
;the adress is stored in x relative to the begin of statsByType

;warning, this can fail for certain numbers, e.g. 8 + 9 = 11
;should be save for all digits 6 and smaller
increaseBCDStatsToF9:
        clc
        adc     statsByType, x
        bcs     @overflow

        sta     statsByType, x
        and     #$0f
        cmp     #10
        bmi     @rts
        lda     statsByType, x
        clc
        adc     #6
        bcc     @writeA
@overflow:
        lda     #$F9
@writeA:
        sta     statsByType, x
@rts:
        rts

;renders the special tournament statistics to screen
;to save some time it does only update a single number per update
updateTournamentRendering:
@leadArrow:
        lda     tournamentRenderFlags
        and     #tournamentRenderFlagsLeadArrow
        beq     @leadScore
        lda     tournamentRenderFlags
        and     #$ff^tournamentRenderFlagsLeadArrow
        sta     tournamentRenderFlags
@leadArrowWrite:
        lda     #>INGAME_LAYOUT_P1_ARROW
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P1_ARROW
        sta     PPUADDR
        ldy     #$ff
        lda     statsByType + LEADERID
        bne     @firstEmpty
        ldx     #INGAME_LAYOUT_CHARID_ARROWS
        stx     PPUDATA
        inx
        stx     PPUDATA
        bpl     @midEmpty
@firstEmpty:
        sty     PPUDATA
        sty     PPUDATA
@midEmpty:
        sty     PPUDATA
        sty     PPUDATA
@midwritten:
        cmp     #1
        bne     @lastEmpty
        ldx     #INGAME_LAYOUT_CHARID_ARROWS+2
        stx     PPUDATA
        inx
        stx     PPUDATA
        rts
@lastEmpty:
        sty     PPUDATA
        sty     PPUDATA
        rts
@leadScore:
        lda     tournamentRenderFlags
        and     #tournamentRenderFlagsLead
        beq     @trtP1
        lda     tournamentRenderFlags
        and     #$ff^tournamentRenderFlagsLead
        sta     tournamentRenderFlags
@leadScoreWrite:
        lda     #>INGAME_LAYOUT_LEAD
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_LEAD
        sta     PPUADDR
        lda     statsByType + SCORELEAD + 2
        jsr     twoDigsToPPU
        lda     statsByType + SCORELEAD + 1
        jsr     twoDigsToPPU
        lda     statsByType + SCORELEAD + 0
        jmp     twoDigsToPPU

@trtP1:
        lda     tournamentRenderFlags
        and     #tournamentRenderFlagsTetrisRate
        beq     @trtP2
        lda     tournamentRenderFlags
        and     #$ff^tournamentRenderFlagsTetrisRate
        sta     tournamentRenderFlags
@trtP1Write:
        lda     #>INGAME_LAYOUT_P1_TRT
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P1_TRT
        sta     PPUADDR
        lda     statsByType + TRATE_P1
        cmp     #$A0
        beq     @write100
        jmp     twoDigsToPPU
@write100:
        ldx     #INGAME_LAYOUT_CHARID_HUNDRED
        stx     PPUDATA
        inx
        stx     PPUDATA
        rts
@trtP2:
        lda     tournamentRenderFlags + 1
        and     #tournamentRenderFlagsTetrisRate
        beq     @burnP1
        lda     tournamentRenderFlags + 1
        and     #$ff^tournamentRenderFlagsTetrisRate
        sta     tournamentRenderFlags + 1
@trtP2Write:
        lda     #>INGAME_LAYOUT_P2_TRT
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P2_TRT
        sta     PPUADDR
        lda     statsByType + TRATE_P2
        cmp     #$A0
        beq     @write100
        jmp     twoDigsToPPU
@burnP1:
        lda     tournamentRenderFlags
        and     #tournamentRenderFlagsBurn
        beq     @burnP2
        lda     tournamentRenderFlags
        and     #$ff^tournamentRenderFlagsBurn
        sta     tournamentRenderFlags
@burnP1Write:
        lda     #>INGAME_LAYOUT_P1_BURN
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P1_BURN
        sta     PPUADDR
        lda     statsByType + BURN_P1
        jmp     twoDigsToPPU
@burnP2:
        lda     tournamentRenderFlags + 1
        and     #tournamentRenderFlagsBurn
        beq     @droughtP1
        lda     tournamentRenderFlags + 1
        and     #$ff^tournamentRenderFlagsBurn
        sta     tournamentRenderFlags + 1
@burnP2Write:
        lda     #>INGAME_LAYOUT_P2_BURN
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P2_BURN
        sta     PPUADDR
        lda     statsByType + BURN_P2
        jmp     twoDigsToPPU
@droughtP1:
        lda     tournamentRenderFlags
        and     #tournamentRenderFlagsDrought
        beq     @droughtP2
        lda     tournamentRenderFlags
        and     #$ff^tournamentRenderFlagsDrought
        sta     tournamentRenderFlags
@droughtP1Write:
        lda     #>INGAME_LAYOUT_P1_DROUGHT
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P1_DROUGHT
        sta     PPUADDR
        lda     statsByType + DROUGHT_P1
        jmp     twoDigsToPPU
@droughtP2:
        lda     tournamentRenderFlags + 1
        and     #tournamentRenderFlagsDrought
        beq     @end
        lda     tournamentRenderFlags + 1
        and     #$ff^tournamentRenderFlagsDrought
        sta     tournamentRenderFlags + 1
@droughtP2Write:
        lda     #>INGAME_LAYOUT_P2_DROUGHT
        sta     PPUADDR
        lda     #<INGAME_LAYOUT_P2_DROUGHT
        sta     PPUADDR
        lda     statsByType + DROUGHT_P2
        jmp     twoDigsToPPU
@end:
        rts

; calculate Tetris rate from two 8bit numbers and give BCD result
; its possible do to a low resolution calculation for high line counts
; by shifting a and tmp1 beforehand
; reg a: 4 times tetris count binary
; tmp1: line count binary
; tmp2: (out) result in BCD
calculateTetrisRateBCD:
        cmp     tmp1
        bcc     @below100Percent
        lda     #$a0
        sta     tmp2
        rts
@below100Percent:
        ldx     #0      ;multiply by 10
        stx     tmp3    ;{t2,t3} = 4 times tetris count
        sta     tmp2

        asl     tmp2    ;{t2,t3} =<< 2
        rol     tmp3
        asl     tmp2
        rol     tmp3

        clc             ;{a,t3} = {t2,t3} + {a,0}
        adc     tmp2
        bcc     @noCarryTen
        inc     tmp3
@noCarryTen:

        asl     a       ;{a,t3} =<< 1
        rol     tmp3

        tay             ;store the Tetris Count * 40 to {y,x}
        ldx     tmp3

        lda     #$ff    ;prepare output as -1
        sta     tournamentTmp4

;{y,x} now contains Tetris Count * 40
;we repeatly try to substract from this
;the result is the first numer of the BCD
@setSecTen:
        sec
@tenLoop:
        inc     tournamentTmp4

        tya
        sbc     tmp1
        tay
        bcs     @tenLoop
        dex
        bpl     @setSecTen

@fixRemainder:
        ldx     #0      ;{y,x} = {y+tmp1,0}
        tya
        clc
        adc     tmp1
        bne     @doOnes ;calculate one of BCD number
        sta     tournamentTmp5
        beq     @prepareResult
@doOnes:
        stx     tmp3    ;multiply by 10
        sta     tmp2    ;{t2,t3} = 4 times remaining tetris count

        asl     tmp2    ;{t2,t3} =<< 2
        rol     tmp3
        asl     tmp2
        rol     tmp3

        clc             ; {a,t3} = {t2,t3} + {a,0}
        adc     tmp2
        bcc     @noCarryOnes
        inc     tmp3
@noCarryOnes:

        asl     a       ;{a,t3} =<< 1
        rol     tmp3

        tay             ;store the remaining Tetris Count * 400 to {y,x}
        ldx     tmp3


        lda     #$ff    ; prepare output as -1
        sta     tournamentTmp5

@setSecOne:
        sec
@oneLoop:
        inc     tournamentTmp5

        tya
        sbc     tmp1
        tay
        bcs     @oneLoop
        dex
        bpl     @setSecOne

@prepareResult:
        lda     tournamentTmp4
        asl     a
        asl     a
        asl     a
        asl     a
        ora     tournamentTmp5
        sta     tmp2
        rts

.endif
