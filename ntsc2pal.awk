function ntsc2pal(addr) {
	# The addresses in these conditions are PAL addresses
	if (addr < 0x9DB3) return addr
	addr+=6
	if (addr < 0xA3FC) return addr
	addr+=6
	if (addr < 0xA46F) return addr
	addr+=19
	if (addr < 0xA577) return addr
	addr-=1
	if (addr < 0xA5D3) return addr
	addr-=1
	if (addr < 0xA602) return addr
	addr-=1
	if (addr < 0xA619) return addr
	addr-=1
	if (addr < 0xA630) return addr
	addr-=1
	if (addr <= 0xD6E3) return addr
	addr-=26 # back in sync
	if (addr <= 0xEBAF) return addr
	addr-=44
	if (addr <= 0xEC6F) return addr
	addr+=2
	if (addr <= 0xEC87) return addr
	addr+=2
	if (addr <= 0xEC9F) return addr
	addr+=2
	if (addr <= 0xECB7) return addr
	addr+=2
	if (addr <= 0xF0EF) return addr
	addr+=35
	if (addr <= 0xF3BB) return addr
	addr+=3
	if (addr <= 0xF45A) return addr
	addr+=9
	if (addr <= 0xF53B) return addr
	addr+=3
	if (addr <= 0xF841) return addr
	addr-=4
	if (addr < 0xFF00) return addr
	addr-=10 # back in sync
	return addr
}

/NAME "(MMC1_Control|MMC1_CHR0|MMC1_CHR1|DMC_START)"/ {
	print
	next
}

/ADDR \$A42B/ {
	sub("@ret", "playState_bTypeGoalCheck_ret")
}

{
	while (match($0, /\$[0-9A-Fa-f]{4}/)) {
		printf("%s", substr($0, 1, RSTART-1))
		addr=substr($0, RSTART, RLENGTH)
		sub(/\$/, "0x", addr)
		printf("$%04X", ntsc2pal(strtonum(addr)))
		$0=substr($0, RSTART+RLENGTH)
	}
	print
}
