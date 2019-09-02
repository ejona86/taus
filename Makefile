all: tetris taus screens custom handicap

# Manually list prerequisites that are generated. Non-generated files will
# automatically be computed.
build/taus.o: build/tetris.inc build/taus.chrs/fake
build/screens.o: build/tetris.inc
build/chart.o: build/tetris.inc build/taus.chrs/fake
build/tetris.o: build/tetris-CHR-00.chr build/tetris-CHR-01.chr
# List linker dependencies
build/tetris.nes: build/tetris.o build/tetris-PRG.o
build/taus.ips: build/taus.o build/ips.o build/fastlegal.o build/playerid.o build/chart.o
build/screens.ips: build/screens.o build/ips.o
build/highscores.ips: build/highscores.o build/ips.o
build/handicap.ips: build/handicap.o build/ips.o
# Combine mods
build/custom.nes: build/taus.ips build/highscores.ips

CAFLAGS = -g
LDFLAGS =
VPATH = build

build:
	mkdir build

build/%.o: %.s Makefile | build
	ca65 $(CAFLAGS) --create-dep $@.d $< -o $@

build/%: %.cfg
	ld65 $(LDFLAGS) -Ln $@.lbl --dbgfile $@.dbg -o $@ -C $< $(filter %.o,$^)

build/%.nes: build/%.ips build/tetris.nes
	cp $<.lbl build/$*.lbl
	cp $<.dbg build/$*.dbg
	# If the first time fails, run it a second time to display output
	flips --apply $< build/tetris.nes $@ > /dev/null || flips --apply $< build/tetris.nes $@
	flips --create build/tetris.nes $@ build/$*.dist.ips > /dev/null

build/%.chrs/fake: %.chr | build
	[ -d build/$*.chrs ] || mkdir build/$*.chrs
	touch $@
	split -x -b 16 $< build/$*.chrs/

# There are tools to split apart the iNES file, like
# https://github.com/taotao54321/ines, but they would require an additional
# setup step for the user to download/run.
build/tetris-PRG.bin: tetris.nes | build
	tail -c +17 $< | head -c 32768 > $@
build/tetris-CHR-00.chr: tetris.nes | build
	tail -c +32785 $< | head -c 8192 > $@
build/tetris-CHR-01.chr: tetris.nes | build
	tail -c +40977 $< | head -c 8192 > $@

build/tetris-PRG.s: tetris-PRG.info build/tetris-PRG.bin Makefile | build
	da65 -i tetris-PRG.info -o $@ build/tetris-PRG.bin

build/tetris.inc: build/tetris.nes
	sort build/tetris.nes.lbl | sed -E -e 's/al 00(.{4}) .(.*)/\2 := $$\1/' > build/tetris.inc

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

# These are simply aliases
.PHONY: all dis tetris taus screens custom handicap
# These are "true" phonies, and always execute something
.PHONY: test clean

.SUFFIXES:

ifneq "$(V)" "1"
.SILENT:
endif

include $(wildcard build/*.d)
