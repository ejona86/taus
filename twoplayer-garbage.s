;
; Mod that enables garbage for twoplayer mod
;

.include "ips.inc"
.include "build/tetris.inc"

.segment "ADD_GARBAGE"
        ips_segment     "ADD_GARBAGE",$9AE2

        ; The twoplayer mod disables garbage by throwing away the garbage here.
        ; This reverts the change.
        sta     pendingGarbageInactivePlayer
