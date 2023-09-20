#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include "sst39sf.h"
#include "programs.h"
#include "ram.h"

__at (0x5000) char vidmem[];
void printhex(uint16_t, uint8_t);
void init(void);

int main(void) {
    init();

    sst39sf_set_bank(0);
    uint16_t romptr = 0x0000;
    for(uint16_t j=0; j<10; j++) {
        uint16_t vidptr = 0x50*(j+10);
        for(uint16_t i=0; i<8; i++) {
            uint8_t v = sst39sf_read_byte(romptr++);
            printhex(vidptr, v);
            vidptr += 3;
        }
    }    

    read_programs();
    uint16_t ram_ptr = 0x0000;
    for(uint16_t i=0; i<4; i++) {
        for(uint16_t j=0; j<24; j++) {
            vidmem[i*0x50+j] = read_ram(ram_ptr++);
        }
    }

    return 0;
}

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

void init(void) {
    const char str[] = "Datacartridge test";
    memcpy(&vidmem[23*0x50], str, strlen(str));
}