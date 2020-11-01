.ifndef __TWOPLAYERSIMPORT
.importzp personal_rng
.importzp spawnID_
.importzp spawnCount_

.import	copyRleNametableToPpu
.import	legal_screen_nametable_rle
.endif

.macro jsr_i label
	.import label
	jsr	label
.endmacro

.macro jmp_i label
	.import label
	jmp	label
.endmacro

.macro jmp_ie label
	.import label
	jmp	label
	.export .ident(.concat("after_", .string(label))) := *
.endmacro

.macro addr_i label
	.import	label
	.addr	label
.endmacro

.macro nop_rep num
	.repeat num
	nop
	.endrepeat
.endmacro

.ifdef TOURNAMENT_MODE

; Enable NEXT_ON_TOP. -DNEXT_ON_TOP is the same as -DNEXT_ON_TOP=0
NEXT_ON_TOP = 0

.include "tournament.screenlayout.inc"

.elseif .not(.def(NEXT_ON_TOP))

INGAME_LAYOUT_P1_SCORE := $2066
INGAME_LAYOUT_P2_SCORE := $2078

INGAME_LAYOUT_P1_LEVEL := $20EF
INGAME_LAYOUT_P1_LINES := $21CF
INGAME_LAYOUT_P2_LEVEL := $2250
INGAME_LAYOUT_P2_LINES := $2330

INGAME_LAYOUT_P1_PREVIEW_X = $78
INGAME_LAYOUT_P1_PREVIEW_Y = $53
INGAME_LAYOUT_P2_PREVIEW_X = $80
INGAME_LAYOUT_P2_PREVIEW_Y = $AB

.else

INGAME_LAYOUT_P1_SCORE := $2366
INGAME_LAYOUT_P2_SCORE := $2378

INGAME_LAYOUT_P1_LEVEL := $210F
INGAME_LAYOUT_P1_LINES := $216F
INGAME_LAYOUT_P2_LEVEL := $21F0
INGAME_LAYOUT_P2_LINES := $2250

INGAME_LAYOUT_P1_PREVIEW_X = 6*8
INGAME_LAYOUT_P1_PREVIEW_Y = 3*8
INGAME_LAYOUT_P2_PREVIEW_X = 24*8
INGAME_LAYOUT_P2_PREVIEW_Y = 3*8

.endif
