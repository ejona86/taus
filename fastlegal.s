;
; Mod that allows pressing start to skip legal screen
;

.include "ips.inc"

.segment "SKIP_LEGALHDR"
        ips_hunkhdr     "SKIP_LEGAL"

.segment "SKIP_LEGAL"

; Allow skipping legal screen
        lda     #$00
