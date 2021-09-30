OSNAME = mfsos
OSBIN = $(OSNAME).bin

ARCH = x86
ARCH_BOOT = arch/$(ARCH)/boot
BOOTBIN = $(ARCH_BOOT)/bootloader.bin

OBJECTS = kernel/main.o
LINKER = kernel/linker.ld
BOOT_SRC = kernel/boot.s
BOOT_OBJ = ${BOOT_SRC:.s=.o}

TARGET_TOOLS = $(HOME)/path/to/cross/compiler/i686-elf-
CC = $(TARGET_TOOLS)gcc
export CC
LD = $(TARGET_TOOLS)ld
export LD
AS = $(TARGET_TOOLS)as
export AS
OBJDUMP = $(TARGET_TOOLS)objdump
export OBJDUMP

.PHONY: all qemu clean

all: $(OSBIN)

$(OSBIN): $(BOOT_OBJ) $(OBJECTS)
	$(CC) -T $(LINKER) -o $(OSBIN) -ffreestanding -O2 -nostdlib \
		$(OBJECTS) $(BOOT_OBJ) -lgcc

$(BOOTBIN):
	$(MAKE) -C $(ARCH_BOOT)

%.o: %.s
	$(AS) $< -o $@

%.o: %.c
	$(CC) -c $< -o $@ \
		-std=gnu89 -ffreestanding -O2 -Wall \
		-Wpedantic -Wextra

qemu: $(OSBIN)
	qemu-system-i386 -kernel $(OSBIN)

clean:
	$(MAKE) -C $(ARCH_BOOT) clean
	rm -rf $(BOOT_OBJ) $(OBJECTS)
	rm -rf $(OSBIN)
