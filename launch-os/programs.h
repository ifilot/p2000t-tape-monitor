#ifndef _PROGRAMS_H
#define _PROGRAMS_H

#include <stdint.h>

// store number of programss
extern uint16_t numprogs;

struct Program {
	uint8_t bank;
	uint8_t block;
	char progname[16];
	char extension[3];
	uint16_t size;
};

void read_programs(void);

#endif // _PROGRAMS_H