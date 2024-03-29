OSNAME = mfsos
OSBIN = $(OSNAME).bin
KERNBIN = kernel.bin
# Available options: `bootloader`, `multiboot`
BOOT ?= multiboot

ARCH = x86
ARCH_PATH = arch/$(ARCH)
ARCH_INCLUDE = $(PWD)/arch/$(ARCH)/include
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

KERN_HEAD = $(ARCH_BOOT)/head.o
C_SOURCES = \
	kernel/main.c \
	kernel/string.c \
	drivers/video/console/vgacon.c \
	$(ARCH_PATH)/gdt.c
OBJECTS = ${C_SOURCES:.c=.o}

export CC LD AS OBJDUMP
export ARCH_INCLUDE

.PHONY: all qemu objdump-boot objdump-kernel clean

all: $(OSBIN)

$(OSBIN): $(OS_BINARIES)
	cat $^ > $@
	dd if=/dev/zero bs=512 count=128 >> $@ # 65536

$(BOOTBIN) $(KERN_HEAD):
	$(MAKE) -C $(ARCH_BOOT)

$(KERNBIN): $(KERN_HEAD) $(OBJECTS)
	$(CC) -T $(ARCH_BOOT)/linker.ld -o $@ \
		-ffreestanding -nostdlib \
		$^ -lgcc
	printf "Kernel size: 0x%x\n" `stat -c "%s" $@`

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
	rm -f $(KERNBIN) $(OSBIN) $(OBJECTS)
