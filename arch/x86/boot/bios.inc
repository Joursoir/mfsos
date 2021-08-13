.macro BIOS_PRINT string
	mov $0x0e, %ah				# Set writing char in TTY mode routine
	mov \string, %si			# Set in Source Index reg the beginning
								# address of a string
print_loop\@:
	lodsb						# Increase SI by 1 byte => get next char
	or %al, %al					# Check for a '\0'
	jz print_done\@

	int $0x10					# Print a char in al register
	jmp print_loop\@
print_done\@:
.endm

.macro PUTCHAR char
	mov $0x0e, %ah				# Set writing char in TTY mode routine
	mov \char, %al
	int $0x10					# Print a char in al register
.endm
