OSNAME = mfsos
OSBIN = $(OSNAME).bin
KERNBIN = kernel.bin

ARCH = x86
ARCH_BOOT = arch/$(ARCH)/boot
BOOTBIN = $(ARCH_BOOT)/bootloader.bin

TARGET_TOOLS = $(HOME)/path/to/cross/compiler/i686-elf-
CC = $(TARGET_TOOLS)gcc
export CC
LD = $(TARGET_TOOLS)ld
export LD
AS = $(TARGET_TOOLS)as
export AS
OBJDUMP = $(TARGET_TOOLS)objdump
export OBJDUMP

C_SOURCES = \
	kernel/main.c \
	kernel/string.c \
	drivers/video/console/vgacon.c
OBJECTS = ${C_SOURCES:.c=.o}

.PHONY: all qemu clean

all: $(OSBIN)

$(OSBIN): $(BOOTBIN) $(KERNBIN)
	cat $^ > $@
	dd if=/dev/zero bs=512 count=128 >> $@ # 65536

$(BOOTBIN):
	$(MAKE) -C $(ARCH_BOOT)

$(KERNBIN): $(ARCH_BOOT)/head.o $(OBJECTS)
	$(CC) -Wl,--oformat binary -Ttext 0x1000 -o $@ \
		-ffreestanding -nostdlib \
		$^ -lgcc

%.o: %.s
	$(AS) $< -o $@

%.o: %.c
	$(CC) -std=gnu89 -Wall -ffreestanding -nostdlib \
		-I arch/$(ARCH)/include \
		-I kernel \
		-I drivers \
		-c $< -o $@ -lgcc

qemu: $(OSBIN)
	qemu-system-i386 -kernel $(OSBIN)

clean:
	$(MAKE) -C $(ARCH_BOOT) clean
	rm -rf $(ARCH_BOOT)/head.o kernel/main.o
	rm -rf $(KERNBIN) $(OSBIN) $(OBJECTS)
