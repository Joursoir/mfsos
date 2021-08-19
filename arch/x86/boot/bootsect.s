.code16							# Tell GAS to generate 16 bit code

.global _start					# Make the symbol visible to ld

.include "bios.inc"

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
	mov %ax, %ss				# zero stack (?)
	mov %ax, %sp				# zero stack pointer (?)
								# Don't touch FS and GS register (why?)
	cld							# Set direction flag for incrementing
	mov %dl, boot_drive			# BIOS stores our boot drive in DL,
								# so we remember it

	BIOS_PRINT $boot_os_msg

	mov $0x02, %ah				# Set BIOS read sector routine
	mov boot_drive, %dl			# Read drive number from $boot_drive
	mov $0x00, %ch				# Select cylinder 0
	mov $0x00, %dh				# Select head 0 [has a base of 0]
	mov $0x02, %cl				# Select sector 2 (next after the
								# boot sector) [has a base of 1]
	mov $0x01, %al				# Read 1 sectors
	mov $0x9000, %bx			# Load sectors to ES:BS (0x9000)
	int $0x13					# Start reading from drive
	jc disk_error				# If carry flag set, bios failed to read

	# FIXME: we must compare different register
	cmp %al, %al				# If AL(sect. read) != <>(sect. expected)
	jne disk_error				# then return disk error

	jmp . # TODO: jump into the darkness

disk_error:
	BIOS_PRINT $disk_error_msg
	jmp .

# Global variables
boot_os_msg:
	.asciz "Booting mfsos...\r\n"

disk_error_msg:
	.asciz "Disk read error!"

boot_drive:
	.byte 0

# Bootsector padding
.space 512 - 2 - (. - _start), 0
.word MAGIC
