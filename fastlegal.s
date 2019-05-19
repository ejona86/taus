;
; Mod that allows pressing start to skip legal screen
;

.include "ips.inc"

.segment "SKIP_LEGALHDR"
.import __SKIP_LEGAL_RUN__, __SKIP_LEGAL_SIZE__
.byte 0
.dbyt __SKIP_LEGAL_RUN__-IPSPRGOFFSET
.dbyt __SKIP_LEGAL_SIZE__

.segment "SKIP_LEGAL"

; Allow skipping legal screen
        lda     #$00
