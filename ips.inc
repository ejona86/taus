IPSPRGOFFSET = 16-$8000

; Generates an IPS hunk header for named segment, which specifes the location
; and length where an IPS tool will place the segment in the modded file.
;
; The code:
;       ips_hunkhdr "HUNK1"
; Is equivalent to:
;	.import __HUNK1_LOAD__, __HUNK1_SIZE__
;	.byte 0
;	.dbyt __HUNK1_LOAD__+IPSPRGOFFSET
;	.dbyt __HUNK1_SIZE__
.macro ips_hunkhdr name
	.import .ident(.concat("__", name, "_LOAD__"))
	.import .ident(.concat("__", name, "_SIZE__"))
	.byte 0
	; Dunno why -(-x) is necessary. But otherwise get a range error
	.dbyt .ident(.concat("__", name, "_LOAD__"))-(-IPSPRGOFFSET)
	.dbyt .ident(.concat("__", name, "_SIZE__"))
.endmacro

IPSCHROFFSET = 16+$8000
CHR00 = $0000
CHR01 = $2000
CHR_LEFT = $0000
CHR_RIGHT = $1000
TILE_SIZE = $10

; Generates an IPS hunk header for tiles, which specifes the location and
; length where an IPS tool will place the tiles in the modded file.
;
; For example, to replace a tile in the "left" (first) section of CHR01 in at
; row 0 and column 3:
;       ips_tilehdr CHR01+CHR_LEFT,$03
.macro ips_tilehdr mapper_addr,tile
	.byte 0
	.dbyt (mapper_addr)+(tile*TILE_SIZE)+IPSCHROFFSET
	.dbyt TILE_SIZE
.endmacro
