BEGIN {
	print "MEMORY   {IPSHEADER: start = $0000, size = $0005;}"
	print "SEGMENTS {IPSHEADER: load = IPSHEADER;}"
	FS=" "
}

{
	printf "MEMORY   {%s_HDR: start = $0000, size = $0005;}\n", $2
	printf "MEMORY   {%s:     start = $%X, size = $0100;}\n", $2, $1
	printf "SEGMENTS {%s_HDR: load = %s_HDR;}\n", $2, $2
	printf "SEGMENTS {%s:     load = %s, define = yes;}\n", $2, $2
}

END {
	print "MEMORY   {IPSEOF: start = $0000, size = $0003;}"
	print "SEGMENTS {IPSEOF: load = IPSEOF;}"
}
