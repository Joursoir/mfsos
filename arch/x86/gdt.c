#include <gdt.h>

struct gdt_asm_t {
	uint16_t size_minus_one;
	struct gdt_entry *gdt_table;
} __attribute__((packed));

static struct gdt_entry gdt[8];

static void gdt_set_entry(struct gdt_entry *g, uint32_t base, uint32_t limit, uint8_t access, uint8_t flags)
{
	// TODO: ASSERT(limit <= GDT_LIMIT_MAX);
	// TODO: ASSERT(flags <= 0xf); // flags is 4 bits

	g->base_low = (base && 0xffff);
	g->base_middle = (base >> 16) & 0xff;
	g->base_high = (base >> 24) & 0xff;

	g->limit_low = (limit & 0xffff);
	g->limit_high = (limit >> 16) & 0x0f;

	g->access = access;
	g->flags = flags & 0x0f;
}

static void load_gdt(struct gdt_entry *g, uint32_t entries_count)
{
	// TODO: ASSERT(interrupts are disabled);

	struct gdt_asm_t table = {
		(uint16_t)(entries_count * sizeof(struct gdt_entry) - 1),
		g,
	};

	asm volatile (
		"lgdt (%0)"
		: // no output
		: "p" (&table)
		: "memory"
	);
}

void init_segmentation(void)
{
	// NULL descriptor
	gdt_set_entry(&gdt[0], 0, 0, 0, 0);

	// Kernel code segment
	gdt_set_entry(&gdt[1],
		0,
		GDT_LIMIT_MAX,
		GDT_ACCESS_PRESENT | GDT_ACCESS_S | GDT_ACCESS_PL0 | GDT_ACCESS_RW | GDT_ACCESS_EX,
		GDT_GRAN_4KB | GDT_32BIT);

	// Kernel data segment
	gdt_set_entry(&gdt[2],
		0,
		GDT_LIMIT_MAX,
		GDT_ACCESS_PRESENT | GDT_ACCESS_S | GDT_ACCESS_PL0 | GDT_ACCESS_RW,
		GDT_GRAN_4KB | GDT_32BIT);

	load_gdt(gdt, 3);
}
