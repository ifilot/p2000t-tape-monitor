#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include "sst39sf.h"
#include "programs.h"
#include "ram.h"
#include "vidmem.h"

void init(void);

int main(void) {
    init();

    // set rom bank to zero
    sst39sf_set_bank(0);

    // set rom pointer to zero
    uint16_t romptr = 0x0000;

    // print the first 80 characters on the screen
    // for(uint16_t j=0; j<10; j++) {
    //     uint16_t vidptr = 0x50*(j+12);
    //     for(uint16_t i=0; i<8; i++) {
    //         uint8_t v = sst39sf_read_byte(romptr++);
    //         printhex(vidptr, v);
    //         vidptr += 3;
    //     }
    // }    

    // read the programs on the cartridge and place the
    // contents on the cartridge RAM
    read_programs();
    print_programs();

    return 0;
}

void init(void) {
    const char str[] = "Datacartridge test";
    memcpy(&vidmem[23*0x50], str, strlen(str));
}