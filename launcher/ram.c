#include "ram.h"

void write_ram(uint16_t addr, uint8_t val) {
    z80_outp(0x60, addr  & 0xFF);
    z80_outp(0x61, (addr >> 8) & 0xFF);
    z80_outp(0x64, val);
}

uint8_t read_ram(uint16_t addr) {
    z80_outp(0x60, addr  & 0xFF);
    z80_outp(0x61, (addr >> 8) & 0xFF);
    return z80_inp(0x64);
}
