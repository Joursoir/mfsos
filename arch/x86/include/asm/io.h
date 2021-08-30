#ifndef ASM_X86_IO_H
#define ASM_X86_IO_H

#include <stdint.h>

static inline void outb(uint16_t port, uint8_t data)
{
	asm volatile (
		"out %0,%1"
		: /* no output */
		: "a" (data), "d" (port)
	);
}

#endif /* ASM_X86_IO_H */
