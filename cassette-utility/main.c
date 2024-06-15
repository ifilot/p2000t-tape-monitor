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
#include "terminal.h"

// forward declarations
void init(void);

int main(void) {
    init();

    // try to access the ROM chip
    print_info("Cassette utility loaded", 0);
    print_info("Try to access ROM chip", 1);
    uint16_t chip_id = sst39sf_get_chip_id();
    sprintf(termbuffer, "Found chip id: %04X", chip_id);
    terminal_printtermbuffer();
    switch(chip_id) {
        case 0xBFB5:
            __nrbanks = 2;
            print_info("SST39SF010 chip. Capacity: 128kb", 0);
        break;
        case 0xBFB6:
            __nrbanks = 4;
            print_info("SST39SF020 chip. Capacity: 256kb", 0);
        break;
        case 0xBFB7:
            __nrbanks = 8;
            print_info("SST39SF040 chip. Capacity: 512kb", 0);
        break;
        default:
            print_error("Invalid CHIP id encountered.");
            return 0;
        break;
    }

    // create placeholders to store tape data
    char description[17];
    description[16] = '\0';
    char ext[4];
    ext[3] = '\0';

    for(;;) {
        // whether to proceed to next cassette
        print_info("Start reading tape? (Y/N)", 1);
        if(wait_for_key_fixed(33) == 0) {
            break;
        }

        // rewind the tape
        print_info("Rewinding tape...", 1);
        tape_rewind();

        while(memory[CASSTAT] != 'M') {
            // read the first block from the tape; the data from the tape is now
            // copied to internal memory
            print_info("Reading next program...", 1);
            tape_read_block();
            if(memory[CASSTAT] != 0) {
                sprintf(termbuffer, "%cStop reading tape, exit code: %c", COL_RED, memory[CASSTAT]);
                terminal_printtermbuffer();
                break;
            }

            // copy data from description to screen
            memcpy(description, &memory[DESC1], 8);
            memcpy(&description[8], &memory[DESC2], 8);
            memcpy(ext, &memory[EXT], 3);
            const uint8_t totalblocks = memory[BLOCKCTR];
            uint16_t length = (uint16_t)memory[LENGTH] | ((uint16_t)memory[LENGTH+1] << 8);

            // at this point, the data resides in internal memory and the user is
            // asked whether they want to store the program from tape on the ROM
            // chip or whether they want to continue searching for the next program
            // on the tape
            sprintf(termbuffer, "Found: %c%s %s%c%i%c%i", COL_YELLOW, description, 
                    ext,COL_CYAN,totalblocks,COL_MAGENTA,length);
            terminal_printtermbuffer();
            print_info("Copy program to ROM? (Y/N)", 1);

            // check if user presses YES key
            uint8_t store_continue = wait_for_key_fixed(33);

            if(store_continue == 1) {
                // grab total blocks and start copying first block
                uint8_t blockcounter = 0;
                uint16_t bankblock = copyblock(blockcounter, totalblocks, 0xFFFF);

                if(bankblock == 0xFFFF) {   // chip is full, exit
                    print_error("CHIP IS FULL. TERMINATING.");
                    return 0;
                }

                // write start byte
                write_startbyte(bankblock);

                // consume all blocks
                while(memory[BLOCKCTR] > 1) {
                    blockcounter++;
                    sprintf(termbuffer, "Remaining blocks: %i...", memory[BLOCKCTR]-1);
                    terminal_redoline();
                    tape_read_block();
                    if(memory[CASSTAT] != 0) {
                        sprintf(termbuffer, "Stop reading tape, exit code: %c", memory[CASSTAT]);
                        terminal_printtermbuffer();
                        return 0;
                    }
                    bankblock = copyblock(blockcounter, totalblocks, bankblock);
                }
                sprintf(termbuffer, "%cCopied: %s to ROM", COL_GREEN, description);
                terminal_printtermbuffer();
            } else {
                // skip all blocks
                while(memory[BLOCKCTR] > 1) {
                    sprintf(termbuffer, "Skipping blocks: %i...", memory[BLOCKCTR]-1);
                    terminal_redoline();
                    tape_read_block();
                }
                sprintf(termbuffer, "%cSkipping: %s", COL_RED, description);
                terminal_printtermbuffer();
            }
        }
        print_info("All done reading this tape.", 0);
        print_info("Swap tape to continue copying.", 0);
        print_info("", 0);
    }

    print_info("End of program.", 0);

    return 0;
}

void init(void) {
    ledbank_init(); // turn all leds off
    clear_screen();
    terminal_init(3, 20);

    sprintf(&vidmem[0x50+2], "%c%cCASSETTE-UTILITY", TEXT_DOUBLE, COL_CYAN);
    sprintf(&vidmem[0x50*22], "Version: %s", __VERSION__);
    sprintf(&vidmem[0x50*23], "Compiled at: %s / %s", __DATE__, __TIME__);
}
