# Encode input using Konami RLE compression
#
# Intended to be run with LC_ALL=C and 'basenc --base16 -w2' as input and
# 'basenc --base16 -d' on output

# input is pairs of hex digits each followed by newline
# output is chunks of hex digits, with newlines between each chunk

BEGIN {
	runlen=0
}

runlen != 0 && lastbyte == $0 {
	runlen=runlen+1
	if (runlen == 128) {
		printf("%02X", runlen)
		print lastbyte
		runlen=0
	}
	next
}

runlen != 0 && lastbyte != $0 {
	printf("%02X", runlen)
	print lastbyte
	runlen=0
}

{
	literal=""
	secondlastbyte=$0
	if (!getline) {
		print "01" secondlastbyte
		exit
	}
	if (secondlastbyte == $0) {
		lastbyte=$0
		runlen=2
		next
	}
	lastbyte=$0
	while (getline) {
		if (secondlastbyte == lastbyte && lastbyte == $0) {
			printf("%02X", length(literal)/2+128)
			print literal
			runlen=3
			next
		}
		literal=literal secondlastbyte
		if (length(literal)/2+2 == 126) {
			printf("%02X", length(literal)/2+2+128)
			print literal lastbyte $0
			next
		}
		secondlastbyte=lastbyte
		lastbyte=$0
	}
	printf("%02X", length(literal)/2+2+128)
	print literal secondlastbyte lastbyte
}

END {
	if (runlen != 0) {
		printf("%02X", runlen)
		print lastbyte
	}
	print "FF"
}
