#ifndef __X86_GDT_H
#define __X86_GDT_H

#include <stdint.h>

// Limit is 20-bit value
#define GDT_LIMIT_MAX		(0x000FFFFF)

// Flags (4 bits)
#define GDT_GRAN_4KB		(1 << 3)
#define GDT_GRAN_BYTE		(0 << 3) /*
					  * Granularity. Indicates the size the
					  * limit value is scaled by.
					  */
#define GDT_64BIT		(1 << 1)
#define GDT_32BIT		(1 << 2)
#define GDT_16BIT		(0 << 2)

// Access flags (8 bits)
#define GDT_ACCESS_ACC		(1 << 0) /*
					  * Accessed bit. The CPU sets 1 when
					  * the segment is accessed.
					  */
#define GDT_ACCESS_RW		(1 << 1) /*
					  * Readable/Writable bit.
					  *
					  * For code segments: readable bit.
					  *   If set 1 read access is allowed.
					  *   Write access is never allowed.
					  *
					  * For data segments: writable bit.
					  *   If set 1 write access is allowed.
					  *   Read access is always allowed.
					  */
#define GDT_ACCESS_DC		(1 << 2) /*
					  * Direction/Conforming bit.
					  *
					  */
#define GDT_ACCESS_EX		(1 << 3) /*
					  * Executable bit.
					  *   0 defines a data segment
					  *   1 defines a code segment
					  */
#define GDT_ACCESS_S		(1 << 4) /*
					  * Descriptor type bit.
					  *   0 defines a system segment (TSS, LDT)
					  *   1 defines a code/data segment
					  */
#define GDT_ACCESS_PL0		(0 << 5) /* the highest privilege */
#define GDT_ACCESS_PL1		(1 << 5)
#define GDT_ACCESS_PL2		(2 << 5)
#define GDT_ACCESS_PL3		(3 << 5) /* the lowest privilege */
#define GDT_ACCESS_PRESENT	(1 << 7) /* Must be set for any valid segments */

struct gdt_entry {
	uint16_t limit_low;
	uint16_t base_low;
	uint8_t base_middle;

	union {
		struct {
			uint8_t type : 4; // EX + DC + RW + ACC
			uint8_t s : 1;    // 0 = system desc, 1 = regular desc
			uint8_t dpl : 2;  // desc privilege level
			uint8_t p : 1;    // present
		};

		uint8_t access;
	};

	union {
		struct {
			uint8_t limit_hi : 4;
			uint8_t avl : 1; // available bit
			uint8_t l : 1;   // 64-bit segment
			uint8_t d : 1;   // default operation size. 0 = 16 bit, 1 = 32 bit
			uint8_t g : 1;   // granularity: 0 = byte, 1 = 4 KB
		};

		struct {
			uint8_t limit_high : 4;
			uint8_t flags : 4;
		};
	};

	uint8_t base_high;
} __attribute__((packed));

#endif /* __X86_GDT_H */
