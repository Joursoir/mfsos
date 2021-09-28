# If you want run this makefile immediately, then set environment
# variables (CC, LD, AS, OBJDUMP) to path of your cross-compiler.
#
# The best way to compile $BOOTBIN is to run the corresponding
# target in the main Makefile, which is in the root of the
# project (.../path/to/os/Makefile)

BOOTBIN = bootloader.bin

.PHONY: all objdump clean

all: $(BOOTBIN)

$(BOOTBIN): bootsect.bin setup.bin
	cat $^ > $@

bootsect.bin: bootsect.o
	$(CC) -Wl,--oformat binary -Ttext 0x7c00 -o $@ \
		-ffreestanding -nostdlib \
		$^ -lgcc

setup.bin: setup.o
	$(CC) -Wl,--oformat binary -Ttext 0x0200 -o $@ \
		-ffreestanding -nostdlib \
		$^ -lgcc

%.o: %.s
	$(AS) $< -o $@

objdump-bootsect:
	$(OBJDUMP) -D -m i386 -b binary \
		--adjust-vma=0x7c00 -Maddr16,data16 bootsect.bin

objdump-setup:
	$(OBJDUMP) -D -m i386 -b binary \
		--adjust-vma=0x2000 -Maddr16,data16 setup.bin

clean:
	rm -rf bootsect.o setup.o $(BOOTBIN)
