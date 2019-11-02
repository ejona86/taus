; Konami RLE decompressor
;
; Encoding:
;   $00     Unsupported (useless)
;   <= $80  Repeat next byte n times
;   $FF     End
;   > $80   Next (n-128) bytes are literal

addrLo  := $0000
addrHi  := addrLo+1
PPUDATA := $2007

; Decodes Konami RLE-encoded stream with address stored at $0000.
;
; Does not support 0-length runs; control byte $00 is not supported
rleDecodeToPpu:
        ; y is current input offset
        ; x is chunk length remaining
        .export rleDecodeToPpu
        ldy     #$00

@processChunk:
        lda     (addrLo),y
        cmp     #$81
        bmi     @runLength
        cmp     #$FF
        beq     @ret
        and     #$7F

; literalLength
        tax
@literalLoop:
        iny
        lda     (addrLo),y
        sta     PPUDATA
        dex
        bne     @literalLoop
        beq     @preventYOverflow

@runLength:
        tax
        iny
        lda     (addrLo),y
@runLengthLoop:
        sta     PPUDATA
        dex
        bne     @runLengthLoop

@preventYOverflow:
        ; The largest input chunk size is literal with a length of 126, which
        ; is 127 bytes of input. We make sure adding 127 to y does not
        ; overflow. This allows us to ignore y overflow during loops.
        iny
        bpl     @processChunk
        ; y is at risk of overflowing next chunk
        tya
        ldy     #$00
        clc
        adc     addrLo
        sta     addrLo
        bcc     @processChunk
        inc     addrHi
        jmp     @processChunk

@ret:
        rts
