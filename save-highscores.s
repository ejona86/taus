;
; Enable SRAM and save highscores
;

.include "build/tetris.inc"
.include "ips.inc"

SRAM := $6000
sramMagic := SRAM
sramHighScoreTable := SRAM+5

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

.segment "saveHighscoreStartPressed_patch"
        ips_segment     "saveHighscoreStartPressed_patch",highScoreEntryScreen+$94 ; $A295

; Save high scores after player presses start after entering name

; saveHighscoreStartPressed_patch:
        jmp saveHighScores

.segment "initAndSave"
        ips_segment     "initAndSave",initRamContinued+$13,$4F ; $806D

continueWarmBootInit := initRamContinued+$62 ; $80BC

; Redefine cold boot to mean uninitialized SRAM
checkInit:
        ldx #$05
@checkColdBoot:
        dex
        bmi @warmInit
        lda magicValue,x
        cmp sramMagic,x
        beq @checkColdBoot

; Copy default high scores and magic to SRAM
@coldInit:
        ; Init all of SRAM, in case we use more in the future
        lda #$00
        ldx #>SRAM
        ldy #$7F
        jsr memset_page

        ldx #$50-1
@initSramHighScore:
        lda defaultHighScoresTable,x
        sta sramHighScoreTable,x
        dex
        bpl @initSramHighScore

        ldx #$05-1
@initSramMagic:
        lda magicValue,x
        sta sramMagic,x
        dex
        bpl @initSramMagic

; Copy scores from SRAM every boot; initMagic unused
@warmInit:
        ldx #$50-1
@loadHighScore:
        lda sramHighScoreTable,x
        sta highScoreNames,x
        dex
        bpl @loadHighScore
        jmp continueWarmBootInit

magicValue:
        .byte $12,$34,$56,$78,$9A

; Copy updated scores to SRAM
saveHighScores:
        ldx #$50-1
@loop:
        lda highScoreNames,x
        sta sramHighScoreTable,x
        dex
        bpl @loop
        jmp highScorePosToY-4 ; @ret := $A337

