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

initPlayfield_mod:
        beq     @typeA
        lda     #20+2
        sta     player1_playfieldSize
        sta     player2_playfieldSize
        jmp     $87E3   ; @initPlayfieldForTypeB

@typeA:
        ldx     player1_startHeight
        lda     heightToSizeTable,x
        sta     player1_playfieldSize
        ldx     player2_startHeight
        lda     heightToSizeTable,x
        sta     player2_playfieldSize

        lda     #$4F
        ldx     #$04
        ldy     #$05
        jsr     memset_page
        ; right after "bne @copyPlayfieldToPlayer2" in initPlayfieldIfTypeB
        jmp     $8855


heightToSizeTable:
        .byte   20+2, 17+2, 15+2, 12+2, 10+2, 8+2


checkForCompletedRows_mod:
        tay     ; replaced code
        lda     generalCounter2
        adc     #$02
        cmp     playfieldSize
        bmi     @noskip
        ldy     #$FF    ; (playfieldAddr),#$FF is always $EF
@noskip:
        ldx     #$0A    ; replaced code
        rts

.segment "JMP_INIT_PLAYFIELDHDR"
        ips_hunkhdr     "JMP_INIT_PLAYFIELD"

.segment "JMP_INIT_PLAYFIELD"

; within initPlayfieldIfTypeB, replaces "bne @initPlayfieldForTypeB" and a byte
; of the next jmp instruction
        jmp     initPlayfield_mod

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

.segment "INIT_PLAYFIELD_IF_TYPE_B_CLEAR1HDR"
        ips_hunkhdr     "INIT_PLAYFIELD_IF_TYPE_B_CLEAR1"

.segment "INIT_PLAYFIELD_IF_TYPE_B_CLEAR1"

; at @emptyAboveHeight_player1 in initPlayfieldIfTypeB, replaces "sta playfield,y; dey; cpy #$FF".
        ; Reorder dey to avoid off-by-one bug in
        ; typeBBlankInitCountByHeightTable
        dey
        sta     playfield,y
        ; This causes the emptying loop to underflow and clear the unused
        ; memory at the top of the page, which is necessary for isPositionValid
        cpy     #$C8+1

.segment "INIT_PLAYFIELD_IF_TYPE_B_CLEAR2HDR"
        ips_hunkhdr     "INIT_PLAYFIELD_IF_TYPE_B_CLEAR2"

.segment "INIT_PLAYFIELD_IF_TYPE_B_CLEAR2"

; at @emptyAboveHeight_player2 in initPlayfieldIfTypeB, replaces "sta playfieldForSecondPlayer,y; dey; cpy #$FF".
        dey
        sta     playfieldForSecondPlayer,y
        cpy     #$C8+1
