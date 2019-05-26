all: tetris taus screens custom

# Manually list prerequisites that are generated. Non-generated files will
# automatically be computed.
build/taus.o: build/tetris.inc
build/screens.o: build/tetris.inc
# List linker dependencies
build/tetris.nes: build/tetris.o build/tetris-PRG.o
build/taus.ips: build/taus.o build/ips.o build/fastlegal.o
build/screens.ips: build/screens.o build/ips.o
build/highscores.ips: build/highscores.o build/ips.o
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
	flips --apply $< build/tetris.nes $@ > /dev/null
	flips --create build/tetris.nes $@ build/$*.dist.ips > /dev/null

build/tetris-PRG.s: tetris-PRG.info tetris-PRG.bin Makefile | build
	da65 -i tetris-PRG.info -o $@ tetris-PRG.bin

build/tetris.inc: build/tetris.nes
	sed -E -e 's/al 00(.{4}) .(.*)/\2 := $$\1/' build/tetris.nes.lbl > build/tetris.inc

build/custom.nes: build/tetris.nes
	cp $< $@.tmp
	for ips in $(filter %.ips,$^); do \
		flips --apply $$ips $@.tmp > /dev/null; \
	done
	mv $@.tmp $@
	flips --create $< $@ build/custom.dist.ips > /dev/null

test: tetris.nes build/tetris.nes
	diff tetris.nes build/tetris.nes

clean:
	[ ! -d build/ ] || rm -r build/

dis: build/tetris-PRG.s
tetris: build/tetris.nes
taus: build/taus.nes
screens: build/screens.nes
custom: build/custom.nes

# These are simply aliases
.PHONY: all dis tetris taus screens custom
# These are "true" phonies, and always execute something
.PHONY: test clean

.SUFFIXES:

ifneq "$(V)" "1"
.SILENT:
endif

include $(wildcard build/*.d)
