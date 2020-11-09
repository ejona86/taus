;
; Mod that displays key presses on-screen
; Originally by Jazzthief81. http://www.romhacking.net/hacks/4785/
;

.include "ips.inc"
.include "build/tetris.inc"

.segment "MOD_UPDATEPLAYER1"
        ips_segment     "MOD_UPDATEPLAYER1",gameModeState_updatePlayer1+12 ; $8180

        jsr stageSpriteForNextPiece_mod

.segment "DISABLE_HEIGHT_DISPLAY"
        ips_segment     "DISABLE_HEIGHT_DISPLAY",$865F

@nextPpuAddress:
        jmp     gameModeState_initGameBackground_finish
        lda     game_typeb_nametable_patch,x
        inx
        sta     PPUADDR
        lda     game_typeb_nametable_patch,x
        inx
        sta     PPUADDR
@nextPpuData:
        lda     game_typeb_nametable_patch,x
        inx
        cmp     #$FE
        beq     @nextPpuAddress
        cmp     #$FD
        beq     @endOfPpuPatching
        sta     PPUDATA
        jmp     @nextPpuData

@endOfPpuPatching:
        lda     #$23
        sta     PPUADDR
        lda     #$3B
        sta     PPUADDR
        lda     startHeight
        and     #$0F
        sta     PPUDATA

.segment "GAME_NAMETABLE"
        ips_segment     "GAME_NAMETABLE",game_nametable,1120

        .incbin "build/TetrisControllerInputDisplay_game.nam.stripe"

.code
        ips_segment     "CODE",unreferenced_data1,$637 ; $D6C9

stageSpriteForNextPiece_mod:
        jsr     stageSpriteForNextPiece
        jsr     stageSpritesForControllerInputDisplay
        rts

stageSpritesForControllerInputDisplay:
        ldy     oamStagingLength
        lda     #$C0
        sta     oamStaging,y
        lda     #$D6
        iny
        sta     oamStaging,y
        lda     heldButtons
        and     #$02
        cmp     #$02
        bne     @leftNotPressed
        lda     #$00
        jmp     @stageLeftSprite

@leftNotPressed:
        lda     #$03
@stageLeftSprite:
        iny
        sta     oamStaging,y
        lda     #$C0
        iny
        sta     oamStaging,y
        lda     #$C0
        iny
        sta     oamStaging,y
        lda     #$C6
        iny
        sta     oamStaging,y
        lda     heldButtons
        and     #$01
        cmp     #$01
        bne     @rightNotPressed
        lda     #$00
        jmp     @stageRightSprite

@rightNotPressed:
        lda     #$03
@stageRightSprite:
        iny
        sta     oamStaging,y
        lda     #$CD
        iny
        sta     oamStaging,y
        lda     #$C6
        iny
        sta     oamStaging,y
        lda     #$E6
        iny
        sta     oamStaging,y
        lda     heldButtons
        and     #$04
        cmp     #$04
        bne     @downNotPressed
        lda     #$00
        jmp     @stageDownSprite

@downNotPressed:
        lda     #$03
@stageDownSprite:
        iny
        sta     oamStaging,y
        lda     #$C7
        iny
        sta     oamStaging,y
        lda     #$C8
        iny
        sta     oamStaging,y
        lda     #$F7
        iny
        sta     oamStaging,y
        lda     heldButtons
        and     #$40
        cmp     #$40
        bne     @bNotPressed
        lda     #$00
        jmp     @stageBSprite

@bNotPressed:
        lda     #$03
@stageBSprite:
        iny
        sta     oamStaging,y
        lda     #$D7
        iny
        sta     oamStaging,y
        lda     #$C8
        iny
        sta     oamStaging,y
        lda     #$F6
        iny
        sta     oamStaging,y
        lda     heldButtons
        and     #$80
        cmp     #$80
        bne     @aNotPressed
        lda     #$00
        jmp     @stageASprite

@aNotPressed:
        lda     #$03
@stageASprite:
        iny
        sta     oamStaging,y
        lda     #$E0
        iny
        sta     oamStaging,y
        tya
        clc
        adc     oamStagingLength
        sta     oamStagingLength
        rts

.res 1359

.segment "IPSCHRC6"
        ips_tile_segment        "IPSCHRC6",CHR01+CHR_RIGHT,$C6

        ; right
        .incbin "build/TetrisControllerInputDisplay.chrs/00"

.segment "IPSCHRD6"
        ips_tile_segment        "IPSCHRD6",CHR01+CHR_RIGHT,$D6

        ; left
        .incbin "build/TetrisControllerInputDisplay.chrs/01"

.segment "IPSCHRE6"
        ips_tile_segment        "IPSCHRE6",CHR01+CHR_RIGHT,$E6

        ; down
        .incbin "build/TetrisControllerInputDisplay.chrs/02"

.segment "IPSCHRF6"
        ips_tile_segment        "IPSCHRF6",CHR01+CHR_RIGHT,$F6

        ; button a
        .incbin "build/TetrisControllerInputDisplay.chrs/03"

        ; button b
        .incbin "build/TetrisControllerInputDisplay.chrs/04"
