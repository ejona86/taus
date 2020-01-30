all: tetris taus screens custom handicap twoplayer build/game_palette.pal build/menu_palette.pal build/game_nametable.nam build/level_menu_nametable.nam

# Manually list prerequisites that are generated. Non-generated files will
# automatically be computed.
build/taus.o: build/tetris.inc build/taus.chrs/fake
build/playerid.o: build/tetris.inc
build/handicap.o: build/tetris.inc
build/screens.o: build/tetris.inc
build/chart.o: build/tetris.inc build/taus.chrs/fake
build/tetris-CHR.o: build/tetris-CHR-00.chr build/tetris-CHR-01.chr
build/twoplayer.o: build/tetris.inc build/twoplayer_game.nam.rle build/twoplayer_game_top.nam.rle build/tournament.nam.rle build/tetris-CHR-00.chr build/twoplayer-CHR-01.chr
build/twoplayer-CHR-01.chr.ips.o: build/twoplayer.chrs/fake
# .diff base files. There should be a .diff for each target
build/twoplayer-tetris-PRG.s: build/tetris-PRG.s
# List linker dependencies. There should be a .cfg for each target
build/tetris.nes: build/tetris.o build/tetris-CHR.o build/tetris-PRG.o build/tetris-ram.o
build/taus.ips: build/taus.o build/ips.o build/fastlegal.o build/playerid.o build/chart.o
build/screens.ips: build/screens.o build/ips.o
build/highscores.ips: build/highscores.o build/ips.o
build/handicap.ips: build/handicap.o build/ips.o
build/twoplayer.nes: build/tetris.o build/twoplayer-tetris-PRG.o build/tetris-ram.o build/twoplayer.o build/rle.o
build/twoplayer-CHR-01.chr.ips: build/ips.o build/twoplayer-CHR-01.chr.ips.o
# IPS base dependencies. There should be a .ips for each target
build/taus.nes: build/tetris.nes
build/screens.nes: build/tetris.nes
build/highscores.nes: build/tetris.nes
build/handicap.nes: build/tetris.nes
build/twoplayer-CHR-01.chr: build/tetris-CHR-01.chr
# Combine mods
build/custom.nes: build/taus.ips build/highscores.ips

build/twoplayer.dist.ips: build/tetris.nes build/twoplayer.nes
	flips --create $^ $@ > /dev/null

CAFLAGS = "-g" "-DTOURNAMENT_MODE"
LDFLAGS =
VPATH = build

build:
	mkdir build

build/%.o: %.s Makefile | build
	ca65 $(CAFLAGS) --create-dep $@.d $< -o $@

build/%: %.cfg
	ld65 $(LDFLAGS) -Ln $(basename $@).lbl --dbgfile $(basename $@).dbg -o $@ -C $< $(filter %.o,$^)

build/%.nes: build/%.ips
	# Second prerequisite is assumed to be a .nes source
	# If the first time fails, run it a second time to display output
	flips --apply $< $(word 2,$^) $@ > /dev/null || flips --apply $< $(word 2,$^) $@
	flips --create $(word 2,$^) $@ build/$*.dist.ips > /dev/null

build/%: %.ips
	# Second prerequisite is assumed to be source
	# If the first time fails, run it a second time to display output
	flips --apply $< $(word 2,$^) $@ > /dev/null || flips --apply $< $(word 2,$^) $@
	flips --create $(word 2,$^) $@ build/$*.dist.ips > /dev/null

build/%.chrs/fake: %.chr | build
	[ -d build/$*.chrs ] || mkdir build/$*.chrs
	touch $@
	split -x -b 16 $< build/$*.chrs/
build/%.rle: % rle-enc.awk | build
	basenc --base16 -w2 $< | LC_ALL=C awk -f rle-enc.awk | basenc --base16 -d > $@

# There are tools to split apart the iNES file, like
# https://github.com/taotao54321/ines, but they would require an additional
# setup step for the user to download/run.
build/tetris-PRG.bin: tetris.nes | build
	tail -c +17 $< | head -c 32768 > $@
build/tetris-CHR-00.chr: tetris.nes | build
	tail -c +32785 $< | head -c 8192 > $@
build/tetris-CHR-01.chr: tetris.nes | build
	tail -c +40977 $< | head -c 8192 > $@

build/game_palette.pal: build/tetris-PRG.bin
	# +3 for buildCopyToPpu header
	tail -c +$$((16#ACF3 - 16#8000 + 3 + 1)) $< | head -c 16 > $@
build/menu_palette.pal: build/tetris-PRG.bin
	# +3 for buildCopyToPpu header
	tail -c +$$((16#AD2B - 16#8000 + 3 + 1)) $< | head -c 16 > $@
build/game_nametable.nam: build/tetris-PRG.bin
	tail -c +$$((16#BF3C - 16#8000 + 1)) $< | head -c $$((1024/32*35)) | LC_ALL=C awk 'BEGIN {RS=".{35}";ORS=""} {print substr(RT, 4)}' > $@
build/level_menu_nametable.nam: build/tetris-PRG.bin
	tail -c +$$((16#BADB - 16#8000 + 1)) $< | head -c $$((1024/32*35)) | LC_ALL=C awk 'BEGIN {RS=".{35}";ORS=""} {print substr(RT, 4)}' > $@

build/%.s: %.bin %.info Makefile | build
	da65 -i $(word 2,$^) -o $@ $<

build/tetris.inc: build/tetris.nes
	sort build/tetris.lbl | sed -E -e 's/al 00(.{4}) .(.*)/\2 := $$\1/' | uniq > $@

build/tetris-ram.s: tetris-PRG.info tetris-ram.awk | build
	awk -f tetris-ram.awk $< > $@

build/custom.nes: build/tetris.nes
	cp $< $@.tmp
	for ips in $(filter %.ips,$^); do \
		flips --apply $$ips $@.tmp > /dev/null; \
	done
	mv $@.tmp $@
	flips --create $< $@ build/custom.dist.ips > /dev/null

test: tetris.nes build/tetris.nes build/taus.nes
	diff tetris.nes build/tetris.nes
	fceux --no-config 1 --fullscreen 0 --sound 0 --frameskip 100 --loadlua taus-test.lua build/taus.nes
	fceux --no-config 1 --fullscreen 0 --sound 0 --frameskip 100 --loadlua chart-test.lua build/taus.nes
	# fceux saves some of the configuration, so restore what we can
	fceux --no-config 1 --sound 1 --frameskip 0 --loadlua testing-reset.lua build/taus.nes

clean:
	[ ! -d build/ ] || rm -r build/

dis: build/tetris-PRG.s
tetris: build/tetris.nes
taus: build/taus.nes
screens: build/screens.nes
custom: build/custom.nes
handicap: build/handicap.nes
twoplayer: build/twoplayer.nes build/twoplayer.dist.ips

# These are simply aliases
.PHONY: all dis tetris taus screens custom handicap twoplayer
# These are "true" phonies, and always execute something
.PHONY: test clean

.SUFFIXES:

ifneq "$(V)" "1"
.SILENT:
endif

include $(wildcard build/*.d)

.SECONDEXPANSION:
build/%: %.diff $$(wildcard build/diffhead-$$*)
	# Last prerequisite is assumed to be basefile
	###
	# Sync diffhead and diff for manual edits
	if [ build/diffhead-$* -nt $@ ]; then \
		diff -u --label orig --label mod -U 5 -F : build/diffbase-$* build/diffhead-$* > $@.tmp \
			|| [ $$? -eq 1 ] && mv $@.tmp $<; \
	elif [ $< -nt $@ -a -e build/diffbase-$* ]; then \
		cp build/diffbase-$* $@.tmp && patch -s $@.tmp $< && mv $@.tmp build/diffhead-$*; \
	fi
	# Now do build-triggered updates
	if [ ! -e build/diffbase-$* -o $(word $(words $^),$^) -nt build/diffbase-$* ]; then \
		cp $(word $(words $^),$^) $@.tmpbase && \
		cp $(word $(words $^),$^) $@.tmphead && patch -s $@.tmphead $< && \
		mv $@.tmpbase build/diffbase-$* && mv $@.tmphead build/diffhead-$*; \
	fi
	echo "; DO NOT MODIFY. Modify diffhead-$* instead" | cat - build/diffhead-$* > $@
