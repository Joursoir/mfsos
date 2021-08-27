# If you want run this makefile immediately, then set environment
# variables (CC, LD, AS, OBJDUMP) to path of your cross-compiler.
#
# The best way to compile bootsect.bin is to run the corresponding
# target in the main Makefile, which is in the root of the
# project (.../path/to/os/Makefile)

BOOTBIN = bootsect.bin

.PHONY: all objdump clean

all: $(BOOTBIN)

$(BOOTBIN): bootsect.o
	$(CC) -T linker.ld -o $(BOOTBIN) \
		-ffreestanding -nostdlib \
		$^ -lgcc

bootsect.o: bootsect.s
	$(AS) $< -o $@

objdump:
	$(OBJDUMP) -D -m i386 -b binary \
		--adjust-vma=0x7c00 -Maddr16,data16 $(BOOTBIN)

clean:
	rm -rf bootsect.o $(BOOTBIN)
