override CAFLAGS += -g
LDFLAGS =
VPATH = build

build:
	mkdir build

build/%.o: %.s Makefile | build
	ca65 $(CAFLAGS) --create-dep $@.d $< -o $@

build/%: %.cfg
	ld65 $(LDFLAGS) -Ln $(basename $@).lbl --dbgfile $(basename $@).dbg -o $@ -C $< $(filter %.o,$^)

build/%.ips.cfg: ips-segments.awk
	od65 --dump-options $(filter %.o,$^) | grep '"ips:' | sed -E 's/^ +Data: +"ips: (.*)"$$/\1/' | sort -n | awk -f ips-segments.awk > $@

build/%.nes: build/%.ips
	# Second prerequisite is assumed to be a .nes source
	# If the first time fails, run it a second time to display output
	flips --apply $< $(word 2,$^) $@ > /dev/null || flips --apply $< $(word 2,$^) $@
	flips --create $(word 2,$^) $@ build/$*.dist.ips > /dev/null

build/%: %.ips
	# Second prerequisite is assumed to be source
	# If the first time fails, run it a second time to display output
	flips --apply $< $(word 2,$^) $@ > /dev/null || flips --apply $< $(word 2,$^) $@
	flips --create $(word 2,$^) $@ build/$*.dist.ips > /dev/null

build/%.chrs/fake: %.chr | build
	[ -d build/$*.chrs ] || mkdir build/$*.chrs
	touch $@
	split -x -b 16 $< build/$*.chrs/
build/%.rle: % rle-enc.awk | build
	# 'basenc --base16 -w2' and 'basenc --base16 -d' would also work, but
	# basenc isn't as widely available as xxd since it was added in
	# coreutils 8.31
	xxd -c1 -p $< | LC_ALL=C awk -f rle-enc.awk | xxd -r -p > $@

build/%.s: %.bin %.info Makefile | build
	# Strip off the first two lines of header, which contain variable
	# information; they cause merge conflicts
	da65 -i $(word 2,$^) $< | tail -n +3 > $@
	da65 -i $(word 2,$^) --comments 2 $< > $(basename $@).v2.s

clean:
	[ ! -d build/ ] || rm -r build/

.PHONY: clean

.SUFFIXES:

ifneq "$(V)" "1"
.SILENT:
endif

include $(wildcard build/*.d)

.SECONDEXPANSION:
build/%: %.diff $$(wildcard build/diffhead-$$*)
	# Last prerequisite is assumed to be basefile
	###
	# Sync diffhead and diff for manual edits
	if [ build/diffhead-$* -nt $@ ]; then \
		diff -u --label orig --label mod -U 5 -F : build/diffbase-$* build/diffhead-$* > $@.tmp \
			|| [ $$? -eq 1 ] && mv $@.tmp $<; \
	elif [ $< -nt $@ -a -e build/diffbase-$* ]; then \
		cp build/diffbase-$* $@.tmp && patch -s $@.tmp $< && mv $@.tmp build/diffhead-$*; \
	fi
	# Now do build-triggered updates
	if [ ! -e build/diffbase-$* -o $(word $(words $^),$^) -nt build/diffbase-$* ]; then \
		cp $(word $(words $^),$^) $@.tmpbase && \
		cp $(word $(words $^),$^) $@.tmphead && patch -s $@.tmphead $< && \
		mv $@.tmpbase build/diffbase-$* && mv $@.tmphead build/diffhead-$*; \
	fi
	echo "; DO NOT MODIFY. Modify diffhead-$* instead" | cat - build/diffhead-$* > $@
