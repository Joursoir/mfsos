# If you want run this makefile immediately, then set environment
# variables (CC, LD, AS, OBJDUMP) to path of your cross-compiler.
#
# The best way to build multiboot header is to run the corresponding
# target in the main Makefile, which is in the root of the
# project (.../path/to/os/Makefile)

MULTIBOOT_HEADER = $(ARCH_INCLUDE)/multiboot.h
BARE_MULTIBOOT_HEADER = bare_multiboot.h

.PHONY: all clean

all: $(BARE_MULTIBOOT_HEADER)

$(BARE_MULTIBOOT_HEADER): $(MULTIBOOT_HEADER)
	$(CC) -E -dM -undef -fsyntax-only $(MULTIBOOT_HEADER) > $(BARE_MULTIBOOT_HEADER)
# Delete all defines that have double underscore
	sed -i '/__/d' $(BARE_MULTIBOOT_HEADER)
# Replace "#define" with ".set" on each line
	sed -i 's/#define/.set/g' $(BARE_MULTIBOOT_HEADER)
# Put a comma after the macro name
	sed -i 's/\>/,/2' $(BARE_MULTIBOOT_HEADER)

clean:
	rm $(BARE_MULTIBOOT_HEADER)
