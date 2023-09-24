#ifndef _PROGRAMS_H
#define _PROGRAMS_H

#include <stdint.h>
#include "vidmem.h"
#include "util.h"

#define RAMADDRPROG 0x4000

// store number of programss
extern uint16_t numprogs;

struct Program {
	uint8_t bank;
	uint8_t block;
	char progname[16];
	char extension[3];
	uint16_t size;
	uint8_t padding;
};

void read_programs(void);

void print_programs(void);

#endif // _PROGRAMS_H