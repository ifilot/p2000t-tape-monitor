#ifndef _SST39SF_H
#define _SST39SF_H

#include <z80.h>
#include "constants.h"

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

/**
 * @brief      Write a byte to external ROM
 *
 * @param[in]  addr  The address
 *
 * @return     byte value
 */
void sst39sf_write_byte(uint16_t addr, uint8_t byte);

/**
 * @brief      Read a byte from the internal rom chip
 *
 * @param[in]  addr  The address
 *
 * @return     byte value
 */
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

/**
 * @brief      Set the bank on the external ROM
 *
 * @param[in]  bank  The bank
 */
void sst39sf_set_bank(uint8_t bank);

/**
 * @brief      Set the bank on the internal ROM chip
 *
 * @param[in]  bank  The bank
 */
void sst39sf_set_bank_romint(uint8_t bank);

/**
 * @brief      Get the chip id
 *
 * @return     Chip identifier token
 */
uint16_t sst39sf_get_chip_id(void);

#endif // _SST39SF_H
