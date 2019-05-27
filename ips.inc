IPSPRGOFFSET = -16+$8000

; Generates an IPS hunk header for named segment, which specifes the location
; and length where an IPS tool will place the segment in the modded file.
;
; The code:
;       ips_hunkhdr "HUNK1"
; Is equivalent to:
;	.import __HUNK1_LOAD__, __HUNK1_SIZE__
;	.byte 0
;	.dbyt __HUNK1_LOAD__-IPSPRGOFFSET
;	.dbyt __HUNK1_SIZE__
.macro ips_hunkhdr name
	.import .ident(.concat("__", name, "_LOAD__"))
	.import .ident(.concat("__", name, "_SIZE__"))
	.byte 0
	.dbyt .ident(.concat("__", name, "_LOAD__"))-IPSPRGOFFSET
	.dbyt .ident(.concat("__", name, "_SIZE__"))
.endmacro
