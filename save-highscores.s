.include "build/tetris.inc"
.include "ips.inc"

SRAM := $6000

; header patch to enable SRAM

.fileopt    comment, "ips: 0 INES_HEADER_MOD"
.segment "INES_HEADER_MOD_HDR"
        .byte 0
        .dbyt 6 ; header offset
        .dbyt 1 ; byte sized
.segment "INES_HEADER_MOD"

INES_MAPPER = 1 ; 0 = NROM
INES_MIRROR = 0 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 1 ; 1 = battery backed SRAM at $6000-7FFF

        .byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)

; patch to load from SRAM (and use a length instead of a terminator)

.segment "initHighScoreTable_patch"
        ; Address happens to be same for PAL
        ips_segment     "initHighScoreTable_patch",$8095

; initHighScoreTable_patch:
initHighScoreTable:
        lda SRAM,x
        cpx #$50

; start button patch to add saving

.segment "saveHighscoreStartPressed_patch"
        ips_segment     "saveHighscoreStartPressed_patch",highScoreEntryScreen+$94 ; $A295

; saveHighscoreStartPressed_patch:
        jmp saveHighScores

; routine for storing the high score data

.segment "saveHighScores"
        ips_segment     "saveHighScores",defaultHighScoresTable

saveHighScores:
        ldx #$00
@loop:
        lda highScoreNames,x
        sta SRAM,x
        inx
        cpx #$51
        bne @loop
        jmp highScorePosToY-4 ; @ret := $A337
