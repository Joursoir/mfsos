#include "string.h"

size_t strlen(const char *str)
{
	size_t len = 0;
	while(str[len])
		len++;
	return len;
}

/*
	Copy bytes in memory. If copying takes place between objects
	that overlap, the behavior is undefined.
*/
void *memcpy(void *dest, const void *src, size_t n)
{
	size_t i;
	const char *s = src;
	char *d = dest;

	for(i = 0; i < n; i++)
		d[i] = s[i];
	return dest;
}

void *memset(void *dest, int c, size_t n)
{
	char *d = dest;
	while(n--)
		*d++ = c;
	return dest;
}

/*
	Copy bytes in memory with overlapping areas.
*/
void *memmove(void *dest, const void *src, size_t n)
{
	const char *s = src;
	char *d = dest;

	if(dest == src)
		return dest;

	if(dest < src)
		return memcpy(dest, src, n);

	while(n--)
		d[n] = s[n];
	return dest;
}
