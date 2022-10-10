#include "multiboot.h"
#include "video/console/vgacon.h"
#include "gdt.h"

/* Check if the compiler thinks you are targeting the wrong operating system. */
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

#if !defined(__i386__)
#error "This kernel needs to be compiled with a ix86-elf compiler"
#endif

void kernel_main(uint32_t magic, multiboot_info_t *multiboot)
{
	init_segmentation();

	/* Initialize VGA video hardware */
	vgacon_init();

	vgacon_print("Welcome to MFSOS!\n");
}
