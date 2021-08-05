#include "video-vga.h"
#include "string.h"
#include "i386.h"

#define VGA_BASE 0xB8000
#define CRTC_PORT 0x3D4

#define VGA_WIDTH 80
#define VGA_HEIGHT 25

static size_t vga_row, vga_column;
static uint8_t vga_color;
static uint16_t *vga_buffer;

uint8_t vga_entry_color(enum vga_colors fg, enum vga_colors bg)
{
	return fg | bg << 4;
}

uint16_t vga_entry(uint8_t uc, uint8_t color)
{
	return (uint16_t) uc | (uint16_t) color << 8;
}

void vga_init(void)
{
	size_t x, y;
	size_t vga_char;
	vga_row = 0, vga_column = 0;
	vga_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
	vga_char = vga_entry(' ', vga_color);
	vga_buffer = (uint16_t *) VGA_BASE;
	for(y = 0; y < VGA_HEIGHT; y++) {
		for(x = 0; x < VGA_WIDTH; x++) {
			const size_t index = y * VGA_WIDTH + x;
			vga_buffer[index] = vga_char;
		}
	}
}

void vga_setcolor(uint8_t color)
{
	vga_color = color;
}

void vga_scroll(size_t lines)
{
	size_t count = (VGA_HEIGHT - lines) * VGA_WIDTH;
	size_t vga_char = vga_entry(' ', vga_color);

	memmove(vga_buffer, vga_buffer + VGA_WIDTH * lines, count * 2);
	for(; count < (vga_row + 1) * VGA_WIDTH; count++)
		vga_buffer[count] = vga_char;
}

void vga_putchar(char c)
{
	uint16_t pos;
	if(c == '\n') {
		vga_column = 0;
		if(++vga_row >= VGA_HEIGHT) {
			vga_scroll(1);
			vga_row--;
		}	
	}
	else {
		const size_t index = vga_row * VGA_WIDTH + vga_column;
		vga_buffer[index] = vga_entry(c, vga_color);

		if(++vga_column >= VGA_WIDTH) {
			vga_column = 0;
			if(++vga_row >= VGA_HEIGHT) {
				vga_scroll(1);
				vga_row--;
			}
		}
	}

	/* Update cursor position */
	pos = vga_row * VGA_WIDTH + vga_column;
	outb(CRTC_PORT, 0x0E);
	outb(CRTC_PORT+1, (uint8_t) ((pos >> 8) & 0xFF));
	outb(CRTC_PORT, 0x0F);
	outb(CRTC_PORT+1, (uint8_t) (pos & 0xFF));
}


void vga_write(const char *str, size_t size)
{
	size_t i;
	for(i = 0; i < size; i++)
		vga_putchar(str[i]);
}

void vga_print(const char *str)
{
	vga_write(str, strlen(str));
}
