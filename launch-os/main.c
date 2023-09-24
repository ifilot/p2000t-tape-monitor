#include <string.h>
#include <stdint.h>
#include <stdio.h>

#include "sst39sf.h"
#include "programs.h"
#include "ram.h"
#include "memory.h"

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
    
    uint16_t offset = 0;
    read_programs_offset(offset);
    print_programs(16);

    while(1) {
        if(keymem[0x0C] > 0) {
            for(uint8_t i=0; i<keymem[0x0C]; i++) {
                switch(keymem[i]) {
                    case 25:  // 'n'
                        offset += 8;
                        read_programs_offset(offset);
                        print_programs(16);
                        break;
                    case 53: // 'p'
                        if(offset > 8) {
                            offset -= 8;
                        } else {
                            offset = 0;
                        }
                        read_programs_offset(offset);
                        print_programs(16);
                        break;
                    default:
                        break;
                }
            }
            keymem[0x0C] = 0;
        }
        printhex(20*0x50, offset);

        for(uint8_t i=0; i<8; i++) {
            printhex(21*0x50+(i*3), keymem[i]);    
        }
        for(uint8_t i=0; i<8; i++) {
            printhex(22*0x50+(i*3), keymem[i+8]);    
        }
    }
}

void init(void) {
    const char str[] = "Datacartridge test";
    memcpy(&vidmem[23*0x50], str, strlen(str));
}