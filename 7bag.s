;
; Mod that uses a 7-bag for choosing tetriminos
;

.include "build/tetris.inc"
.include "ips.inc"

.segment "PICK_TETRIMINO_PATCH"
        ips_segment     "PICK_TETRIMINO_PATCH",pickRandomTetrimino,$0038

pickRandomTetrimino_7bag:
        lda     spawnID
        bne     @countBits
        lda     #$7F
        sta     spawnID

        ; Count number of pieces remaining in bag
@countBits:
        ldx     #0
@shiftLoop:
        lsr     a
        bcc     @bitClear
        inx                     ; Trashes Z, so bne is unconditional
@bitClear:
        bne     @shiftLoop

        ; Bounded random
@mult:  tay                     ; Set y=0
@multLoop:
        clc
        adc     rng_seed
        bcc     @noCarry
        iny
@noCarry:
        dex
        bne     @multLoop

        ; Find chosen piece
        lda     spawnID
        iny     ; THINGS ARE WEIRD HERE
@nextBit:
        inx
        lsr     a
        bcc     @nextBit
        dey
        bne     @nextBit

        ; Clear chosen piece in spawnID
        txa
        tay
        lda     #$00
        sec
@shiftLeft:
        rol
        dey
        bne     @shiftLeft
        eor     spawnID
        sta     spawnID

        lda     spawnTable,x
        rts

