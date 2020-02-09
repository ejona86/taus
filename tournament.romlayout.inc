TRATE_P1        = 0
TRATE_P2        = 1
BURN_P1         = 2
BURN_P2         = 3
DROUGHT_P1      = 4
DROUGHT_P2      = 5
SCORELEAD       = 6   ; 3-byte bcd number
LEADERID        = 9   ; id of leading player

;this should be stored in zeropage for a bit faster access
tournamentRenderFlags           = $07
tournamentRenderFlagsLeadArrow  = $01
tournamentRenderFlagsLead       = $02
tournamentRenderFlagsTetrisRate = $04
tournamentRenderFlagsBurn       = $08
tournamentRenderFlagsDrought    = $10
tournamentCalcFlagsTetrisRate   = $20
tournamentTmp4                  = $10
tournamentTmp5                  = $11
