#ifndef _RAM_H
#define _RAM_H

#include <stdint.h>
#include <z80.h>

void write_ram(uint16_t addr, uint8_t val);

uint8_t read_ram(uint16_t addr);

#endif // _RAM_H
