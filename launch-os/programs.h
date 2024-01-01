#ifndef _PROGRAMS_H
#define _PROGRAMS_H

#include <stdio.h>
#include <stdint.h>
#include "memory.h"
#include "util.h"
#include "constants.h"
#include "sst39sf.h"
#include "leds.h"

#define RAMADDRPROG 0x7000
#define RAMLINKEDLIST 0x7D00
#define PRINTPROGROW 3

// store number of programs
extern uint16_t __nrprogs;
extern uint8_t __nrbanks;

struct Program {
    uint8_t bank;
    uint8_t block;
    char progname[16];
    char extension[3];
    uint16_t size;
    uint8_t padding;
};

uint16_t get_number_programs(void);

void read_programs(void);

void read_programs_offset(uint16_t offset);

void print_programs(uint8_t numprogs, uint16_t offset);

uint16_t build_linked_list(uint16_t progid);

void print_linked_list(uint8_t row);

void copyprogramlinkedlist(void);

extern void copyblock(uint16_t ramptr, uint16_t romptr) __z88dk_callee;

#endif // _PROGRAMS_H
