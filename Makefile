all: tetris mod

build:
	mkdir build

build/tetris-PRG.s: disasm.info tetris-PRG.bin Makefile | build
	da65 -i disasm.info -o build/tetris-PRG.s tetris-PRG.bin

build/%.o: %.s Makefile | build
	ca65 $< -o $@

build/tetris.o: tetris-CHR-00.bin tetris-CHR-01.bin

build/tetris.nes: tetris.cfg build/tetris.o build/tetris-PRG.s
	ca65 -g build/tetris-PRG.s -o build/tetris-PRG.o
	ld65 -o build/tetris.nes -C tetris.cfg -Ln build/tetris.lbl build/tetris.o build/tetris-PRG.o
	sed -E -e 's/al 00(.{4}) .(.*)/\2 := $$\1/' build/tetris.lbl > build/tetris.inc

build/tetris-mod.o: build/tetris.nes

build/tetris-mod.nes: tetris-mod.cfg build/tetris-mod.o build/tetris.nes
	ld65 -o build/tetris-mod.ips -C tetris-mod.cfg build/tetris-mod.o
	cp build/tetris.nes build/tetris-mod.nes
	flips build/tetris-mod.ips build/tetris-mod.nes > /dev/null
	flips build/tetris.nes build/tetris-mod.nes build/tetris-mod.dist.ips > /dev/null

test: tetris.nes build/tetris.nes
	diff tetris.nes build/tetris.nes

clean:
	[ ! -d build/ ] || rm -r build/

dis: build/tetris-PRG.s
tetris: build/tetris.nes
mod: build/tetris-mod.nes

# These are simply aliases
.PHONY: all dis tetris mod
# These are "true" phonies, and always execute something
.PHONY: test clean

ifneq "$(V)" "1"
.SILENT:
endif
