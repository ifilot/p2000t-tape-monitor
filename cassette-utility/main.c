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

// forward declarations
void init(void);

int main(void) {
    init();

    sprintf(&vidmem[0x50*1], "Press any key to read the tape.");
    while(keymem[0x0C] == 0) {} // wait until a key is pressed

    // rewind the tape
    tape_rewind();

    uint8_t line = 3;
    uint8_t iter = 0;

    while(memory[CASSTAT] != 'M' && iter < 20) {
        sprintf(&vidmem[0x50*line], "%04i", iter+1);
        tape_read_block();

        // copy data from description to screen
        memcpy(&vidmem[0x50*line+5], &memory[DESC1], 8);
        memcpy(&vidmem[0x50*line+13], &memory[DESC2], 8);
        uint16_t length = (uint16_t)memory[LENGTH] | ((uint16_t)memory[LENGTH+1] << 8);
        sprintf(&vidmem[0x50*line+22], "%05i", length);
        sprintf(&vidmem[0x50*line+28], "%02i", memory[BLOCKCTR]);

        // consume all blocks
        while(memory[BLOCKCTR] > 1) {
            sprintf(&vidmem[0x50*line+31], "%02i", memory[BLOCKCTR]-1);
            tape_read_block();
        }
        vidmem[0x50*line+30] = COL_GREEN;
        sprintf(&vidmem[0x50*line+31], "OK");

        line++;
        iter++;

        clearline(1);
        sprintf(&vidmem[0x50*1], "Press any key to read the next file.");

        keymem[0x0C] = 0;
        while(keymem[0x0C] == 0) {} // wait until a key is pressed
    }

    sprintf(&vidmem[0x50*21], "All done");

    return 0;
}

void init(void) {
    ledbank_init(); // turn all leds off
    sprintf(&vidmem[0x50*22], "Version: %s", __VERSION__);
    sprintf(&vidmem[0x50*23], "Compiled at: %s / %s", __DATE__, __TIME__);
}
