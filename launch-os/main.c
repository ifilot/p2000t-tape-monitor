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

    // set rom bank to zero
    sst39sf_set_bank(0);

    // set rom pointer to zero
    uint16_t romptr = 0x0000;

    // print the first 80 characters on the screen
    for(uint16_t j=0; j<10; j++) {
        uint16_t vidptr = 0x50*(j+12);
        for(uint16_t i=0; i<8; i++) {
            uint8_t v = sst39sf_read_byte(romptr++);
            printhex(vidptr, v);
            vidptr += 3;
        }
    }    

    // read the programs on the cartridge and place the
    // contents on the cartridge RAM
    read_programs();

    // print the first four programs from the RAM on the screen
    for(uint16_t i=0; i<6; i++) {
        for(uint8_t j=0; j<16; j++) {
            vidmem[i*0x50+j] = read_ram(i * 24 + 2 + j);
        }
        
        vidmem[i*0x50+16] = ' ';
        
        for(uint8_t j=0; j<3; j++) {
            vidmem[i*0x50+17+j] = read_ram(i * 24 + 18 + j);
        }

        printhex(i*0x50+21, read_ram(i * 24 + 21));
        printhex(i*0x50+23, read_ram(i * 24 + 22));
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