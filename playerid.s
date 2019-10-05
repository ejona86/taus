;
; Mod that shows a player id for discerning who was playing in a recording. The
; player id is specified by pressing 'select' on the level selection screen.
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "JMP_LEVEL_MENU_CHECK_SELECT_PRESSEDHDR"
        ips_hunkhdr     "JMP_LEVEL_MENU_CHECK_SELECT_PRESSED"

.segment "JMP_LEVEL_MENU_CHECK_SELECT_PRESSED"

; at start of @showSelection, replaces "lda selectingLevelOrHeight; bne @showSelectionLevel"
        jmp     level_menu_check_select_pressed
        nop
afterJmpLevelMenuCheckSelectPressedMod:

.segment "JMP_GAME_SHOW_PLAYERID_SPRITEHDR"
        ips_hunkhdr     "JMP_GAME_SHOW_PLAYERID_SPRITE"

.segment "JMP_GAME_SHOW_PLAYERID_SPRITE"

.ifdef PLAYERID_SPRITE
; in branchOnGameMode; replaces "jsr stageSpriteForNextPiece"
        jsr     game_show_playerid_sprite
.else
        jsr     stageSpriteForNextPiece
.endif

.segment "JMP_GAME_SHOW_PLAYERID_BGHDR"
        ips_hunkhdr     "JMP_GAME_SHOW_PLAYERID_BG"

.segment "JMP_GAME_SHOW_PLAYERID_BG"

.ifndef PLAYERID_SPRITE
; in initGameBackground; replaces "jsr twoDigsToPPU"
        jsr     game_show_playerid_game_mod
.else
        jsr     twoDigsToPPU
.endif

.segment "JMP_MENU_SHOW_PLAYERID_BGHDR"
        ips_hunkhdr     "JMP_MENU_SHOW_PLAYERID_BG"

.segment "JMP_MENU_SHOW_PLAYERID_BG"

.ifndef PLAYERID_SPRITE
; in render_mode_menu_screens; replaces "sta PPUSCROLL"
        jsr     game_show_playerid_menu_mod
.else
        sta     PPUSCROLL
.endif

.segment "CODE"

playerId := $0003
showSelectionLevel := $855F

level_menu_check_select_pressed:
        lda     newlyPressedButtons
        cmp     #$20
        bne     level_menu_check_select_pressed_render
        lda     playerId
        cmp     #$07
        beq     reset_playerid
        inc     playerId
        jmp     level_menu_check_select_pressed_render
reset_playerid:
        lda     #$00
        sta     playerId
level_menu_check_select_pressed_render:
.ifdef PLAYERID_SPRITE
        jsr     stagePlayerIdSprite
.endif

        lda     selectingLevelOrHeight
        bne     level_menu_check_select_return_level
        jmp     afterJmpLevelMenuCheckSelectPressedMod
level_menu_check_select_return_level:
        jmp     showSelectionLevel

.ifdef PLAYERID_SPRITE
game_show_playerid_sprite:
        jsr     stageSpriteForNextPiece
stagePlayerIdSprite:
        lda     playerId
        beq     stagePlayerIdSprite_return
        ldx     oamStagingLength
        lda     #$07
        sta     oamStaging,x
        inx
        lda     playerId
        sta     oamStaging,x
        inx
        lda     gameMode
        cmp     #$03
        beq     stagePlayerIdSprite_menu
        lda     #$03
        jmp     stagePlayerIdSprite_control
stagePlayerIdSprite_menu:
        lda     #$00
stagePlayerIdSprite_control:
        sta     oamStaging,x
        inx
        lda     #$F8
        sta     oamStaging,x
        inx
        stx     oamStagingLength
stagePlayerIdSprite_return:
        rts

.else

game_show_playerid_menu_mod:
        sta     PPUSCROLL
        lda     gameMode
        cmp     #$03    ; level menu
        beq     game_show_playerid_bg
        rts
game_show_playerid_game_mod:
        jsr     twoDigsToPPU
        lda     playerId
        bne     game_show_playerid_bg
        rts
game_show_playerid_bg:
        lda     #$20
        sta     PPUADDR
        lda     #$3F
        sta     PPUADDR
        lda     playerId
        bne     game_show_playerid_bg_display
        lda     #$82
game_show_playerid_bg_display:
        sta     PPUDATA
        rts
.endif
