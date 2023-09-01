#include "programs.h"
#include "sst39sf.h"
#include "ram.h"

// store number of programs
uint16_t numprogs = 0;

// set pointer to video memory
__at (0x5000) char vidmem_base[];

/**
 * @brief      Read all programs from banks
 */
void read_programs(void) {
	numprogs = 0;
	uint16_t ram_ptr = 0;
	uint16_t vidmemptr = 0x50 * 10;
	for(uint8_t bank=0; bank<8; bank++) {
		sst39sf_set_bank(bank);
		uint8_t startblock = 0;
		uint16_t addr = 0x0000;
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
			for(uint8_t i=0; i<8; i++) {
				prg.progname[i] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x26 + i);
			}
			for(uint8_t i=0; i<8; i++) {
				prg.progname[i+8] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x37 + i);
			}
			for(uint8_t i=0; i<3; i++) {
				prg.extension[i] = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x2E + i);
			}
			prg.size = sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x24) + 
			           (sst39sf_read_byte(0x0100 + 0x40 * startblock + 0x25) << 8);

			numprogs++;

			for(uint16_t i=0; i<16; i++) {
				write_ram(ram_ptr++, prg.progname[i]);
			}
			for(uint16_t i=0; i<5; i++) {
				write_ram(ram_ptr++, '.');
			}
		}
	}
}