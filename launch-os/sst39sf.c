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

void sst39sf_set_bank(uint8_t bank) {
    z80_outp(ROMBANK, bank);
}