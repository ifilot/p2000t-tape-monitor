#include "util.h"

void printhex(uint16_t vidaddr, uint8_t val) {
    uint8_t v = (val >> 4) & 0x0F;
    
    if(v < 10) {
        vidmem[vidaddr] = v + 48;
    } else {
        vidmem[vidaddr] = v + 65 - 10;
    }

    vidaddr++;

    v = val & 0x0F;
    if(v < 10) {
        vidmem[vidaddr] = v + 48;
    } else {
        vidmem[vidaddr] = v + 65 - 10;
    }
}
