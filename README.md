## Set up

Dependencies (should be in PATH):
1. [Flips](https://github.com/Alcaro/Flips). [Flips
   1.31](https://www.smwcentral.net/?p=section&a=details&id=11474) is fine
2. [cc65](https://www.cc65.org/)

Manual prep:
1. Copy tetris ROM to `tetris.nes`. I used a USA ROM with CRC32 6d72c53a,
   MD5 `ec58574d96bee8c8927884ae6e7a2508`, and
   SHA1 `77747840541bfc62a28a5957692a98c550bd6b2b`. Ignoring the 16 byte iNES
   header (`tail +17 tetris.nes > no-header.nes`), it has CRC32 1394f57e,
   MD5 5b0e571558c8c796937b96af469561c6, and
   SHA1 fd9079cb5e8479eb06d93c2ae5175bfce871746a. Other roms are fine, but you
   may need to adjust the iNES header in tetris.s. Ignore that for now. `$ make
   test` will fail if this is a problem.
2. Use [taetae54321/ines](https://github.com/taotao54321/ines) to split the
   file: `$ ines.py split tetris.nes`
3. Use `$ make` to build artifacts into `build/`, which includes disassembling
   into `build/tetris-PRG.s`. `$ make test` verifies the reassembled version
   matches the original. The mod will be generated at `build/tetris-mod.ips`
   and will have been applied to `build/tetris-mod.nes`.
