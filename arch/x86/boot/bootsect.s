.code16							# Tell GAS to generate 16 bit code

.global _start					# Make the symbol visible to ld

.include "bios.inc"

# Define some constants for the GDT segment descriptor offsets
.set CODESEG, gdt_code - gdt_start
.set DATASEG, gdt_data - gdt_start

.set SYSSEG, 0x1000				# Historical load address
.set MAGIC, 0xAA55

.section .text.bootentry		# Code that will start executing at
								# special address (specified in linker)
_start:
	jmp $0x0, $_start2			# Normalize the start address
								# CS = 0 and IP = _start2
_start2:
	mov %cs, %ax				# AX = CS = 0 (see above)
	mov %ax, %ds				# Zero segment registers
	mov %ax, %es
	mov %ax, %ss
	mov %ax, %sp

	cld							# Set direction flag for incrementing
	mov %dl, boot_drive			# BIOS stores our boot drive in DL,
								# so we remember it

	BIOS_PRINT $boot_real_mode_msg

load_kernel:					# Load our kernel
	BIOS_PRINT $boot_load_kern_msg

	mov $0x02, %ah				# Set BIOS read sector routine
	mov boot_drive, %dl			# Read drive number from $boot_drive
	mov $0x00, %ch				# Select cylinder 0
	mov $0x00, %dh				# Select head 0 [has a base of 0]
	mov $0x02, %cl				# Select sector 2 (next after the
								# boot sector) [has a base of 1]
	mov $0x01, %al				# Read 1 sectors
	mov $SYSSEG, %bx			# Load sectors to ES:BX (0:$SYSSEG)
	int $0x13					# Start reading from drive
	jc disk_error				# If carry flag set, bios failed to read

	# FIXME: we must compare different register
	cmp %al, %al				# If AL(sect. read) != <>(sect. expected)
	jne disk_error				# then return disk error

switch_to_pm:
	BIOS_PRINT $boot_prot_mode_msg
	cli							# Switch of interrupt until we have set
								# up the protected mode interrupt vector
	lgdt gdt_descriptor			# Load our global descriptor table

	mov %cr0, %eax				# Set the first bit of CR0
	or $0x01, %eax				# to make the switch to protected mode
	mov %eax, %cr0

	# Make a far jump to our 32-bit code.
	# This also forces the CPU to flush its cache of pre-fetched
	# and real-mode decoded instructions, which can cause problems
	jmp $CODESEG, $init_pm

disk_error:
	BIOS_PRINT $disk_error_msg
	jmp .

.code32
init_pm:
	mov $DATASEG, %ax			# Point segment registers to the
	mov %ax, %ds				# data selector we defined in our GDT
	mov %ax, %es
	mov %ax, %ss
	mov %ax, %fs
	mov %ax, %gs

	mov $0x90000, %ebp			# Update stack position so it is right
	mov %ebp, %esp				# at the top of the free space.

	jmp . 						# infinite loop

# Global Descriptor Table (contains 8-byte entries)
gdt_start:
gdt_null:						# The mandatory null descriptor
	.quad 0x0

gdt_code:						# The code segment descriptor
	# Base = 0x0, limit = 0xfffff
	# 1st flags: (present)1 (privilege)00 (descriptor type)1 -> b1001
	# Type flags: (code)1 (conforming)0 (readable)1 (accessed)0 -> b1010
	# 2nd flags: (granularity)1 (size)1 (64-bit seg)0 (AVL)0 -> b1100
	.word 0xffff				# Limit (bits 0-15)
	.word 0x0					# Base (bits 0-15)
	.byte 0x0					# Base (bits 16-23)
	.byte 0b10011010			# 1st flags, type flags
	.byte 0b11001111			# 2nd flags, limit (bits 16-19)
	.byte 0x0					# Base (bits 24-31)

gdt_data: 						# the data segment descriptor
	# Same as code segment except for the type flags:
	# Type flags: (code)0 (direction)0 (writable)1, (accessed)0 -> b0010
	# P.S: direction bit: 0 the segment grows up
	.word 0xffff				# Limit (bits 0-15)
	.word 0x0					# Base (bits 0-15)
	.byte 0x0					# Base (bits 16-23)
	.byte 0b10010010			# 1st flags, type flags
	.byte 0b11001111			# 2nd flags, limit (bits 16-19)
	.byte 0x0					# Base (bits 24-31)
gdt_end:

# Global variables
boot_drive:
	.byte 0

gdt_descriptor:
	# The 6-byte GDT structure containing:
	# - GDT size, 2 bytes (size always less one of the real size):
	.word gdt_end - gdt_start - 1
	# - GDT address, 4 bytes:
	.long gdt_start

boot_real_mode_msg:
	.asciz "Started mfsos in 16-bit real mode\r\n"

boot_prot_mode_msg:
	.asciz "Entering 32-bit protected mode\r\n"

boot_load_kern_msg:
	.asciz "Loading kernel into memory\r\n"

disk_error_msg:
	.asciz "Disk read error!"

# Bootsector padding
.space 512 - 2 - (. - _start), 0
.word MAGIC
