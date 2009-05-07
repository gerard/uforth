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

ifdef CTAGS
all: $(BIN) tags check
else
all: $(BIN) check
endif

init_sym.s: gen_symboltable.pl $(SRCS_OPS) compile.s
	./gen_symboltable.pl > $@

$(BIN): $(OBJS) $(INCLUDES)
	$(LD) $(OBJS) -o uforth

clean:
	rm -f $(BIN) $(OBJS) init_sym.s tags

check: $(BIN) $(TESTS)
	@for TC in $(TESTS); do \
		echo " === Running tests:" `basename $${TC}` " === " ; \
		./t/run-tests.pl $${TC} ; \
	done ;

tags:
	$(CTAGS) -R .

.PHONY: clean
