#include "programs.h"
#include "sst39sf.h"
#include "ram.h"

// set pointer to video memory
__at (0x5000) char vidmem_base[];

/**
 * @brief      Read all programs from banks
 */
void read_programs(void) {
	uint16_t numprogs = 0;
	uint16_t ram_ptr = RAMADDRPROG;

	// loop over the rom banks
	for(uint8_t bank=0; bank<8; bank++) {

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

			// read program size
			prg.size = (sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x24) << 8) + 
			            sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x25);

			prg.padding = '.';

			// increment number of programs
			numprogs++;

			// write content to RAM 
			for(uint16_t i=0; i<24; i++) {
				write_ram(ram_ptr++, ((char*)&prg)[i]);
			}
		}
	}
}

/**
 * @brief      Read all programs from banks
 */
void read_programs_offset(uint16_t offset) {
	uint16_t numprogs = 0;
	uint16_t ram_ptr = RAMADDRPROG;
	uint8_t bank = 0;
	uint8_t startblock = 0;
	uint16_t addr = 0x0000;

	// skip first items by offset
	while((numprogs < offset) && (bank < 8)) {
		startblock = sst39sf_read_byte(addr++);

		// terminate loop upon reading 0xFF
		if(startblock == 0xFF) {
			bank++;

			sst39sf_set_bank(bank);
			startblock = 0;
			addr = 0x0000;

			continue;
		}

		numprogs++;
	}

	// grab 16 programs
	while((numprogs < (offset+16)) && (bank < 8)) {
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
		prg.size = (sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x24) << 8) + 
		            sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x25);

		prg.padding = '.';

		// increment number of programs
		numprogs++;

		// write content to RAM 
		for(uint16_t i=0; i<24; i++) {
			write_ram(ram_ptr++, ((char*)&prg)[i]);
		}
	}
}

void print_programs(uint8_t numprogs) {
	for(uint16_t i=0; i<numprogs; i++) {
        for(uint8_t j=0; j<16; j++) {
            vidmem[i*0x50+j] = read_ram(RAMADDRPROG + i * 24 + 2 + j);
        }
        
        vidmem[i*0x50+16] = ' ';
        
        for(uint8_t j=0; j<3; j++) {
            vidmem[i*0x50+17+j] = read_ram(RAMADDRPROG + i * 24 + 18 + j);
        }

        // print number of bytes
        printhex(i*0x50+21, read_ram(RAMADDRPROG + i * 24 + 21));
        printhex(i*0x50+23, read_ram(RAMADDRPROG + i * 24 + 22));

        // print starting bank
        printhex(i*0x50+26, read_ram(RAMADDRPROG + i * 24 + 0));

        // print starting block
        printhex(i*0x50+29, read_ram(RAMADDRPROG + i * 24 + 1));
    }
}