#ifndef _ROMCHIP_H
#define _ROMCHIP_H

#include <z80.h>
#include "constants.h"
#include "sst39sf.h"
#include "copy.h"
#include "crc16.h"
#include "leds.h"

extern uint8_t __nrbanks;

uint16_t findfreeblock(void);

uint16_t copyblock(uint8_t currentblock, uint8_t totalblocks, uint16_t prevbankblock);

void write_startbyte(uint16_t bankblock);

#endif // _ROMCHIP_H
