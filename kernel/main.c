#include "video-vga.h"
#include "gdt.h"

/* Check if the compiler thinks you are targeting the wrong operating system. */
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

#if !defined(__i386__)
#error "This kernel needs to be compiled with a ix86-elf compiler"
#endif
void kernel_main(void) 
{
	init_segmentation();

	/* Initialize VGA video hardware */
	vga_init();

	vga_print("Welcome to MFSOS!\n\t");
}
