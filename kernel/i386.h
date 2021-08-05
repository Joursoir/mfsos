#ifndef KERNEL_I386
#define KERNEL_I386

static inline void outb(uint16_t port, uint8_t data)
{
	asm volatile (
		"out %0,%1"
		: /* no output */
		: "a" (data), "d" (port)
	);
}

#endif /* KERNEL_I386 */
