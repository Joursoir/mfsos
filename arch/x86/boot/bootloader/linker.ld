OUTPUT_FORMAT("binary")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	/* BIOS likes always to load the boot sector to the address 0x7c00,
	where it is sure will not be occupied by important routines. */
	. = 0x7c00;
}
