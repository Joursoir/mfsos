OSNAME = mfsos
OSBIN = $(OSNAME).bin

OBJECTS = kernel/main.o
LINKER = kernel/linker.ld
BOOT_SRC = kernel/boot.s
BOOT_OBJ = ${BOOT_SRC:.s=.o}

TARGET_TOOLS = $(HOME)/path/to/cross/compiler/i686-elf-
CC = $(TARGET_TOOLS)gcc
AS = $(TARGET_TOOLS)as

.PHONY: all qemu clean

all: $(OSBIN)

$(OSBIN): $(BOOT_OBJ) $(OBJECTS)
	$(CC) -T $(LINKER) -o $(OSBIN) -ffreestanding -O2 -nostdlib \
		$(OBJECTS) $(BOOT_OBJ) -lgcc

$(BOOT_OBJ): $(BOOT_SRC)
	$(AS) $< -o $@

%.o: %.c
	$(CC) -c $< -o $@ \
		-std=gnu89 -ffreestanding -O2 -Wall \
		-Wpedantic -Wextra

qemu: $(OSBIN)
	qemu-system-i386 -kernel $(OSBIN)

clean:
	rm -rf $(BOOT_OBJ) $(OBJECTS) $(OSBIN)
