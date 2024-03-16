#ifndef _ROMCHIP_H
#define _ROMCHIP_H

#include <z80.h>
#include "constants.h"
#include "sst39sf.h"
#include "copy.h"
#include "crc16.h"
#include "leds.h"

extern uint8_t __nrbanks;

/**
 * @brief Find the first free bank and block on the ROM chip
 * 
 * @return uint16_t bank and block
 */
uint16_t findfreeblock(void);

/**
 * @brief Copy a block from internal memory to the SST39SF0x0 chip
 * 
 * @param currentblock current block number
 * @param totalblocks total number of blocks to copy
 * @param prevbankblock previous bank and block
 * @return uint16_t which bank and block on the ROM have been written to
 */
uint16_t copyblock(uint8_t currentblock, uint8_t totalblocks, uint16_t prevbankblock);

/**
 * @brief Write the start byte to the ROM chip, this byte indicates what the first
 *        block of a file is.
 * 
 * @param bankblock bank and block to write
 */
void write_startbyte(uint16_t bankblock);

#endif // _ROMCHIP_H
