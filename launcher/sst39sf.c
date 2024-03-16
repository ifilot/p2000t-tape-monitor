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
 * @brief      Set the rom bank
 *
 * @param[in]  rom bank
 */
void sst39sf_set_bank(uint8_t bank) {
    z80_outp(ROMBANK, bank);
}

/**
 * @brief      Get the chip id
 *
 * @return     Chip identifier token
 */
uint16_t sst39sf_get_chip_id(void) {
    sst39sf_set_bank(0);
    sst39sf_send_byte(0x5555, 0xAA);
    sst39sf_send_byte(0x2AAA, 0x55);
    sst39sf_send_byte(0x5555, 0x90);

    uint8_t id0 = sst39sf_read_byte(0x0000);
    uint8_t id1 = sst39sf_read_byte(0x0001);

    sst39sf_send_byte(0x5555, 0xAA);
    sst39sf_send_byte(0x2AAA, 0x55);
    sst39sf_send_byte(0x5555, 0xF0);

    return id0 << 8 | id1;
}
