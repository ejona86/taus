;
; Mod that shows a player id for discerning who was playing in a recording. The
; player id is specified by pressing 'select' on the level selection screen.
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "JMP_LEVEL_MENU_CHECK_SELECT_PRESSEDHDR"
        ips_hunkhdr     "JMP_LEVEL_MENU_CHECK_SELECT_PRESSED"

.segment "JMP_LEVEL_MENU_CHECK_SELECT_PRESSED"

; at gameMode_levelMenu_handleLevelHeightNavigation, replaces "lda newlyPressedButtons; cmp #$01"
        jsr     level_menu_check_select_pressed
        nop

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

.segment "CODEHDR"
        ips_hunkhdr     "CODE"

.segment "CODE"

playerId := $0003

level_menu_check_select_pressed:
        lda     newlyPressedButtons
        cmp     #$20
        bne     @render
        inc     playerId
        lda     playerId
        and     #$07
        sta     playerId
@render:
.ifdef PLAYERID_SPRITE
        jsr     stagePlayerIdSprite
.endif

        ; replaced code
        lda     newlyPressedButtons
        cmp     #$01
        rts

.ifdef PLAYERID_SPRITE
game_show_playerid_sprite:
        jsr     stageSpriteForNextPiece
stagePlayerIdSprite:
        lda     playerId
        beq     @ret
        ldx     oamStagingLength
        lda     #$07
        sta     oamStaging,x
        inx
        lda     playerId
        sta     oamStaging,x
        inx
        lda     gameMode
        cmp     #$03
        beq     @menu
        lda     #$03
        jmp     @control
@menu:
        lda     #$00
@control:
        sta     oamStaging,x
        inx
        lda     #$F8
        sta     oamStaging,x
        inx
        stx     oamStagingLength
@ret:
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
        bne     @display
        lda     #$82
@display:
        sta     PPUDATA
        rts
.endif
