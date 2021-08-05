#ifndef KERNEL_VIDEO_VGA
#define KERNEL_VIDEO_VGA

#include <stddef.h>
#include <stdint.h>

/* Hardware text mode color constants. */
enum vga_colors {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15
};

uint8_t vga_entry_color(enum vga_colors fg, enum vga_colors bg);
uint16_t vga_entry(uint8_t uc, uint8_t color);
void vga_init(void);
void vga_setcolor(uint8_t color);
void vga_scroll(size_t lines);
void vga_putchar(char c);
void vga_write(const char *str, size_t size);
void vga_print(const char *str);

#endif /* KERNEL_VIDEO_VGA */
