AS=arm-angstrom-linux-gnueabi-as
LD=arm-angstrom-linux-gnueabi-ld

BIN=uforth
SRCS=$(filter-out init_sym.s, $(wildcard *.s)) init_sym.s
OBJS=$(patsubst %.s,%.o,$(SRCS))
INCLUDES=$(wildcard *.asi)
TESTS=$(wildcard t/TC-*)

all: $(BIN) check

init_sym.s: gen_symboltable.pl ops.s
	./gen_symboltable.pl > $@

$(BIN): $(OBJS) $(INCLUDES)
	$(LD) $(OBJS) -o uforth

clean:
	rm -f $(BIN) $(OBJS) init_sym.s

check: $(BIN) $(TESTS)
	@for TC in $(TESTS); do \
		echo " === Running tests:" `basename $${TC}` " === " ; \
		./t/run-tests.pl $${TC} ; \
	done ;

.PHONY: clean
