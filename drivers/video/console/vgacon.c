/*
	Low level VGA based console driver
*/

#include "string.h"
#include "video/vga.h"
#include "asm/io.h"

#define LIGHT_GREY_ON_BLACK \
	VGA_ENTRY_COLOR(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK)

static uint16_t *vga_vram_base;
static size_t vga_vram_size;
static size_t vga_cols;
static size_t vga_rows;
static uint8_t vga_attr;

static size_t cursor_x;
static size_t cursor_y;

void vgacon_init(void)
{
	vga_vram_base = (uint16_t *) VGA_VRAM_BC;
	vga_cols = 80;
	vga_rows = 25;
	vga_vram_size = vga_cols * vga_rows;
	vga_attr = LIGHT_GREY_ON_BLACK;

	cursor_x = 0;
	cursor_y = 0;
}

void vgacon_setattr(uint8_t attr)
{
	vga_attr = attr;
}

void vgacon_scroll(size_t lines)
{
	uint16_t vga_char = VGA_ENTRY(' ', vga_attr);
	size_t count = (vga_rows - lines) * vga_cols;
	memmove(vga_vram_base, vga_vram_base + vga_cols * lines, count * 2);
	for(; count < vga_vram_size; count++)
		vga_vram_base[count] = vga_char;
}

void vgacon_cls(void)
{
	vgacon_scroll(vga_rows);
}

static void putchar(char c)
{
	if(c == '\n') {
		cursor_x = 0;
		if(++cursor_y >= vga_rows) {
			vgacon_scroll(1);
			cursor_y--;
		}	
	}
	else {
		const size_t index = cursor_y * vga_cols + cursor_x;
		vga_vram_base[index] = VGA_ENTRY(c, vga_attr);

		if(++cursor_x >= vga_cols) {
			cursor_x = 0;
			if(++cursor_y >= vga_rows) {
				vgacon_scroll(1);
				cursor_y--;
			}
		}
	}
}

static void update_cursor()
{
	uint16_t pos = cursor_y * vga_cols + cursor_x;
	outb(VGA_CRTC_IC, VGA_CRTC_CURSOR_H);
	outb(VGA_CRTC_DC, (uint8_t) ((pos >> 8) & 0xFF));
	outb(VGA_CRTC_IC, VGA_CRTC_CURSOR_L);
	outb(VGA_CRTC_DC, (uint8_t) (pos & 0xFF));
}

void vgacon_putchar(char c)
{
	putchar(c);
	update_cursor();
}

void vgacon_write(const char *str, size_t size)
{
	size_t i;
	for(i = 0; i < size; i++)
		putchar(str[i]);
	update_cursor();
}

void vgacon_print(const char *str)
{
	vgacon_write(str, strlen(str));
}
