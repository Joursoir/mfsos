OSNAME = mfsos
OSBIN = $(OSNAME).bin
KERNBIN = kernel.bin
# Available options: `bootloader`, `multiboot`
BOOT ?= bootloader

ARCH = x86
ARCH_BOOT = arch/$(ARCH)/boot/$(BOOT)

BOOTBIN = $(ARCH_BOOT)/bootloader.bin
OS_BINARIES = $(KERNBIN)
ifeq ($(BOOT), bootloader)
	OS_BINARIES := $(BOOTBIN) $(OS_BINARIES)
endif

TARGET		= i686-elf
TARGET_TOOLS	= $(PWD)/tools/toolchain/bin/$(TARGET)-

CC	= $(TARGET_TOOLS)gcc
LD	= $(TARGET_TOOLS)ld
AS	= $(TARGET_TOOLS)as
OBJDUMP	= $(TARGET_TOOLS)objdump

C_SOURCES = \
	kernel/main.c \
	kernel/string.c \
	drivers/video/console/vgacon.c
OBJECTS = ${C_SOURCES:.c=.o}

export CC LD AS OBJDUMP

.PHONY: all qemu objdump-boot objdump-kernel clean

all: $(OSBIN)

$(OSBIN): $(OS_BINARIES)
	cat $^ > $@
	dd if=/dev/zero bs=512 count=128 >> $@ # 65536

$(BOOTBIN):
	$(MAKE) -C $(ARCH_BOOT)

$(KERNBIN): $(ARCH_BOOT)/head.o $(OBJECTS)
	$(CC) -Wl,--oformat binary -Ttext 0x1000 -o $@ \
		-ffreestanding -nostdlib \
		$^ -lgcc
	printf "Kernel size: 0x%x\n" `stat -c "%s" $@`

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

objdump-boot: $(BOOTBIN)
	$(MAKE) -C $(ARCH_BOOT) objdump-bootsect objdump-setup

objdump-kernel: $(KERNBIN)
	$(OBJDUMP) -D -m i386 -b binary \
		--adjust-vma=0x1000 -Maddr32,data32 $<

clean:
	$(MAKE) -C $(ARCH_BOOT) clean
	rm -rf $(ARCH_BOOT)/head.o kernel/main.o
	rm -rf $(KERNBIN) $(OSBIN) $(OBJECTS)
