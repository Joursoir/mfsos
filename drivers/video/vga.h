#ifndef DRIVERS_VIDEO_VGA_H
#define DRIVERS_VIDEO_VGA_H

#include <stddef.h>

/* VGA Video RAM base addresses */
#define VGA_VRAM_BC 0xB8000 // Color
#define VGA_VRAM_BM 0xB0000 // Monochrome

/* VGA index register ports */
#define VGA_CRTC_IC 0x3D4 // Color
#define VGA_CRTC_IM 0x3B4 // Monochrome

/* VGA data register ports */
#define VGA_CRTC_DC 0x3D5 // Color
#define VGA_CRTC_DM 0x3B5 // Monochorme

/* VGA CRTC register indices */
#define VGA_CRTC_CURSOR_H 0x0E
#define VGA_CRTC_CURSOR_L 0x0F

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

#define VGA_ENTRY_COLOR(fg, bg) ((uint8_t)(fg | bg << 4))
#define VGA_ENTRY(uc, color) ((uint16_t) uc | (uint16_t) color << 8)

#endif /* DRIVERS_VIDEO_VGA_H */
