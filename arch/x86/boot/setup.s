/*
	setup.s is second stage bootloader loaded at 0x90200 (by 
	first stage), is responsible for getting the system data
	from the BIOS.

	System data puts at special place: 0x90000-0x901FF.
*/

.code16							# Tell GAS to generate 16 bit code

.include "bios.inc"
.include "rm_seg.inc"

# Define some constants for the GDT segment descriptor offsets
.set CODESEG, gdt_code - gdt_start
.set DATASEG, gdt_data - gdt_start

.global _start					# Make the symbol visible to ld
_start:
	mov $SDATASEG, %ax
	mov %ax, %ds
	mov $KERNSEG, %ax
	mov %ax, %es

	BIOS_PRINT $get_data_msg
	# TODO: get memory size
	# TODO: get video infos

load_kernel:					# Load our kernel
	BIOS_PRINT $boot_load_kern_msg

	mov $0x02, %ah				# Set BIOS read sector routine
	mov (0), %dl				# Read drive boot
	mov $0x00, %ch				# Select cylinder 0
	mov $0x00, %dh				# Select head 0 [has a base of 0]
	mov $0x02+SETUPLEN, %cl		# Select sector 2 (next after the
								# boot sector) [has a base of 1]
	mov $0x10, %al				# Read 16 sectors
	mov $0x00, %bx				# Load sectors to ES:BX ($KERNSEG:0)
	int $0x13					# Start reading from drive
	jc disk_error				# If carry flag set, bios failed to read

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
	jmp $CODESEG, $KERNADDR

disk_error:
	BIOS_PRINT $disk_error_msg
	jmp .

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
gdt_descriptor:
	# The 6-byte GDT structure containing:
	# - GDT size, 2 bytes (size always less one of the real size):
	.word gdt_end - gdt_start - 1
	# - GDT address, 4 bytes:
	.word gdt_start, 0x9

get_data_msg:
	.asciz "Getting the system data from the BIOS\r\n"

boot_prot_mode_msg:
	.asciz "Entering 32-bit protected mode\r\n"

boot_load_kern_msg:
	.asciz "Loading kernel into memory\r\n"

disk_error_msg:
	.asciz "Disk read error!"

.space (512 * SETUPLEN) - (. - _start), 0
