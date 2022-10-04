OUTPUT_FORMAT("binary")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	/* Our bootloader loads kernel at 4 KiB */
	. = 0x1000;
}
