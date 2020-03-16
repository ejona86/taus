;
; Mod that draws into the blank area below the playfield when selecting a height; in Type A.
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "TYPE_A_MENU_PATCHHDR"
        ips_hunkhdr     "TYPE_A_MENU_PATCH"

.segment "TYPE_A_MENU_PATCH"

; height_menu_nametablepalette_patch:
        .byte   $3F,$0A,$01,$16
        .byte   $20,$6D,$01,$0A
        .byte   $FF

playfieldSize := $0043
player1_playfieldSize := $0063
player2_playfieldSize := $0084

initGameState_mod:
        jsr     chooseNextTetrimino     ; replaced code

        jsr     makePlayer1Active
        jsr     initPlayfieldSize
        jsr     savePlayer1State

        jsr     makePlayer2Active
        jsr     initPlayfieldSize
        jmp     savePlayer2State

initPlayfieldSize:
        lda     gameType
        bne     @typeB

        ldx     startHeight
        ldy     typeBBlankInitCountByHeightTable,x
        lda     #$4F
@setRows:
        cpy     #200
        beq     @ret
        sta     (playfieldAddr),y
        iny
        bne     @setRows

@typeB:
        ldx     #$00
@ret:
        lda     heightToSizeTable,x
        sta     playfieldSize
        rts


heightToSizeTable:
        .byte   20+2, 17+2, 15+2, 12+2, 10+2, 8+2

.segment "UNREFERENCED_DATA3HDR"
        ips_hunkhdr     "UNREFERENCED_DATA3"

.segment "UNREFERENCED_DATA3"

checkForCompletedRows_mod:
        tay     ; replaced code
        lda     generalCounter2
        ; clc performed recently
        adc     #$02
        cmp     playfieldSize
        bmi     @noskip
        ldy     #$FF    ; (playfieldAddr),#$FF is always $EF
@noskip:
        ldx     #$0A    ; replaced code
        rts

.segment "JMP_INIT_GAME_STATEHDR"
        ips_hunkhdr     "JMP_INIT_GAME_STATE"

.segment "JMP_INIT_GAME_STATE"

; within initGameState, replaces "jsr chooseNextTetrimino" after "sta player2_autorepeatY"
        jsr     initGameState_mod

.segment "JMP_CHECK_FOR_COMPLETED_ROWSHDR"
        ips_hunkhdr     "JMP_CHECK_FOR_COMPLETED_ROWS"

.segment "JMP_CHECK_FOR_COMPLETED_ROWS"

; at @yInRange in playState_checkForCompletedRows, replaces "tay; ldx #$0A"
        jsr     checkForCompletedRows_mod

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
