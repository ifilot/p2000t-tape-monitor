#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "constants.h"
#include "sst39sf.h"
#include "memory.h"
#include "leds.h"
#include "config.h"
#include "tape.h"
#include "util.h"
#include "romchip.h"

// forward declarations
void init(void);

int main(void) {
    init();

    sprintf(&vidmem[0x50*3], "Press any key to read the tape.");
    while(keymem[0x0C] == 0) {} // wait until a key is pressed
    clearline(3);

    // rewind the tape
    tape_rewind();

    uint8_t line = 4;
    uint8_t iter = 0;

    while(memory[CASSTAT] != 'M') {
        // read the first block from the tape
        tape_read_block();
        if(memory[CASSTAT] != 0) {
            sprintf(&vidmem[0x50*20], "Stop reading tape, exit code: %c", memory[CASSTAT]);
            break;
        }

        // set file counter
        vidmem[0x50*line] = COL_YELLOW;
        sprintf(&vidmem[0x50*line+1], "%03i", iter+1);
        vidmem[0x50*line+4] = COL_WHITE;

        // grab total blocks and start copying first block
        const uint8_t totalblocks = memory[BLOCKCTR];
        uint8_t blockcounter = 0;
        uint16_t bankblock = copyblock(blockcounter, totalblocks, 0xFFFF);

        if(bankblock == 0xFFFF) {   // chip is full, exit
            sprintf(&vidmem[0x50*18], "CHIP IS FULL. TERMINATING.");
            break;
        }

        // write start byte
        write_startbyte(bankblock);

        // copy data from description to screen
        memcpy(&vidmem[0x50*line+5], &memory[DESC1], 8);
        memcpy(&vidmem[0x50*line+5+8], &memory[DESC2], 8);
        memcpy(&vidmem[0x50*line+5+17], &memory[EXT], 3);
        uint16_t length = (uint16_t)memory[LENGTH] | ((uint16_t)memory[LENGTH+1] << 8);
        vidmem[0x50*line+25] = COL_CYAN;
        sprintf(&vidmem[0x50*line+26], "%05i", length);
        sprintf(&vidmem[0x50*line+32], "%02i", totalblocks);
        vidmem[0x50*line+34] = COL_RED;

        // consume all blocks
        while(memory[BLOCKCTR] > 1) {
            blockcounter++;
            sprintf(&vidmem[0x50*line+35], "%02i", memory[BLOCKCTR]-1);
            tape_read_block();
            if(memory[CASSTAT] != 0) {
                sprintf(&vidmem[0x50*20], "Stop reading tape, exit code: %c", memory[CASSTAT]);
                return 0;
            }
            bankblock = copyblock(blockcounter, totalblocks, bankblock);
        }
        vidmem[0x50*line+34] = COL_GREEN;
        sprintf(&vidmem[0x50*line+35], "OK");

        line++;
        iter++;

        clearline(3);
        sprintf(&vidmem[0x50*3], "Press any key to read the next file.");

        keymem[0x0C] = 0;
        while(keymem[0x0C] == 0) {} // wait until a key is pressed
        clearline(3); // remove line to press any key
    }

    sprintf(&vidmem[0x50*21], "All done");

    return 0;
}

void init(void) {
    ledbank_init(); // turn all leds off

    vidmem[0x50] = TEXT_DOUBLE;
    vidmem[0x50+1] = COL_CYAN;
    sprintf(&vidmem[0x50+2], "CASSETTE-UTILITY");
    sprintf(&vidmem[0x50*22], "Version: %s", __VERSION__);
    sprintf(&vidmem[0x50*23], "Compiled at: %s / %s", __DATE__, __TIME__);

    // determine chip id
    uint16_t chip_id = sst39sf_get_chip_id();

    switch(chip_id & 0xFF) {
        case 0xB5:
            sprintf(&vidmem[21], "%s", "SST39SF010 (128kb)");
            __nrbanks = 2;
            break;
        case 0xB6:
            sprintf(&vidmem[21], "%s", "SST39SF020 (256kb)");
            __nrbanks = 4;
            break;
        case 0xB7:
            sprintf(&vidmem[21], "%s", "SST39SF040 (512kb)");
            __nrbanks = 8;
            break;
        default:
            // stop initialization and throw error message
            sprintf(&vidmem[0x50 * 10], "%s", "[ERROR]: Cannot detect external chip");
            sprintf(&vidmem[0x50 * 11], "%s", "Ensure a ROM is inserted in the data");
            sprintf(&vidmem[0x50 * 12], "%s", "cartridge and press RESET");
            while(0 == 0){}; // put in infinite loop
    }
}
