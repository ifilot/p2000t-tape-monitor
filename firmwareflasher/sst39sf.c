#include "sst39sf.h"

/**
 * Send a byte to the SST39SF0x0
 */
void sst39sf_send_byte(uint16_t addr, uint8_t byte) {
    z80_outp(ADDR_LOW, addr  & 0xFF);
    z80_outp(ADDR_HIGH, (addr >> 8) & 0xFF);
    z80_outp(ROMCHIP, byte);
}

/**
 * @brief      Receive a byte from the SST39SF0x0
 *
 * @param[in]  addr  The address
 *
 * @return     byte value
 */
uint8_t sst39sf_read_byte(uint16_t addr) {
    z80_outp(ADDR_LOW, addr  & 0xFF);
    z80_outp(ADDR_HIGH, (addr >> 8) & 0xFF);
    return z80_inp(ROMCHIP);
}

/**
 * @brief      Receive a byte from the SST39SF0x0
 *
 * @param[in]  addr  The address
 *
 * @return     byte value
 */
uint8_t sst39sf_read_byte_romint(uint16_t addr) {
    z80_outp(ADDR_LOW, addr  & 0xFF);
    z80_outp(ADDR_HIGH, (addr >> 8) & 0xFF);
    return z80_inp(ROMINT);
}

/**
 * Send a byte to internal rom
 */
void sst39sf_send_byte_romint(uint16_t addr, uint8_t byte) {
    z80_outp(ADDR_LOW, addr  & 0xFF);
    z80_outp(ADDR_HIGH, (addr >> 8) & 0xFF);
    z80_outp(ROMINT, byte);
}

/**
 * Write a byte to internal rom
 */
void sst39sf_write_byte_romint(uint16_t addr, uint8_t byte) {
    sst39sf_send_byte_romint(0x5555, 0xAA);
    sst39sf_send_byte_romint(0x2AAA, 0x55);
    sst39sf_send_byte_romint(0x5555, 0xA0);
    sst39sf_send_byte_romint(addr, byte);
}

/**
 * @brief      Wipe sector on internal rom
 *
 * @param[in]  addr  The address
 */
void sst39sf_wipe_sector_romint(uint16_t addr) {
    sst39sf_send_byte_romint(0x5555, 0xAA);
    sst39sf_send_byte_romint(0x2AAA, 0x55);
    sst39sf_send_byte_romint(0x5555, 0x80);
    sst39sf_send_byte_romint(0x5555, 0xAA);
    sst39sf_send_byte_romint(0x2AAA, 0x55);
    sst39sf_send_byte_romint(addr, 0x30);

    uint16_t attempts = 0;
    while((sst39sf_read_byte_romint(0x0000) & 0x80) != 0x80 && attempts < 1000) {
        attempts++;
    }
}

/**
 * @brief      Set the bank on the external ROM
 *
 * @param[in]  bank  The bank
 */
void sst39sf_set_bank(uint8_t bank) {
    z80_outp(ROMBANK, bank);
}

/**
 * @brief      Set the bank on the internal ROM chip
 *
 * @param[in]  bank  The bank
 */
void sst39sf_set_bank_romint(uint8_t bank) {
    z80_outp(ROMINT, bank);
}
