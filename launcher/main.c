#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "sst39sf.h"
#include "programs.h"
#include "ram.h"
#include "memory.h"
#include "config.h"
#include "leds.h"
#include "stack.h"

// set printf io
#pragma printf "%u %X %s"

// forward declarations
void init(void);
void handle_key(uint8_t key);
uint8_t handle_keybuffer_return(void);

// store program selection keys
char keybuffer[4] = {0x00, 0x00, 0x00, 0x00};
uint8_t numkeysbuf = 0;
uint8_t flag_validation = 1; // whether to perform validation on the loaded program

void main(void) {
    init();

    // set rom bank to zero
    sst39sf_set_bank(0);

    // set rom pointer to zero
    uint16_t romptr = 0x0000;

    // read the programs on the cartridge and place the
    // contents on the cartridge RAM
    __nrprogs = get_number_programs();
    uint16_t offset = 0;
    read_programs_offset(offset);
    print_programs(16, offset);
    uint8_t exit_loop = 1;

    while(exit_loop != 0) {
        if(keymem[0x0C] > 0) {
            for(uint8_t i=0; i<keymem[0x0C]; i++) {
                switch(keymem[i]) {
                    case 25:  // 'n'
                        if(__nrprogs <= 16) { // if program size is smaller than 16, do nothing
                            break;
                        }
                        if(offset + 16 < (__nrprogs - 16)) {
                            offset += 16;
                        } else {
                            offset = __nrprogs - 16;
                        }
                        read_programs_offset(offset);
                        print_programs(16, offset);
                        break;
                    case 53: // 'p'
                        if(__nrprogs <= 16) { // if program size is smaller than 16, do nothing
                            break;
                        }
                        if(offset > 16) {
                            offset -= 16;
                        } else {
                            offset = 0;
                        }
                        read_programs_offset(offset);
                        print_programs(16, offset);
                        break;
                    case 31: // 'v'
                        flag_validation ^= 1; // toggle first bit
                        sprintf(&vidmem[0x50*20+1], "Checksum validation %s. [V]", flag_validation == 1 ? "enabled" : "disabled");
                        break;
                    case 46:
                    case 63:
                    case 4:
                    case 7:
                    case 5:
                    case 1:
                    case 6:
                    case 54:
                    case 41:
                    case 45:
                    case 44:
                        handle_key(keymem[i]);
                        break;
                    case 52: // enter
                        exit_loop = handle_keybuffer_return();
                        if(exit_loop != 0) {
                            read_programs_offset(offset);
                            print_programs(16, offset);
                        }
                        break;
                    default:
                        break;
                }
            }
            keymem[0x0C] = 0;
        }
    }
}

void handle_key(uint8_t key) {
    if(key == 44) { // backspace
        if(numkeysbuf > 0) {
            numkeysbuf--;
        }
        keybuffer[numkeysbuf] = ' ';
    } else {
        if(numkeysbuf < 3) {
            switch(key) {
                case 46:
                   keybuffer[numkeysbuf] = '1';
                   break;
                case 63:
                   keybuffer[numkeysbuf] = '2';
                   break;
                case 4:
                   keybuffer[numkeysbuf] = '3';
                   break;
                case 7:
                   keybuffer[numkeysbuf] = '4';
                   break;
                case 5:
                   keybuffer[numkeysbuf] = '5';
                   break;
                case 1:
                   keybuffer[numkeysbuf] = '6';
                   break;
                case 6:
                   keybuffer[numkeysbuf] = '7';
                   break;
                case 54:
                   keybuffer[numkeysbuf] = '8';
                   break;
                case 41:
                   keybuffer[numkeysbuf] = '9';
                   break;
                case 45:
                   keybuffer[numkeysbuf] = '0';
                   break;
            }
            numkeysbuf++;
        } else {
            return;
        }
    }
    vidmem[0x50*22+34] = COL_WHITE;
    memcpy(&vidmem[0x50*22+35], keybuffer, 3);
}

uint8_t handle_keybuffer_return(void) {
    uint16_t progid = strtoul(keybuffer, 0x00, 10);

    if(progid > 0 && progid <= __nrprogs) {

        clearscreen();
        vidmem[0x50*1] = 0x06;
        vidmem[0x50*1+1] = 0x0D;

        char progname[17];
        memset(progname, 0x00, 17);
        get_progname(progid-1, progname);
        sprintf(&vidmem[0x50*1+2], "Loading program: %s", progname);

        // write deploy location in memory
        uint16_t deploy = get_deploy_location(progid-1);
        write_ram(0x8000-4, (uint8_t)(deploy & 0xFF));
        write_ram(0x8000-3, (uint8_t)(deploy >> 8));
        sprintf(&vidmem[0x50*3], "Deploying program to: 0x%04X", deploy);

        uint16_t prgsize = build_linked_list(progid-1);
        //print_linked_list(22);
        copyprogramlinkedlist();

        // perform validation on the RAM chip
        if(flag_validation == 1) {
            validatelinkedlist();

            sprintf(&vidmem[0x50 * 23], "Press any key to start the program.");
            keymem[0x0C] = 0;
            while(keymem[0x0C] == 0) {} // wait until a key is pressed
        }

        // write number of bytes in memory, note that prgsize is stored
        // in big endian order
        write_ram(0x8000-2, (uint8_t)(prgsize & 0xFF));
        write_ram(0x8000-1, (uint8_t)(prgsize >> 8));

        return 0;

    } else {
        sprintf(&vidmem[0x50*10], "Invalid program id: %03u", progid);
    }

    // clean video buffer
    memset(keybuffer, 0x00, 3);
    memcpy(&vidmem[0x50*21+34], keybuffer, 3);
    numkeysbuf = 0;

    return 1;
}

void init(void) {
    clearscreen();
    ledbank_init();

    vidmem[0x0000] = 0x06;    // cyan color
    vidmem[0x0001] = 0x0D;    // double height

    static const char str1[] = "Launcher";
    memcpy(&vidmem[0x0002], str1, strlen(str1));

    // show debug information about BASIC locations and stack pointer
    // uint16_t basictop = memory[0x63b8] | (uint16_t)memory[0x63b9] << 8; // highest address that BASIC is allowed to use
    // uint16_t stringspace_size = memory[0x6258] | (uint16_t)memory[0x6259] << 8; // start of string space
    // sprintf(&vidmem[0x50*19], "Basic pointers: %04X / %04X / %04X", basictop, stringspace_size, get_stack_pointer());

    // show version and compile information
    vidmem[0x50*23] = COL_BLUE;
    sprintf(&vidmem[0x50*23+1], "Version %s (%s, %s)", __VERSION__, __DATE__, __TIME__);

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

    vidmem[0x50*20] = COL_MAGENTA;
    sprintf(&vidmem[0x50*20+1], "Checksum validation enabled. [v]");
    vidmem[0x50*21] = COL_BLUE;
    sprintf(&vidmem[0x50*21+1], "Press [n/p] to scroll between pages.");
    vidmem[0x50*22] = COL_BLUE;
    sprintf(&vidmem[0x50*22+1], "Select program by entering [0-9]: ");
}
