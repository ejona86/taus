;
; Mod that displays key presses on-screen
; Originally by Jazzthief81. http://www.romhacking.net/hacks/4785/
;

.include "ips.inc"
.include "build/tetris.inc"

.segment "MOD_UPDATEPLAYER1"
        ips_segment     "MOD_UPDATEPLAYER1",gameModeState_updatePlayer1+12 ; $8180

        jsr stageSpriteForNextPiece_mod

.segment "GAME_NAMETABLE"
        ips_segment     "GAME_NAMETABLE",game_nametable,1120

        .incbin "build/TetrisControllerInputDisplay_game.nam.stripe"

.segment "DISABLE_HEIGHT_DISPLAY"
        ; Address happens to be same for PAL
        ips_segment     "DISABLE_HEIGHT_DISPLAY",$865F,$34

        jmp     gameModeState_initGameBackground_finish

heldDownPalette = $00
controllerOamTemplate:
        .byte   $C0,$D6,$03,$C0
        .byte   $C0,$C6,$03,$CD
        .byte   $C6,$E6,$03,$C7
        .byte   $C8,$F7,$03,$D7
        .byte   $C8,$F6,$03,$E0
controllerOamTemplate_end:

stageSpriteForNextPiece_mod:
        jsr     stageSpriteForNextPiece

        lda     numberOfPlayers
        cmp     #$01
        beq     @onePlayer
        rts

@onePlayer:
        ldy     oamStagingLength
        ldx     #0
@copyTemplateByte:
        lda     controllerOamTemplate,x
        sta     oamStaging,y
        inx
        iny
        cpx     #controllerOamTemplate_end-controllerOamTemplate
        bne     @copyTemplateByte

        jmp stageSpriteForNextPiece_mod_secondHalf

.code
        ips_segment     "CODE",game_typeb_nametable_patch,$2C


stageSpriteForNextPiece_mod_secondHalf:
        tya
        ldy     oamStagingLength
        sta     oamStagingLength

        ; y=oamStaging offset, x=current button
        iny
        iny
        ldx     #0
@checkButton:
        lda     heldButtons
        and     buttonMask,x
        beq     @notHeld
        lda     #heldDownPalette
        sta     oamStaging,y
@notHeld:
        tya
        clc
        adc     #4
        tay
        inx
        cpx     #numberOfButtons
        bne     @checkButton

        rts

numberOfButtons = 5
buttonMask:
        .byte   $02     ; left
        .byte   $01     ; right
        .byte   $04     ; down
        .byte   $40     ; b
        .byte   $80     ; a


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
