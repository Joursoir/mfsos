/*
	setup.s is second stage bootloader loaded at 0x90200 (by 
	first stage), is responsible for getting the system data
	from the BIOS.

	System data puts at special place: 0x90000-0x901FF.
*/

.code16							# Tell GAS to generate 16 bit code

.include "bios.inc"
.include "rm_seg.inc"

.set ENDSEG, KERNSEG + KERNSIZE	# Where to stop loading kernel

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

	# Get disk drive parameters
	xor %ax, %ax
	mov %ax, %es				# ES:DI = 0x0000:0x0000 to guard
	mov %ax, %di				# against BIOS bugs
	mov (0), %dl				# Set drive boot
	mov $0x8, %ah
	int $0x13
	jc disk_error

	# Interrupt return:
	# - CH = low eight bits of maximum cylinder number
	# - CL = maximum sector number (bits 5-0)
	#        high two bits of maximum cylinder number (bits 7-6)
	# - DH = maximum head number
	xor %ch, %ch
	and $0b00111111, %cl
	xor %dl, %dl
	mov %dx, heads
	mov %cx, sectors

	# TODO: get memory size
	# TODO: get video infos

load_kernel:					# Load our kernel
	BIOS_PRINT $boot_load_kern_msg

	# Load the system at $KERNSEG address:
	mov $KERNSEG, %ax
	mov %ax, %es				# ES - starting address segment
	xor %bx, %bx				# BX is offset within segment

	# A few words about the algorithm:
	# We read 0x10000 bytes (64 kB) and overflow BX (16 bytes register),
	# then add 0x1000 to ES reg, after that compare with $ENDSEG
	#
	# If KERNSIZE != 0x10000 * N we read some unnecessary data, but
	# i think it's not a problem
repeat_read:
	mov %es, %ax
	cmp $ENDSEG, %ax
	jae enable_a20				# Jump if AX >= $ENDSEG
get_sects_for_read:
	mov sectors, %ax			# AX = amount of sectors - current sector
	sub csect, %ax				# AX has 6 significant bytes
	mov %ax, %cx				# Calculate how many bytes we get by
								# reading AX sectors
	shl $9, %cx					# One sector = 2^9 = 512
	add %bx, %cx				# CX = 0@@@.@@@0.0000.0000 + BX
	jnc read_sects				# if not overflow, then jump
	jz read_sects				# if CX = 0, then jump
	xor %ax, %ax				# AX = 0
	sub %bx, %ax				# AX = amount of sectors that we must
	shr $9, %ax					# read for overflow BX
read_sects:
	call read_track				# INPUT: AX
	mov %ax, %cx				# CX = amount of sectors that we read
	add csect, %ax
	cmp sectors, %ax			# Current sector = amount of sectors?
	jne check_read				# If not equal, jump
	mov chead, %ax
	cmp heads, %ax				# Current head = amount of heads?
	jne inc_chead				# If not equal, jump
	movw $0xffff, chead			# Current head will overflow and equal 0
								# after INC instuction in inc_chead
	incw ctrack					# Go to next cylinder
								# We don't check cylinder overflow
								# because it makes no sense
inc_chead:
	incw chead
	xor %ax, %ax
check_read:
	mov %ax, csect				# Calculate how many bytes we get by
	shl $9, %cx					# reading AX sectors
	add %cx, %bx				# Add it to BX
	jnc repeat_read				# If BX not overflow, jjmp
	mov %es, %ax
	add $0x1000, %ax			# We read 0x10000 = 65536 bytes
	mov %ax, %es
	xor %bx, %bx
	jmp repeat_read

# INPUT:
# AX - amount of sectors that we want to read
read_track:
	push %ax
	push %bx
	push %cx
	push %dx
	mov ctrack, %dx
	mov csect, %cx				# Set sector
	inc %cx						# Add +1 because sector has a base of 1
	mov %dl, %ch				# Set cylinder
	mov chead, %dh				# Set head
	mov %dl, %dh
	mov (0), %dl				# Set boot
	mov $0x02, %ah				# Set BIOS read sector routine
	int $0x13
	jc .						# Error :(
	pop %dx
	pop %cx
	pop %bx
	pop %ax
	ret

enable_a20:
	BIOS_PRINT $enable_a20_msg

	cli							# Switch of interrupt until we have set
								# up the protected mode interrupt vector

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

# Total amount of HDD components:
heads:							# 8 significant bytes
	.word 0x0
sectors:						# 6 significant bytes
	.word 0x0

# The number of the current component with which we interact:
ctrack:							# track/cylinder
	.word 0x0
chead:
	.word 0x0
csect:
	.word 1 + SETUPLEN

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
