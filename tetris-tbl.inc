TBL_HIGHSCORE = $FFFF

; Sets the charmap for the requested CHR data. The special address $FFFF
; indicates the high score charmap should be used (highScoreCharToTile).
;
; For example:
;     set_tbl CHR01+CHR_RIGHT
.macro set_tbl mapper_addr
.repeat 256,I
.charmap I,$FC ; <replacement character> "single-color tile"
.endrep

.if mapper_addr = $0000 || mapper_addr = $3000
.charmap $30,$00 ; 0
.charmap $31,$01 ; 1
.charmap $32,$02 ; 2
.charmap $33,$03 ; 3
.charmap $34,$04 ; 4
.charmap $35,$05 ; 5
.charmap $36,$06 ; 6
.charmap $37,$07 ; 7
.charmap $38,$08 ; 8
.charmap $39,$09 ; 9
.charmap $41,$0A ; A
.charmap $42,$0B ; B
.charmap $43,$0C ; C
.charmap $44,$0D ; D
.charmap $45,$0E ; E
.charmap $46,$0F ; F
.charmap $47,$10 ; G
.charmap $48,$11 ; H
.charmap $49,$12 ; I
.charmap $4A,$13 ; J
.charmap $4B,$14 ; K
.charmap $4C,$15 ; L
.charmap $4D,$16 ; M
.charmap $4E,$17 ; N
.charmap $4F,$18 ; O
.charmap $50,$19 ; P
.charmap $51,$1A ; Q
.charmap $52,$1B ; R
.charmap $53,$1C ; S
.charmap $54,$1D ; T
.charmap $55,$1E ; U
.charmap $56,$1F ; V
.charmap $57,$20 ; W
.charmap $58,$21 ; X
.charmap $59,$22 ; Y
.charmap $5A,$23 ; Z
.charmap $2D,$24 ; -
.charmap $2C,$25 ; ,
.if mapper_addr = $0000
.charmap $27,$26 ; '
.charmap $2F,$4F ; /
.charmap $21,$52 ; !
.charmap $28,$5E ; (
.charmap $29,$5F ; )
.charmap $22,$6E ; "
.charmap $2E,$6F ; .
.else ; mapper_addr = $3000
.charmap $2E,$26 ; .
.charmap $21,$28 ; !
.endif
.charmap $20,$FF ; <space>

.elseif mapper_addr = $1000 || mapper_addr = $2000

.charmap $30,$00 ; 0
.charmap $31,$01 ; 1
.charmap $32,$02 ; 2
.charmap $33,$03 ; 3
.charmap $34,$04 ; 4
.charmap $35,$05 ; 5
.charmap $36,$06 ; 6
.charmap $37,$07 ; 7
.charmap $38,$08 ; 8
.charmap $39,$09 ; 9
.charmap $53,$0A ; S
.charmap $43,$0B ; C
.charmap $4F,$0C ; O
.charmap $52,$0D ; R
.charmap $45,$0E ; E
.charmap $4C,$0F ; L
.charmap $56,$10 ; V
.charmap $48,$11 ; H
.charmap $49,$12 ; I
.charmap $47,$13 ; G
.charmap $54,$14 ; T
.charmap $41,$15 ; A
.charmap $2D,$16 ; -
.charmap $20,$FF ; <space>

.elseif mapper_addr = $FFFF

; Defined by highScoreCharToTile mapped through CHR00+CHR_LEFT
.repeat 256,I
.charmap I,$27 ; <replacement character> "("
.endrep
.charmap $2D,$00 ; -
.charmap $41,$01 ; A
.charmap $42,$02 ; B
.charmap $43,$03 ; C
.charmap $44,$04 ; D
.charmap $45,$05 ; E
.charmap $46,$06 ; F
.charmap $47,$07 ; G
.charmap $48,$08 ; H
.charmap $49,$09 ; I
.charmap $4A,$0A ; J
.charmap $4B,$0B ; K
.charmap $4C,$0C ; L
.charmap $4D,$0D ; M
.charmap $4E,$0E ; N
.charmap $4F,$0F ; O
.charmap $50,$10 ; P
.charmap $51,$11 ; Q
.charmap $52,$12 ; R
.charmap $53,$13 ; S
.charmap $54,$14 ; T
.charmap $55,$15 ; U
.charmap $56,$16 ; V
.charmap $57,$17 ; W
.charmap $58,$18 ; X
.charmap $59,$19 ; Y
.charmap $5A,$1A ; Z
.charmap $30,$1B ; 0
.charmap $31,$1C ; 1
.charmap $32,$1D ; 2
.charmap $33,$1E ; 3
.charmap $34,$1F ; 4
.charmap $35,$20 ; 5
.charmap $36,$21 ; 6
.charmap $37,$22 ; 7
.charmap $38,$23 ; 8
.charmap $39,$24 ; 9
.charmap $2C,$25 ; ,
.charmap $2F,$26 ; /
.charmap $28,$27 ; (
.charmap $29,$28 ; )
.charmap $22,$29 ; "
.charmap $2E,$2A ; .
.charmap $20,$2B ; <space>

.else

.error .sprintf("Unknown address to set_tbl: %d", mapper_addr)

.endif
.endmacro
