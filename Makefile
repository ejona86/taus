all: tetris taus screens custom handicap twoplayer playerid build/game_palette.pal build/menu_palette.pal build/game_nametable.nam build/level_menu_nametable.nam
test: build/tetris-test build/taus-test.test build/chart-test.test build/twoplayer-test.test
# These are simply aliases
.PHONY: all dis tetris taus screens custom handicap twoplayer playerid

dis: build/tetris-PRG.s

handicap: build/handicap.nes
# For .o files, manually list prerequisites that are generated. Non-generated
# files will automatically be computed
build/handicap.o: build/tetris.inc
# Detect IPS hunks. These .o files used ips_segments in their .s
build/handicap.ips.cfg: build/handicap.o
# Linker dependencies. There is a corresponding .cfg file
build/handicap.ips: build/handicap.o build/ips.o
# IPS base file. There is a corresponding .ips file
build/handicap.nes: build/tetris.nes

build/highscores.o: build/tetris.inc
build/highscores.ips.cfg: build/highscores.o
build/highscores.ips: build/highscores.o build/ips.o
build/highscores.nes: build/tetris.nes

playerid: build/playerid.nes
build/playerid.o: build/tetris.inc
build/playerid.ips.cfg: build/playerid.o
build/playerid.ips: build/ips.o build/playerid.o
build/playerid.nes: build/tetris.nes

screens: build/screens.nes
build/screens.o: build/tetris.inc
build/screens.ips.cfg: build/screens.o
build/screens.ips: build/screens.o build/ips.o
build/screens.nes: build/tetris.nes

taus: build/taus.nes
build/chart.o: build/tetris.inc build/taus.chrs/fake
build/taus.o: build/tetris.inc build/taus.chrs/fake
build/taus.ips: build/taus.o build/ips.o build/fastlegal.o build/chart.o
build/taus.nes: build/tetris.nes
build/chart-test.test: chart-test.lua build/taus.nes
build/taus-test.test: taus-test.lua build/taus.nes

tetris: build/tetris.nes
build/tetris-CHR.o: build/tetris-CHR-00.chr build/tetris-CHR-01.chr
build/tetris.nes: build/tetris.o build/tetris-CHR.o build/tetris-PRG.o build/tetris-ram.o
build/tetris-test: tetris.nes build/tetris.nes
	diff tetris.nes build/tetris.nes
	touch $@

twoplayer: build/twoplayer.dist.ips
build/twoplayer-CHR-01.chr.ips.o: build/twoplayer.chrs/fake
build/twoplayer.o: build/tetris.inc build/twoplayer_game.nam.rle build/twoplayer_game_top.nam.rle build/tournament.nam.rle build/tetris-CHR-00.chr build/twoplayer-CHR-01.chr build/legal_screen_nametable.nam.rle
# Diff base file. There is a corresponding .diff file
build/twoplayer-tetris-PRG.s: build/tetris-PRG.s
build/twoplayer-CHR-01.chr.ips: build/ips.o build/twoplayer-CHR-01.chr.ips.o
build/twoplayer-CHR-01.chr: build/tetris-CHR-01.chr
build/twoplayer.nes: build/tetris.o build/twoplayer-tetris-PRG.o build/tetris-ram.o build/twoplayer.o build/rle.o
build/twoplayer.dist.ips: build/tetris.nes build/twoplayer.nes
	flips --create $^ $@ > /dev/null
build/twoplayer-test.test: twoplayer-test.lua build/twoplayer.nes

custom: build/custom.nes
build/custom.nes: build/taus.ips build/highscores.ips build/playerid.ips
build/custom.nes: build/tetris.nes
	cp $< $@.tmp
	for ips in $(filter %.ips,$^); do \
		flips --apply $$ips $@.tmp > /dev/null; \
	done
	mv $@.tmp $@
	flips --create $< $@ build/custom.dist.ips > /dev/null

# There are tools to split apart the iNES file, like
# https://github.com/taotao54321/ines, but they would require an additional
# setup step for the user to download/run.
build/tetris-PRG.bin: tetris.nes | build
	tail -c +17 $< | head -c 32768 > $@
build/tetris-pal-PRG.bin: tetris-pal.nes | build
	tail -c +17 $< | head -c 32768 > $@
build/tetris-CHR-00.chr: tetris.nes | build
	tail -c +32785 $< | head -c 8192 > $@
build/tetris-CHR-01.chr: tetris.nes | build
	tail -c +40977 $< | head -c 8192 > $@

build/tetris-pal-PRG.info: tetris-PRG.info ntsc2pal.awk | build
	awk -f ntsc2pal.awk $< > $@
build/tetris-pal-PRG.s: build/tetris-pal-PRG.bin build/tetris-pal-PRG.info Makefile | build
	# Strip off the first two lines of header, which contain variable
	# information; they cause merge conflicts
	da65 -i $(word 2,$^) $< | tail -n +3 > $@
	da65 -i $(word 2,$^) --comments 3 $< > $(basename $@).v2.s

build/game_palette.pal: build/tetris-PRG.bin
	# +3 for buildCopyToPpu header
	tail -c +$$((0xACF3 - 0x8000 + 3 + 1)) $< | head -c 16 > $@
build/menu_palette.pal: build/tetris-PRG.bin
	# +3 for buildCopyToPpu header
	tail -c +$$((0xAD2B - 0x8000 + 3 + 1)) $< | head -c 16 > $@
build/legal_screen_nametable.nam: build/tetris-PRG.bin
	tail -c +$$((0xADB8 - 0x8000 + 1)) $< | head -c $$((1024/32*35)) | LC_ALL=C awk 'BEGIN {RS=".{35}";ORS=""} {print substr(RT, 4)}' > $@
build/game_nametable.nam: build/tetris-PRG.bin
	tail -c +$$((0xBF3C - 0x8000 + 1)) $< | head -c $$((1024/32*35)) | LC_ALL=C awk 'BEGIN {RS=".{35}";ORS=""} {print substr(RT, 4)}' > $@
build/level_menu_nametable.nam: build/tetris-PRG.bin
	tail -c +$$((0xBADB - 0x8000 + 1)) $< | head -c $$((1024/32*35)) | LC_ALL=C awk 'BEGIN {RS=".{35}";ORS=""} {print substr(RT, 4)}' > $@

build/tetris.inc: build/tetris.nes
	sort build/tetris.lbl | sed -E -e 's/al 00(.{4}) .(.*)/\2 := $$\1/' | uniq > $@

build/tetris-ram.s: tetris-PRG.info tetris-ram.awk | build
	awk -f tetris-ram.awk $< > $@

build/%.test: %.lua
	# Second prerequisite is assumed to be a .nes to run
	fceux --no-config 1 --fullscreen 0 --sound 0 --frameskip 100 --loadlua $< $(word 2,$^)
	touch $@

.PHONY: test
test:
	# fceux saves some of the configuration, so restore what we can
	fceux --no-config 1 --sound 1 --frameskip 0 --loadlua testing-reset.lua build/taus.nes

# include last because it enables SECONDEXPANSION
include nes.mk
