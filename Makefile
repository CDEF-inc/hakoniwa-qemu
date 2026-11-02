# Builds the plant asset and the RX guest. Run scripts/build-hakoniwa.sh
# first; see README.md.
BUILD ?= build
HAKO_PREFIX ?= $(BUILD)/install
RX_GCC ?= rx-elf-gcc

all: $(BUILD)/plant $(BUILD)/rx-baremetal.elf

$(BUILD)/plant: assets/plant/plant.c
	@mkdir -p $(BUILD)
	cc -O2 -Wall -o $@ $< -I$(HAKO_PREFIX)/include/hakoniwa \
	   -L$(HAKO_PREFIX)/lib -Wl,-rpath,$(abspath $(HAKO_PREFIX))/lib \
	   -lassets -lconductor

$(BUILD)/rx-baremetal.elf: guests/rx-baremetal/start.S guests/rx-baremetal/guest.c
	@mkdir -p $(BUILD)
	$(RX_GCC) -O2 -nostdlib -ffreestanding -Wl,-e,_start -Wl,-Ttext=0x1000 \
	   -o $@ $^

clean:
	rm -f $(BUILD)/plant $(BUILD)/rx-baremetal.elf

.PHONY: all clean
