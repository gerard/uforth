# Copyright (c) 2009, Gerard Lledo Vives <gerard.lledo@gmail.com>
# This program is open source.  For license terms, see the LICENSE file.

AS=arm-angstrom-linux-gnueabi-as
LD=arm-angstrom-linux-gnueabi-ld

BIN=uforth
SRCS=$(filter-out init_sym.s, $(wildcard *.s ops/*.s)) init_sym.s
SRCS_OPS=$(wildcard ops/*.s)
OBJS=$(patsubst %.s,%.o,$(SRCS))
INCLUDES=$(wildcard *.asi)
TESTS=$(wildcard t/TC-*)
CTAGS=$(shell which ctags)

BUILD=clean-ws $(BIN) check check-license
ifdef CTAGS
BUILD+=tags
endif

all: $(BUILD)

init_sym.s: gen_symboltable.pl $(SRCS_OPS) compile.s
	./gen_symboltable.pl > $@

$(BIN): $(OBJS) $(INCLUDES)
	$(LD) $(OBJS) -o uforth

clean-ws:
	@for FILE in `git-ls-files`; do \
		sed -i "s/[ \t]*$$//" $${FILE} ; \
	done ;

clean:
	rm -f $(BIN) $(OBJS) init_sym.s tags

check-license:
	@for FILE in `git-ls-files | sed 's/\.gitignore//'` ; do \
		grep -q Copyright $${FILE} || echo "W: $${FILE} misses copyright statement" ; \
	done ;

check: $(BIN) $(TESTS)
	@for TC in $(TESTS); do \
		echo " === Running tests:" `basename $${TC}` " === " ; \
		./t/run-tests.pl $${TC} ; \
	done ;

tags:
	$(CTAGS) -R .

.PHONY: clean clean-ws check check-license
