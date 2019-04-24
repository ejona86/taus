## Set up

1. Copy tetris ROM to `tetris.nes`
2. Use [taetae54321/ines](https://github.com/taotao54321/ines) to split the
   file: `$ ines.py split tetris.nes`
3. Use `$ make dis` to disassemble into `tetris-PRG.s` and `$ make test` to
   assemble and check that it matches the original. The mod will be generated at
   `build/mod.ips` and will have been applied to `build/tetris.mod.nes`.
