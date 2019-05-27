# TAUS, et al

The main project is the Actually Useful Statistics Tetris mod. However, the
repository also contains disassembly knowledge for tetris, a structure for
building NES ips/nes files, and a LUA-based unit/integration test helpers.

## Set up

Dependencies (should be in PATH):
1. [Flips](https://github.com/Alcaro/Flips). [Flips
   1.31](https://www.smwcentral.net/?p=section&a=details&id=11474) is fine
2. [cc65](https://www.cc65.org/)
3. Only Linux has been used to date. Mac OS would probably mostly work. Windows
   with GNU make and UnxUtils may mostly work as well.

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
   matches the original. The mod will be generated at `build/taus.ips` and will
   have been applied to `build/taus.nes`.

## Structure

tetris-PRG.info is the location for all tetris ROM knowledge. It is used to
disassemble tetris into build/tetris-PRG.s. tetris.s and tetris.nes.info
contain the pieces to reassemble tetris into a iNES file. Reassembly is able to
output debug information.

The main debug output is the .lbl file. It is basic and just contains the
labels with their addresses, so doesn't have any more information than
tetris-PRG.info. However, it is easy to parse so the file format is used for
several other tasks; it is transformed into build/tetris.inc using sed and can
be read directly by the LUA testing tools.

NES and IPS files are output directly by the linker, because our .s files
define the headers for the formats and the .cfg files specify the ordering of
the headers/chunks. The linker is fairly well suited to the job and provides
the ability to mix-and-match source files when generating an IPS file, only
needing to manually sort the hunks. It is useful to have understanding of the
IPS format and how it works. It is basically the simplest possible patch
format, only supporting 1:1 replacing, so should be easy to learn.

The [Nesdev Wiki](https://wiki.nesdev.com/w/index.php/NES_reference_guide) has
good resources for the various file formats. The .info file format is described
in the [da65 (disassembler)
documentation](https://www.cc65.org/doc/da65-4.html). The .cfg file format is
described in the [ld65 (linker)
documentation](https://www.cc65.org/doc/ld65-5.html).

## Creating new NES/IPS files

To create a new NES file output (IPS/NES file), simply create a new .cfg file,
mirroring one of the existing ones (depending on what you are making), and any
.s files for the source. Then modify the Makefile to list the object files you
want to include within your IPS/NES file. These will be in the form
build/ORIGNAME.o corresponding to each ORIGINAL.s file. If your .cfg file was
named `myfile.ext.cfg`, then run `$ make build/myfile.ext` to build the output.
The extension used does not matter to the Makefile nor linker.
