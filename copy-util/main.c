#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "sst39sf.h"
#include "memory.h"
#include "util.h"

int main(void) {

    const char msg[] = "Copying external bank 0 to internal rom chip.";
    memcpy(vidmem, msg, strlen(msg));

    sst39sf_set_bank(0);
    sst39sf_set_bank_romint(0);

    for(uint16_t i=0; i<4; i++) { // loop over sectors
        sst39sf_wipe_sector_romint(i * 0x1000);

        for(uint16_t j=0; j<0x1000; j++) {
            sst39sf_write_byte_romint(i * 0x1000 + j, sst39sf_read_byte(i * 0x1000 + j));
        }
    }

    const char msgdone[] = "Done copying.";
    memcpy(&vidmem[0x50], msgdone, strlen(msg));

    for(uint8_t i=0; i<16; i++) {
        for(uint8_t j=0; j<8; j++) {
            printhex((i+2)*0x50 +j*3, sst39sf_read_byte_romint(i*8+j));
        }
    }

    return 0;
}
