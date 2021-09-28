/*
	head.s is loaded at 0x1000 (by second stage), its main goal
	is run 32-bit startup code.

	After that manipulations it jumps to kernel written by C
*/

.code32							# Tell GAS to generate 32 bit code
.extern kernel_main

.set CODESEG, 0x08
.set DATASEG, 0x10

.global _start
_start:
	mov $DATASEG, %ax			# Point segment registers to the
	mov %ax, %ds				# data selector we defined in our GDT
	mov %ax, %es
	mov %ax, %ss
	mov %ax, %fs
	mov %ax, %gs

	mov $0x90000, %ebp			# Update stack position so it is right
	mov %ebp, %esp				# at the top of the free space.

	call kernel_main
	jmp . 						# infinite loop
