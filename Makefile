build:
	@[ -d build/ ] || mkdir build/
	@ca65 tetris.s -o build/tetris.o
	@ld65 -o build/tetris.nes -C tetris.cfg build/tetris.o
	@cp build/tetris.nes build/tetris.mod.nes
	@flips build/mod.ips build/tetris.mod.nes > /dev/null

test: build
	@diff tetris.nes build/tetris.nes

dis:
	@da65 -i disasm.info -o tetris-PRG.s tetris-PRG.bin

clean:
	@[ ! -d build/ ] || rm -r build/

.PHONY: clean build dis
