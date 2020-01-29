IPSCHROFFSET = 0
.include "ips.inc"

.segment "IPSCHR"

.ifdef TOURNAMENT_MODE
.include "tournament-CHR.inc"
.else

    .ifdef NEXT_ON_TOP
            ips_tilehdr CHR_RIGHT,$68
            .incbin "build/twoplayer.chrs/18"
    .endif
    
            ips_tilehdr CHR_RIGHT,$76
            .incbin "build/twoplayer.chrs/04"
    
            ips_tilehdr CHR_RIGHT,$86
            .incbin "build/twoplayer.chrs/05"
    
            ips_tilehdr CHR_RIGHT,$8C
            .incbin "build/twoplayer.chrs/00"
    
    .ifndef NEXT_ON_TOP
            ips_tilehdr CHR_RIGHT,$8D
            .incbin "build/twoplayer.chrs/01"
    
            ips_tilehdr CHR_RIGHT,$9C
            .incbin "build/twoplayer.chrs/02"
    .else
            ips_tilehdr CHR_RIGHT,$8D
            .incbin "build/twoplayer.chrs/11"
    
            ips_tilehdr CHR_RIGHT,$9B
            .incbin "build/twoplayer.chrs/19"
    
            ips_tilehdr CHR_RIGHT,$9C
            .incbin "build/twoplayer.chrs/12"
    .endif
    
            ips_tilehdr CHR_RIGHT,$9D
            .incbin "build/twoplayer.chrs/03"
    
    .ifdef NEXT_ON_TOP
            ips_tilehdr CHR_RIGHT,$9E
            .incbin "build/twoplayer.chrs/16"
    
            ips_tilehdr CHR_RIGHT,$9F
            .incbin "build/twoplayer.chrs/17"
    .endif

.endif
