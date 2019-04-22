build:
	@[ -d build/ ] || mkdir build/
	@ca65 tetris.s -o build/tetris.o
	@ld65 -o build/tetris.nes -C tetris.cfg build/tetris.o

test: build
	@diff tetris.nes build/tetris.nes

dis:
	@da65 -i disasm.info -o tetris-PRG.s tetris-PRG.bin

clean:
	@[ ! -d build/ ] || rm -r build/

.PHONY: clean build dis
