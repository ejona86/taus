all: tetris taus screens

# Manually list prerequisites that are generated. Non-generated files will
# automatically be computed.
build/taus.o: build/tetris.inc
build/screens.o: build/tetris.inc
# List linker dependencies
build/tetris.nes: build/tetris.o tetris-PRG.o
build/taus.ips: build/taus.o build/ips.o build/fastlegal.o build/highscores.o
build/screens.ips: build/screens.o build/ips.o

CAFLAGS =
LDFLAGS =
VPATH = build

build:
	mkdir build

build/%.o: %.s Makefile | build
	ca65 $(CAFLAGS) --create-dep $@.d $< -o $@

build/%: %.cfg
	ld65 $(LDFLAGS) -o $@ -C $< $(filter %.o,$^)

build/%.nes: build/%.ips build/tetris.nes
	cp build/tetris.nes $@
	flips $< $@ > /dev/null
	flips build/tetris.nes $@ build/$*.dist.ips > /dev/null

build/tetris-PRG.s: tetris-PRG.info tetris-PRG.bin Makefile | build
	da65 -i tetris-PRG.info -o $@ tetris-PRG.bin

build/tetris-PRG.o: CAFLAGS = -g
build/tetris.nes: LDFLAGS = -Ln build/tetris.lbl
build/tetris.inc: build/tetris.nes
	sed -E -e 's/al 00(.{4}) .(.*)/\2 := $$\1/' build/tetris.lbl > build/tetris.inc

test: tetris.nes build/tetris.nes
	diff tetris.nes build/tetris.nes

clean:
	[ ! -d build/ ] || rm -r build/

dis: build/tetris-PRG.s
tetris: build/tetris.nes
taus: build/taus.nes
screens: build/screens.nes

# These are simply aliases
.PHONY: all dis tetris taus screens
# These are "true" phonies, and always execute something
.PHONY: test clean

.SUFFIXES:

ifneq "$(V)" "1"
.SILENT:
endif

include $(wildcard build/*.d)
