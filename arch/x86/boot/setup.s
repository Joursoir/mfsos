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

# Keyboard Controller commands: 
.set READ_OUTP, 0xD0			# Read Output Port
.set WRITE_OUTP, 0xD1			# Write Output Port

.global _start					# Make the symbol visible to ld
_start:
	mov $SDATASEG, %ax
	mov %ax, %ds
	mov %ax, %ss
	mov $KERNSEG, %ax
	mov %ax, %es

	mov $0xFF00, %bp			# Set up the stack at 0x9ff00
	mov %bp, %sp

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

	cli							# Switch of interrupt until we have set
								# up the protected mode interrupt vector

enable_a20:
	BIOS_PRINT $enable_a20_msg

	call wait_input
	mov $READ_OUTP, %al
	out %al, $0x64 
	call wait_output

	in $0x60, %al				# Read input buffer and store on stack
	push %ax
	call wait_input

	mov $WRITE_OUTP, %al
	out %al, $0x64
	call wait_input

	pop %ax						# Pop the output port data from stack
	or $2, %al					# Set bit 1 (A20) to enable
	out %al, $0x60				# Write the data to the output port
	call wait_input

switch_to_pm:
	BIOS_PRINT $boot_prot_mode_msg
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

wait_input:
	in $0x64, %al				# Read status
	test $2, %al				# Is input buffer full?
	jnz wait_input				# yes - continue waiting
	ret

wait_output:
	in $0x64, %al
	test $1, %al				# Is output buffer full?
	jz wait_output				# no - continue waiting
	ret

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

enable_a20_msg:
	.asciz "Enabling A20 line\r\n"

disk_error_msg:
	.asciz "Disk read error!"

.space (512 * SETUPLEN) - (. - _start), 0
