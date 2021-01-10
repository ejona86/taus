;
; Mod that says Jonas is the Tetris Master. RIP
;

.include "ips.inc"
.include "build/tetris.inc"
.include "tetris-tbl.inc"

.segment "ENTER_HIGH_SCORE_NAMETABLE"
        ips_segment     "ENTER_HIGH_SCORE_NAMETABLE",$C39D,1024/32*35

        .incbin "build/enter_high_score_nametable_jonas.nam.stripe"

.segment "DEFAULT_HIGH_SCORES"
        ips_segment     "DEFAULT_HIGH_SCORES",defaultHighScoresTable,$0051

; replace defaultHighScoresTable
        set_tbl TBL_HIGHSCORE
        ; NAME
        .byte   "JONAS "
        .byte   "HOWARD"
        .byte   "OTASAN"
        ;.byte   "LANCE"
        .byte   "------"
        .byte   "ALEX  "
        .byte   "TONY  "
        .byte   "NINTEN"
        .byte   "------"
        ; SCORE, in BCD
        .byte   $99,$99,$99
        .byte   $01,$00,$00
        .byte   $00,$75,$00
        ;.byte   $00,$50,$00
        .byte   $00,$00,$00
        .byte   $00,$20,$00
        .byte   $00,$10,$00
        .byte   $00,$05,$00
        .byte   $00,$00,$00
        ; LV, in binary
        .byte   29,9,5,$00
        .byte   $09,$05,$00,$00
        .byte   $FF

