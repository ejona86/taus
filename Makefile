all: tetris taus screens custom handicap save-highscores twoplayer twoplayer-garbage playerid build/game_palette.pal build/menu_palette.pal build/game_nametable.nam build/level_menu_nametable.nam
test: build/tetris-test build/taus-test.test build/chart-test.test build/twoplayer-test.test
# These are simply aliases
.PHONY: all dis tetris taus screens custom handicap save-highscores twoplayer twoplayer-garbage playerid

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

save-highscores: build/save-highscores.nes
build/save-highscores.o: build/tetris.inc
build/save-highscores.ips.cfg: build/save-highscores.o
build/save-highscores.ips: build/save-highscores.o build/ips.o
build/save-highscores.nes: build/tetris.nes

build/fastlegal.o: build/tetris.inc
build/fastlegal.ips.cfg: build/fastlegal.o
build/fastlegal.ips: build/fastlegal.o build/ips.o
build/fastlegal.nes: build/tetris.nes

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

taus: build/taus.nes build/taus-CHR-01.chr
build/chart.o: build/tetris.inc build/taus.chrs/fake
build/taus.o: build/tetris.inc build/taus.chrs/fake build/taus_game.nam.stripe
build/taus.ips: build/taus.o build/ips.o build/fastlegal.o build/chart.o
build/taus.tmp.ips.cfg: build/taus.o build/ips.o build/fastlegal.o build/chart.o
build/taus.ips.cfg: build/taus.tmp.ips.cfg taus.ips.cfg.snip
	cat $^ > $@
build/taus.nes: build/tetris.nes
build/chart-test.test: chart-test.lua build/taus.nes
build/taus-test.test: taus-test.lua build/taus.nes
build/taus-CHR-01.chr: build/taus.nes
	tail -c +40977 $< | head -c 8192 > $@

tetris: build/tetris.nes
build/tetris-CHR.o: build/tetris-CHR-00.chr build/tetris-CHR-01.chr
build/tetris.nes: build/tetris.o build/tetris-CHR.o build/tetris-PRG.o build/tetris-ram.o
ifeq "$(PAL)" "1"
build/tetris-test: tetris-pal.nes
else
build/tetris-test: tetris.nes
endif
build/tetris-test: build/tetris.nes
	diff $^
	touch $@

twoplayer: build/twoplayer.dist.ips
build/twoplayer-CHR-01.chr.ips.o: build/twoplayer.chrs/fake
build/twoplayer.o: build/tetris.inc build/twoplayer_game.nam.rle build/twoplayer_game_top.nam.rle build/tournament.nam.rle build/tetris-CHR-00.chr build/twoplayer-CHR-01.chr build/legal_screen_nametable.nam.rle
# Diff base file. There is a corresponding .diff file
build/twoplayer-tetris-PRG.s: build/tetris-PRG.s
build/twoplayer-CHR-01.chr.ips: build/ips.o build/twoplayer-CHR-01.chr.ips.o
build/twoplayer-CHR-01.chr: build/tetris-CHR-01.chr
ifeq "$(PAL)" "1"
build/twoplayer.nes: build/twoplayer-pal.nes.cfg
else
build/twoplayer.nes: twoplayer.nes.cfg
endif
build/twoplayer.nes: build/tetris.o build/twoplayer-tetris-PRG.o build/tetris-ram.o build/twoplayer.o build/rle.o build/fastlegal.ips
	ld65 $(LDFLAGS) -Ln $(basename $@).lbl --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg,$^) $(filter %.o,$^)
	# If the first time fails, run it a second time to display output
	flips --apply build/fastlegal.ips $@ > /dev/null || flips --apply build/fastlegal.ips $@ || (rm $@; false)
build/twoplayer.dist.ips: build/tetris.nes build/twoplayer.nes
	flips --create $^ $@ > /dev/null
build/twoplayer-test.test: twoplayer-test.lua build/twoplayer.nes
build/twoplayer-pal.nes.cfg: twoplayer.nes.cfg ntsc2pal.awk | build
	awk -f ntsc2pal.awk $< > $@

twoplayer-garbage: build/twoplayer-garbage.nes
build/twoplayer-garbage.o: build/tetris.inc
build/twoplayer-garbage.ips.cfg: build/twoplayer-garbage.o
build/twoplayer-garbage.ips: build/twoplayer-garbage.o build/ips.o
build/twoplayer-garbage.nes: build/twoplayer.nes

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
build/tetris-pal.nes.cfg: tetris.nes.cfg ntsc2pal.awk | build
	awk -f ntsc2pal.awk $< > $@
build/tetris-pal.nes: build/tetris.o build/tetris-CHR.o build/tetris-pal-PRG.o build/tetris-ram.o
build/tetris-pal-PRG.o: build/tetris-pal-PRG.s

ifeq "$(PAL)" "1"
build/tetris-PRG.s: build/tetris-pal-PRG.s
	cp $< $@
build/tetris.nes: build/tetris-pal.nes
	cp $< $@
	cp $(basename $<).dbg $(basename $@).dbg
	cp $(basename $<).lbl $(basename $@).lbl
endif

build/game_palette.pal: build/tetris-PRG.bin
	# +3 for buildCopyToPpu header
	tail -c +$$((0xACF3 - 0x8000 + 3 + 1)) $< | head -c 16 > $@
build/menu_palette.pal: build/tetris-PRG.bin
	# +3 for buildCopyToPpu header
	tail -c +$$((0xAD2B - 0x8000 + 3 + 1)) $< | head -c 16 > $@
build/legal_screen_nametable.nam:
build/legal_screen_nametable.nam.stripe: build/tetris-PRG.bin
	tail -c +$$((0xADB8 - 0x8000 + 1)) $< | head -c $$((1024/32*35)) > $@
build/game_nametable.nam.stripe: build/tetris-PRG.bin
	tail -c +$$((0xBF3C - 0x8000 + 1)) $< | head -c $$((1024/32*35)) > $@
build/level_menu_nametable.nam.stripe: build/tetris-PRG.bin
	tail -c +$$((0xBADB - 0x8000 + 1)) $< | head -c $$((1024/32*35)) > $@

# Converts to/from NES Stripe RLE. Only supports a _very_ limited subset that
# is fully consecutive, only "literal to right", with each sized 0x20
build/%: %.stripe
	LC_ALL=C awk -v BINMODE=3 'BEGIN {RS=".{35}";ORS=""} {print substr(RT, 4)}' $< > $@
build/%.nam.stripe: %.nam
	LC_ALL=C awk -v BINMODE=3 'BEGIN {RS=".{32}";ADDR=0x2000} {printf("%c%c%c%s",ADDR/256,ADDR%256,32,RT);ADDR=ADDR+32}' $< > $@

build/tetris.inc: build/tetris.nes
	sort build/tetris.lbl | sed -E -e 's/al 00(.{4}) .(.*)/\2 := $$\1/' | uniq > $@

build/tetris-ram.s: tetris-PRG.info tetris-ram.awk | build
	awk -f tetris-ram.awk $< > $@

ifeq "$(PAL)" "1"
FCEUXFLAGS = --pal 1
else
FCEUXFLAGS = --pal 0
endif
build/%.test: %.lua
	# Second prerequisite is assumed to be a .nes to run
	fceux --no-config 1 --fullscreen 0 --sound 0 --frameskip 100 $(FCEUXFLAGS) --loadlua $< $(word 2,$^)
	touch $@

.PHONY: test
test:
	# fceux saves some of the configuration, so restore what we can
	fceux --no-config 1 --sound 1 --frameskip 0 --loadlua testing-reset.lua build/tetris.nes

# include last because it enables SECONDEXPANSION
include nes.mk
