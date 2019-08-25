;
; Mod that draws into the blank area below the playfield when using a
; handicapping Game Genie code that limits the playfield size.
;
; Use a tool like http://games.technoplaza.net/ggencoder/js/ to generate a Game
; Genie code to change address 94B3. For example AOLPLG will reduce the
; playfield size by 6.
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "CODEHDR"
        ips_hunkhdr     "CODE"

.segment "CODE"

playfieldSize := $94B3

initGameState_mod:
        jsr     memset_page
        lda     playfieldSize
        sec
        sbc     #$02
        ; 20 is too large for multBy10Table
        cmp     #20
        bpl     @ret
        tay
        ldx     multBy10Table,y
        lda     #$4F
@setRows:
        sta     playfield,x
        inx
        cpx     #200
        bne     @setRows
@ret:
        rts

checkForCompletedRows_mod:
        lda     tetriminoY
        clc
        adc     lineIndex
        cmp     playfieldSize
        bpl     @skip
        ; run replaced code
        lda     tetriminoY
        sec
        jmp     afterCheckForCompletedRowsMod
@skip:
        jmp     $9ACC   ; @rowNotComplete

.segment "JMP_INIT_GAME_STATEHDR"
        ips_hunkhdr     "JMP_INIT_GAME_STATE"

.segment "JMP_INIT_GAME_STATE"

; at beginning of initGameState, replaces "jsr memset_page"
        jsr     initGameState_mod

.segment "JMP_CHECK_FOR_COMPLETED_ROWSHDR"
        ips_hunkhdr     "JMP_CHECK_FOR_COMPLETED_ROWS"

.segment "JMP_CHECK_FOR_COMPLETED_ROWS"

; at @updatePlayfieldComplete in playState_checkForCompletedRows, replaces "lda tetriminoY; sec"
        jmp     checkForCompletedRows_mod
afterCheckForCompletedRowsMod:
