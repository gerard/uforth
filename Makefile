AS=arm-angstrom-linux-gnueabi-as
LD=arm-angstrom-linux-gnueabi-ld

BIN=uforth
SRCS=$(wildcard *.s) init_sym.s
OBJS=$(patsubst %.s,%.o,$(SRCS))

all: $(BIN)

init_sym.s: gen_symboltable.pl ops.s
	./gen_symboltable.pl > $@

$(BIN): $(OBJS)
	$(LD) $^ -o uforth

clean:
	rm -f $(BIN) $(OBJS) init_sym.s
