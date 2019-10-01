BEGIN {
	FS=" *([;{}]+|#.*)+ *"
	OFS="\t"
	NEXT=0
	print ".zeropage"
}

! (/^LABEL/ && $2 ~ /^ADDR / && $3 ~ /^NAME /) { next }

NF > 4 { NF=4 }

{
	SIZE=1
	sizenum=SIZE
}

$4 ~ /^SIZE / {
	split($4, a, " ");
	SIZE=a[2]
	sizenum=SIZE
	sub(/\$/, "0x", sizenum)
	sizenum=strtonum(sizenum)
}

{
	split($2, a, " ")
	addrnum=a[2]
	sub(/\$/, "0x", addrnum)
	addrnum=strtonum(addrnum)

	if (addrnum >= 0x800) exit
	if (addrnum > NEXT) print ".res " (addrnum-NEXT)
	if (addrnum < NEXT) {
		print $3 " out of order" > "/dev/stderr"
		next
	}
	NEXT=addrnum+sizenum
	split($3, b, "[ \"]+")
	print b[2] ":", ".res " SIZE, "; " a[2]
	if (addrnum < 0x100 && NEXT >= 0x100) print "\n.bss";
}
