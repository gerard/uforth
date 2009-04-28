AS=arm-angstrom-linux-gnueabi-as
LD=arm-angstrom-linux-gnueabi-ld

BIN=uforth
SRCS=$(filter-out init_sym.s, $(wildcard *.s)) init_sym.s
OBJS=$(patsubst %.s,%.o,$(SRCS))
INCLUDES=$(wildcard *.asi)

all: $(BIN) check

init_sym.s: gen_symboltable.pl ops.s
	./gen_symboltable.pl > $@

$(BIN): $(OBJS) $(INCLUDES)
	$(LD) $(OBJS) -o uforth

clean:
	rm -f $(BIN) $(OBJS) init_sym.s

check: $(BIN)
	@for T in ./t/*.pl; do \
		printf "%s\t" $${T} && $${T} ; \
	done ;

.PHONY: clean
