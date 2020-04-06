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

.segment "JMP_GAME_SHOW_PLAYERID_BGHDR"
        ips_hunkhdr     "JMP_GAME_SHOW_PLAYERID_BG"

.segment "JMP_GAME_SHOW_PLAYERID_BG"

; in initGameBackground; replaces "jsr waitForVBlankAndEnableNmi"
        jsr     game_show_playerid_game_mod

.segment "JMP_MENU_SHOW_PLAYERID_BGHDR"
        ips_hunkhdr     "JMP_MENU_SHOW_PLAYERID_BG"

.segment "JMP_MENU_SHOW_PLAYERID_BG"

; in render_mode_menu_screens; replaces "sta PPUSCROLL"
        jsr     game_show_playerid_menu_mod

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

        ; replaced code
        lda     newlyPressedButtons
        cmp     #$01
        rts

game_show_playerid_menu_mod:
        sta     PPUSCROLL
        lda     gameMode
        cmp     #$03    ; level menu
        beq     game_show_playerid_bg
        rts

game_show_playerid_game_mod:
        lda     playerId
        beq     @done
        jsr     game_show_playerid_bg
@done:
        jmp     waitForVBlankAndEnableNmi       ; replaced code

game_show_playerid_bg:
        lda     #$20
        sta     PPUADDR
        lda     #$3F
        sta     PPUADDR
        lda     playerId
        bne     @display
        lda     #$82    ; hard-coded original select screen tile
@display:
        sta     PPUDATA
        rts
