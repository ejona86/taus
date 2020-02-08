IPSCHROFFSET = 0
.include "ips.inc"

.segment "IPSCHR"

.ifdef TOURNAMENT_MODE
NEXT_ON_TOP = 0

    .include "tournament.screenlayout.inc"

    ips_tilehdr CHR_RIGHT,INGAME_LAYOUT_CHARID_HUNDRED
    .incbin "build/twoplayer.chrs/1a"

    ips_tilehdr CHR_RIGHT,INGAME_LAYOUT_CHARID_HUNDRED+1
    .incbin "build/twoplayer.chrs/1b"

    ips_tilehdr CHR_RIGHT,INGAME_LAYOUT_CHARID_ARROWS
    .incbin "build/twoplayer.chrs/1e"

    ips_tilehdr CHR_RIGHT,INGAME_LAYOUT_CHARID_ARROWS+1
    .incbin "build/twoplayer.chrs/1f"

    ips_tilehdr CHR_RIGHT,INGAME_LAYOUT_CHARID_ARROWS+2
    .incbin "build/twoplayer.chrs/1c"

    ips_tilehdr CHR_RIGHT,INGAME_LAYOUT_CHARID_ARROWS+3
    .incbin "build/twoplayer.chrs/1d"

.endif

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
