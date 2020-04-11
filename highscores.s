;
; Custom high scores
;

.include "build/tetris.inc"
.include "tetris-tbl.inc"
.include "ips.inc"

.segment "DEFAULT_HIGH_SCORES"
        ips_segment     "DEFAULT_HIGH_SCORES",defaultHighScoresTable,$0051

; replace defaultHighScoresTable
        set_tbl TBL_HIGHSCORE
        ; NAME
        .byte   "EM.J  "
        .byte   "ASHARA"
        .byte   "ERIC  "
        .byte   "------"
        .byte   "ALEX  "
        .byte   "TONY  "
        .byte   "NINTEN"
        .byte   "------"
        ; SCORE, in BCD
        .byte   $43,$36,$81
        .byte   $41,$19,$67
        .byte   $22,$68,$39
        .byte   $00,$00,$00
        .byte   $00,$20,$00
        .byte   $00,$10,$00
        .byte   $00,$05,$00
        .byte   $00,$00,$00
        ; LV, in binary
        .byte   16,16,11,$00
        .byte   $09,$05,$00,$00
        .byte   $FF

