
VRL = iverilog
GTK = gtkwave
OUT = modules

# rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))
# SOURCES := $(call rwildcard,.,*.v)
SOURCES := $(wildcard *.v)
OUTPUTS := $(wildcard *.vcd)

default: compile

compile: $(OUT)

run:
	./$(OUT)

show:
	$(GTK) $(OUTPUTS) &
	@echo

test: $(OUT)
	./$(OUT)
	$(GTK) $(OUTPUTS) &
	@echo

$(OUT): $(SOURCES) Makefile
	$(VRL) -o $@ $(SOURCES)

clean:
	rm $(OUT)
	rm *.vcd
