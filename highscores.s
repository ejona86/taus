;
; Custom high scores
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "DEFAULT_HIGH_SCORES"
        ips_segment     "DEFAULT_HIGH_SCORES",defaultHighScoresTable,$0051

; replace defaultHighScoresTable
        ; NAME
        ; # Convert ALPHA string to hex:
        ; list(map(lambda x: hex(ord(x)-64), "CHEATR"))
        .byte   $05,$0D,$2A,$0A,$2B,$2B ; "EM.J  "
        .byte   $01,$13,$08,$01,$12,$01 ; "ASHARA"
        .byte   $05,$12,$09,$03,$2B,$2B ; "ERIC  "
        .byte   $00,$00,$00,$00,$00,$00
        .byte   $01,$0C,$05,$18,$2B,$2B
        .byte   $14,$0F,$0E,$19,$2B,$2B
        .byte   $0E,$09,$0E,$14,$05,$0E
        .byte   $00,$00,$00,$00,$00,$00
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

