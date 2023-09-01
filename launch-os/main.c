#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include "sst39sf.h"
#include "programs.h"
#include "ram.h"

__at (0x5000) char vidmem[];

int main(void) {
    read_programs();
    uint16_t ram_ptr = 0x0000;
    for(uint16_t i=0; i<4; i++) {
        for(uint16_t j=0; j<23; j++) {
            vidmem[i*0x50+j] = read_ram(ram_ptr++);
        }
    }

    while(1) {}

    return 0;
}