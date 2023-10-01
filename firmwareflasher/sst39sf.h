#ifndef _SST39SF_H
#define _SST39SF_H

#include <z80.h>

#define ADDR_LOW  0x60
#define ADDR_HIGH 0x61
#define ROMINT    0x62
#define ROMCHIP   0x65
#define ROMBANK   0x63

/**
 * Send a byte to the SST39SF0x0
 */
void sst39sf_send_byte(uint16_t addr, uint8_t byte);

/**
 * @brief      Receive a byte from the SST39SF0x0
 *
 * @param[in]  addr  The address
 *
 * @return     byte value
 */
uint8_t sst39sf_read_byte(uint16_t addr);

uint8_t sst39sf_read_byte_romint(uint16_t addr);

/**
 * Send a byte to internal rom
 */
void sst39sf_send_byte_romint(uint16_t addr, uint8_t byte);

/**
 * Write a byte to internal rom
 */
void sst39sf_write_byte_romint(uint16_t addr, uint8_t byte);

/**
 * @brief      Wipe sector on internal rom
 *
 * @param[in]  addr  The address
 */
void sst39sf_wipe_sector_romint(uint16_t addr);

void sst39sf_set_bank(uint8_t bank);

void sst39sf_set_bank_romint(uint8_t bank);

#endif // _SST39SF_H
