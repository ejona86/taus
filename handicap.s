;
; Mod that draws into the blank area below the playfield when using a
; handicapping Game Genie code that limits the playfield size.
;
; Use a tool like http://games.technoplaza.net/ggencoder/js/ to generate a Game
; Genie code to change address 14B3. For example AOLPLG will reduce the
; playfield size by 6.
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "CODEHDR"
        ips_hunkhdr     "CODE"

.segment "CODE"

playfieldSize := $94B3

initGameState_mod:
        lda     playfieldSize
        sec
        sbc     #$02
        cmp     #20
        beq     @ret
        tax
        ldy     multBy10Table,x
        lda     #$4F
        ldx     #9
@initialRow:
        sta     playfield,y
        iny
        dex
        bne     @initialRow
        iny

@laterRows:
        cpy     #20*10
        beq     @ret
        sta     playfield,y
        iny
        bne     @laterRows
@ret:
        rts

.segment "JMP_INIT_GAME_STATEHDR"
        ips_hunkhdr     "JMP_INIT_GAME_STATE"

.segment "JMP_INIT_GAME_STATE"

; at beginning of initGameState, replaces "jsr memset_page"
        jsr initGameState_mod


