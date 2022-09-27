/*
	bootsect.s is loaded at 0x7c00 (BIOS likes always to load the boot
	sector to this address). It is first stage bootloader, it has one
	task - loads setup.s (second stage) to 0x90000 and jumps there.
*/

.code16							# Tell GAS to generate 16 bit code

.include "bios.inc"
.include "rm_seg.inc"

.global _start					# Make the symbol visible to ld
_start:
	jmp $0x0, $_start2			# Normalize the start address
								# CS = 0 and IP = _start2
_start2:
	mov $SDATASEG, %ax			# We will store the boot drive at
	mov %ax, %ds				# $SDATASEG in the first byte
	mov $SETUPSEG, %ax			# Do it for disk read routine (see below)
	mov %ax, %es

	cld							# Set direction flag for incrementing
	mov %dl, (0)				# BIOS stores our boot drive in DL,
								# so we remember it
	mov %cs, %ax				# AX = CS = 0 (see above)
	mov %ax, %ds				# Zero data segment register

load_setup:
	BIOS_PRINT $load_setup_msg	# The routine uses only AX register

	mov $0x02, %ah				# Set BIOS read sector routine
	mov $0x00, %ch				# Select cylinder 0
	mov $0x00, %dh				# Select head 0 [has a base of 0]
	mov $0x02, %cl				# Select sector 2 (next after the
								# boot sector) [has a base of 1]
	mov $SETUPLEN, %al			# Read $SETUPLEN sectors
	mov $0x0, %bx				# Load sectors to ES:BX ($SETUPSEG:0)
	int $0x13					# Start reading from drive
	jc disk_error				# If carry flag set, bios failed to read

	# Make a far jump to our setup code
	jmp $SETUPSEG, $0x0

disk_error:
	BIOS_PRINT $disk_error_msg
	jmp .

load_setup_msg:
	.asciz "Loading setup sectors\r\n"

disk_error_msg:
	.asciz "Disk read error!"

# Bootsector padding
.space 512 - 2 - (. - _start), 0
boot_flag:
	.word 0xAA55
