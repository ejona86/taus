;
; Mod that draws into the blank area below the playfield when selecting a height; in Type A.
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "CODEHDR"
        ips_hunkhdr     "CODE"

.segment "CODE"

playfieldSize := $0003

initGameState_mod:
        jsr     memset_page
        lda     gameType
        bne     @typeB
        ldy     startHeight
        lda     heightToSizeTable,y
        sta     playfieldSize
        ldx     typeBBlankInitCountByHeightTable,y
        lda     #$4F
@setRows:
        cpx     #200
        beq     @ret
        sta     playfield,x
        inx
        bne     @setRows
@typeB:
        lda     #$16
        sta     playfieldSize
@ret:
        rts

heightToSizeTable:
        .byte   20+2, 17+2, 15+2, 12+2, 10+2, 8+2

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

.segment "TYPE_A_MENU_PATCHHDR"
        ips_hunkhdr     "TYPE_A_MENU_PATCH"

.segment "TYPE_A_MENU_PATCH"

; height_menu_nametablepalette_patch:
        .byte   $3F,$0A,$01,$16
        .byte   $20,$6D,$01,$0A
        .byte   $FF

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

.segment "ENABLE_HEIGHT_IN_TYPE_AHDR"
        ips_hunkhdr     "ENABLE_HEIGHT_IN_TYPE_A"

.segment "ENABLE_HEIGHT_IN_TYPE_A"

; at @checkAPressed in gameMode_levelMenu, replaces "lda gameType"
        lda     #$01

.segment "ENABLE_HEIGHT_IN_TYPE_A2HDR"
        ips_hunkhdr     "ENABLE_HEIGHT_IN_TYPE_A2"

.segment "ENABLE_HEIGHT_IN_TYPE_A2"

; at @skipShowingSelectionLevel in gameMode_levelMenu, replaces "lda gameType"
        lda     #$01

.segment "IS_POSITION_VALID_MODHDR"
        ips_hunkhdr     "IS_POSITION_VALID_MOD"

.segment "IS_POSITION_VALID_MOD"

; at @checkSquare in isPositionValid, replaces "cmp #$16"
        cmp     playfieldSize
