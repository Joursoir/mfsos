#ifndef KERNEL_STRING
#define KERNEL_STRING

#include <stddef.h>
#include <stdint.h>

size_t strlen(const char *str);
void *memcpy(void *dest, const void *src, size_t n);
void *memset(void *dest, int c, size_t n);
void *memmove(void *dest, const void *src, size_t n);

#endif /* KERNEL_STRING */
