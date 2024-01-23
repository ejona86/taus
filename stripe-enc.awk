# Encode input using Stripe RLE compression (Tetris variation)
#
# Intended to be run with LC_ALL=C and 'basenc --base16 -w2' as input and
# 'basenc --base16 -d' on output

# variable addr can be set to change the destination PPU address
# input is pairs of hex digits, each followed by newline
# output is chunks of hex digits, with newlines between each chunk

BEGIN {
	runlen=0
	if (addr == "") {
		addr=0x2000
	}
}

runlen != 0 && lastbyte == $0 {
	runlen++
	if (runlen == 0x40) {
		printf("%04X%02X%s\n", addr, 0x40, lastbyte)
		addr+=runlen
		runlen=0
	}
	next
}

runlen != 0 && lastbyte != $0 {
	printf("%04X%02X%s\n", addr, 0x40+runlen, lastbyte)
	addr+=runlen
	runlen=0
}

{
	literal=$0
	runlen=1
	lastbyte=$0
	while (getline) {
		literal=literal $0
		if (lastbyte != $0) {
			runlen=1
		} else {
			runlen++
			# Optimal is 4 if next stripe is a run, and 7 if
			# literal. Assume a literal typically follows a run.
			if ((runlen == 4 && runlen*2 == length(literal)) \
			     || runlen == 7) {
				literal=substr(literal, 1, length(literal)-runlen*2)
				if (literal == "") {
					next
				} else {
					break
				}
			}
		}
		if (length(literal)/2 == 0x40) {
			runlen=0
			break
		}
		lastbyte=$0
	}
	printf("%04X%02X%s\n", addr, (length(literal)/2)%0x40, literal)
	addr+=length(literal)/2
}

END {
	if (runlen != 0) {
		printf("%04X%02X%s\n", addr, 0x40+runlen, lastbyte)
		addr+=runlen
	}
	print "FF"
}
