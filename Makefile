AS=arm-angstrom-linux-gnueabi-as
LD=arm-angstrom-linux-gnueabi-ld

BIN=uforth
SRCS=$(wildcard *.s)
OBJS=$(patsubst %.s,%.o,$(SRCS))

all: $(BIN)

$(BIN): $(OBJS)
	$(LD) $^ -o uforth

clean:
	rm -f $(BIN) $(OBJS)
