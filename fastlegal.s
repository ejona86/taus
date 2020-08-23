;
; Mod that allows pressing start to skip legal screen
;

.include "ips.inc"
.include "build/tetris.inc"

.segment "SKIP_LEGAL"
        ips_segment     "SKIP_LEGAL",gameMode_legalScreen+54 ; $8236

; Allow skipping legal screen
        lda     #$00
