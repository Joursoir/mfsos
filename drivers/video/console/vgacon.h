#ifndef DRIVERS_VIDEO_CONSOLE_VGA_H
#define DRIVERS_VIDEO_CONSOLE_VGA_H

#include <stddef.h>
#include <stdint.h>

void vgacon_init(void);
void vgacon_setattr(uint8_t attr);
void vgacon_scroll(size_t lines);
void vgacon_cls(void);
void vgacon_putchar(char c);
void vgacon_write(const char *str, size_t size);
void vgacon_print(const char *str);

#endif /* DRIVERS_VIDEO_CONSOLE_VGA_H */
