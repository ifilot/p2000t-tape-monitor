#include "programs.h"
#include "sst39sf.h"
#include "ram.h"

// set pointer to video memory
__at (0x5000) char vidmem_base[];
uint16_t __nrprogs = 0;
uint8_t __nrbanks = 0;

/**
 * @brief      Read all programs from banks
 */
void read_programs(void) {
    uint16_t numprogs = 0;
    uint16_t ram_ptr = RAMADDRPROG;

    // loop over the rom banks
    led_rd_on(); // turn read led on
    for(uint8_t bank=0; bank<__nrbanks; bank++) {

        // set rom bank
        sst39sf_set_bank(bank);

        // set start position on rom bank
        uint8_t startblock = 0;
        uint16_t addr = 0x0000;

        // infinite loop until terminating byte is encountered
        while(1) {
            startblock = sst39sf_read_byte(addr++);

            // terminate loop upon reading 0xFF
            if(startblock == 0xFF) {
                break;
            }

            // build Program object
            struct Program prg;
            prg.bank = bank;
            prg.block = startblock;

            // read first 8 bytes of program name
            for(uint8_t i=0; i<8; i++) {
                prg.progname[i] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x26 + i);
            }

            // read last 8 bytes of program name
            for(uint8_t i=0; i<8; i++) {
                prg.progname[i+8] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x37 + i);
            }

            // read program extension
            for(uint8_t i=0; i<3; i++) {
                prg.extension[i] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x2E + i);
            }

            // read program size, note big endian order
            prg.size = (sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x23) << 8) +
                        sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x22);

            prg.padding = '.';

            // increment number of programs
            numprogs++;

            // write content to RAM
            for(uint16_t i=0; i<24; i++) {
                write_ram(ram_ptr++, ((char*)&prg)[i]);
            }
        }
    }
    led_rd_off(); // turn read led off
}

/**
 * @brief      Read 16 programs with respect to a given offset
 *             stores the result in external RAM.
 */
void read_programs_offset(uint16_t offset) {
    uint16_t numprogs = 0;
    uint16_t ram_ptr = RAMADDRPROG;

    // set starting bank
    uint8_t bank = 0;
    sst39sf_set_bank(bank);

    // set start positions
    uint8_t startblock = 0;
    uint16_t addr = 0x0000;

    // skip first items by offset
    led_rd_on();
    while((numprogs < offset) && (bank < __nrbanks)) {
        startblock = sst39sf_read_byte(addr++);

        // terminate loop upon reading 0xFF
        if(startblock == 0xFF) {
            // increment bank
            bank++;
            sst39sf_set_bank(bank);

            // reset start position on bank
            addr = 0x0000;

            continue;
        }

        numprogs++;
    }
    led_rd_off();

    // grab 16 programs
    led_rd_on();
    while((numprogs < (offset+16)) && (bank < __nrbanks) && numprogs < __nrprogs) {
        startblock = sst39sf_read_byte(addr++);

        // terminate loop upon reading 0xFF
        if(startblock == 0xFF) {
            bank++;

            sst39sf_set_bank(bank);
            startblock = 0;
            addr = 0x0000;

            continue;
        }

        // build Program object
        struct Program prg;
        prg.bank = bank;
        prg.block = startblock;

        // read first 8 bytes of program name
        for(uint8_t i=0; i<8; i++) {
            prg.progname[i] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x26 + i);
        }

        // read last 8 bytes of program name
        for(uint8_t i=0; i<8; i++) {
            prg.progname[i+8] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x37 + i);
        }

        // read program extension
        for(uint8_t i=0; i<3; i++) {
            prg.extension[i] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x2E + i);
        }

        // read program size
        prg.size = (sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x23) << 8) +
                    sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x22);

        prg.padding = '.';

        // increment number of programs
        numprogs++;

        // write content to RAM
        for(uint16_t i=0; i<24; i++) {
            write_ram(ram_ptr++, ((char*)&prg)[i]);
        }
    }
    led_rd_off();
}

/**
 * @brief      Get the total number of programs (files) on the chip
 *
 * @return     The number of programs.
 */
uint16_t get_number_programs(void) {
    uint16_t numprogs = 0;
    uint16_t ram_ptr = RAMADDRPROG;

    // loop over the rom banks
    led_rd_on();
    for(uint8_t bank=0; bank<__nrbanks; bank++) {

        // set rom bank
        sst39sf_set_bank(bank);

        // set start position on rom bank
        uint8_t startblock = 0;
        uint16_t addr = 0x0000;

        // infinite loop until terminating byte is encountered
        while(1) {
            startblock = sst39sf_read_byte(addr++);

            // terminate loop upon reading 0xFF
            if(startblock == 0xFF) {
                break;
            }

            numprogs++;
        }
    }
    led_rd_off();

    return numprogs;
}

/**
 * @brief      Print the programs
 *
 * @param[in]  numprogs  The numprogs
 * @param[in]  offset    The offset
 */
void print_programs(uint8_t numprogs, uint16_t offset) {
    // print header line
    clearline(2);
    char header[] = {COL_WHITE,' ','I','D',' ',
                     'N','A','M','E',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
                     'E','X','T',' ',
                     ' ','S','I','Z','E',' ',
                     'B','K',' ',
                     'B','L', 0x00};
    sprintf(&vidmem[0x50 * 2], "%s", header);

    for(uint16_t i=0; i<numprogs; i++) {

        if(offset + i >= __nrprogs) {
            break;
        }

        vidmem[(i+PRINTPROGROW)*0x50] = COL_WHITE;
        sprintf(&vidmem[(i+PRINTPROGROW)*0x50+1], "%03u", i + offset + 1);

        vidmem[(i+PRINTPROGROW)*0x50+4] = COL_YELLOW;
        for(uint8_t j=0; j<16; j++) {
            vidmem[(i+PRINTPROGROW)*0x50+j+5] = read_ram(RAMADDRPROG + i * 24 + 2 + j);
        }
        
        vidmem[(i+PRINTPROGROW)*0x50+21] = COL_CYAN;
        for(uint8_t j=0; j<3; j++) {
            vidmem[(i+PRINTPROGROW)*0x50+22+j] = read_ram(RAMADDRPROG + i * 24 + 18 + j);
        }

        // print number of bytes
        vidmem[(i+PRINTPROGROW)*0x50+25] = COL_MAGENTA;
        uint16_t size = read_ram(RAMADDRPROG + i * 24 + 22) * 256 +
                        read_ram(RAMADDRPROG + i * 24 + 21);
        sprintf(&vidmem[(i+PRINTPROGROW)*0x50+26], "%5u", size);

        // print starting bank
        vidmem[(i+PRINTPROGROW)*0x50+31] = COL_WHITE;
        printhex((i+PRINTPROGROW)*0x50+32, read_ram(RAMADDRPROG + i * 24 + 0));

        // print starting block
        vidmem[(i+PRINTPROGROW)*0x50+34] = COL_WHITE;
        printhex((i+PRINTPROGROW)*0x50+35, read_ram(RAMADDRPROG + i * 24 + 1));
    }

    clearline(19);
    vidmem[19 * 0x50] = COL_MAGENTA;
    sprintf(&vidmem[19 * 0x50+1], "Showing %u-%u of %u programs.", offset+1, offset+16, __nrprogs);
}

uint16_t build_linked_list(uint16_t progid) {
    // establish startbank and startblock of chosen program
    uint16_t bankblock = find_bankblock(progid);
    uint8_t nextblock = bankblock & 0xFF;
    uint8_t nextbank = bankblock >> 8;
    uint16_t ramptr = RAMLINKEDLIST;

    // note that prgsize is stored in big endian order on the ROM
    uint16_t prgsize = (sst39sf_read_byte(0x0100 + 0x40 * nextblock + 0x25) << 8) +
                        sst39sf_read_byte(0x0100 + 0x40 * nextblock + 0x24);

    led_rd_on();
    while(nextbank != 0xFF) {
        // write linked list to ram
        write_ram(ramptr++, nextbank);
        write_ram(ramptr++, nextblock);

        sst39sf_set_bank(nextbank);
        nextbank = sst39sf_read_byte(0x0100 + 0x40 * nextblock + 0x03);
        nextblock = sst39sf_read_byte(0x0100 + 0x40 * nextblock + 0x04);
    }

    // terminate with two 0xFF characters
    write_ram(ramptr++, 0xFF);
    write_ram(ramptr++, 0xFF);

    led_rd_off();

    return prgsize;
}

void get_progname(uint16_t progid, char* progname) {
    // establish startbank and startblock of chosen program
    uint16_t bankblock = find_bankblock(progid);
    uint8_t block = bankblock & 0xFF;
    uint8_t bank = bankblock >> 8;

    sst39sf_set_bank(bank);

    // read first 8 bytes of program name
    for(uint8_t i=0; i<8; i++) {
        progname[i] = sst39sf_read_byte(0x0100 + 0x40 * block + 0x26 + i);
    }

    // read last 8 bytes of program name
    for(uint8_t i=0; i<8; i++) {
        progname[i+8] = sst39sf_read_byte(0x0100 + 0x40 * block + 0x37 + i);
    }
}

uint16_t find_bankblock(uint16_t progid) {
    uint16_t numprogs = 0;
    uint16_t ram_ptr = RAMADDRPROG;

    // set starting bank
    uint8_t bank = 0;
    sst39sf_set_bank(bank);

    // set start positions
    uint8_t startblock = 0xFF;
    uint16_t addr = 0x0000;

    // skip first items by offset
    led_rd_on();
    while((numprogs <= progid) && (bank < __nrbanks)) {
        startblock = sst39sf_read_byte(addr++);

        // terminate loop upon reading 0xFF
        if(startblock == 0xFF) {
            // increment bank
            bank++;
            sst39sf_set_bank(bank);

            // reset start position on bank
            addr = 0x0000;

            continue;
        }

        numprogs++;
    }
    led_rd_off();

    uint8_t nextblock = startblock;
    uint8_t nextbank = bank;

    return nextbank << 8 | startblock;
}

void print_linked_list(uint8_t row) {
    clearline(row);

    uint16_t ramptr = RAMLINKEDLIST;
    uint8_t nextbank = read_ram(ramptr++);
    uint8_t nextblock = read_ram(ramptr++);
    uint8_t numblocks = 0;

    while(nextbank != 0xFF) {
        printhex(row*0x50+numblocks*5, nextbank);
        printhex(row*0x50+numblocks*5+2, nextblock);

        numblocks++;
        nextbank = read_ram(ramptr++);
        nextblock = read_ram(ramptr++);
    }
}

/**
 * @brief Copy program from external ROM to the external RAM chip in the
 *        datacartridge. Use the linked list to grab the right banks and
 *        blocks. The complete program is written to 0x0000 on the RAM chip.
 */
void copyprogramlinkedlist(void) {
    uint16_t llptr = RAMLINKEDLIST;
    uint8_t nextbank = read_ram(llptr++);
    uint8_t nextblock = read_ram(llptr++);

    // start address on ram chip for the program
    uint16_t ramptr = 0x0000;

    // block counter
    uint8_t ctr = 0;

    led_rd_on();
    while(nextbank != 0xFF) { // loop over all the blocks
        sst39sf_set_bank(nextbank);

        uint16_t romptr = 0x1000 + nextblock * 0x400;   // address on rom chip
        copyblock(ramptr, romptr);                      // assembly routine
        ramptr += 0x400;                                // go to next ram position

        vidmem[0x50*(ctr%16+4) + (ctr >= 16 ? 20 : 0)] = COL_WHITE;
        sprintf(&vidmem[0x50*(ctr%16+4) + (ctr >= 16 ? 21 : 1)], "%02X/%02X", nextbank, nextblock);

        // set indices to next bank and block
        nextbank = read_ram(llptr++);
        nextblock = read_ram(llptr++);
        ctr++;
    }
    led_rd_off();
}

void validatelinkedlist(void) {
    uint16_t llptr = RAMLINKEDLIST;
    uint8_t nextbank = read_ram(llptr++);
    uint8_t nextblock = read_ram(llptr++);

    // start address on ram chip for the program
    uint16_t ramptr = 0x0000;
    uint8_t ctr = 0;
    led_rd_on();
    while(nextbank != 0xFF) { // loop over all the blocks
        sst39sf_set_bank(nextbank);

        // read checksum from ROM chip
        uint16_t checksum = (sst39sf_read_byte(0x0100 + 0x40 * nextblock + 0x07) << 8) +
                             sst39sf_read_byte(0x0100 + 0x40 * nextblock + 0x06);

        // construct checksum from RAM chip
        uint16_t crc16 = crc16_ramchip(ramptr, 0x400);

        // perform check
        if(crc16 == checksum) {
            vidmem[0x50*(ctr%16+4) + (ctr >= 16 ? 20 : 0)] = COL_GREEN;
        } else {
            vidmem[0x50*(ctr%16+4) + (ctr >= 16 ? 20 : 0)] = COL_RED;
        }
        sprintf(&vidmem[0x50*(ctr%16+4) + (ctr >= 16 ? 21 : 1)], "%02X/%02X: %04X (%04X)", nextbank, nextblock, checksum, crc16);

        // set indices to next bank and block
        nextbank = read_ram(llptr++);
        nextblock = read_ram(llptr++);
        ramptr += 0x400;
        ctr++;
    }
    led_rd_off();
}