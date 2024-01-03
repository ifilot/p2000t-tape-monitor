#include "romchip.h"

uint8_t __nrbanks = 0;

uint16_t findfreeblock(void) {
    led_rd_on();
    for(uint8_t bank = 0; bank < __nrbanks; bank++) {

        sst39sf_set_bank(bank);

        for(uint8_t block = 0; block < 60; block++) {
            if(sst39sf_read_byte(0x100 + block * 0x40 + 8) == 0xFF) {
                led_rd_off();
                return (uint16_t)bank << 8 | block;
            }
        }
    }

    led_rd_off();
    return 0xFFFF;  // return when no new block can be found
}


uint16_t copyblock(uint8_t currentblock, uint8_t totalblocks, uint16_t prevbankblock) {
    // find first free available block
    const uint16_t bankblock = findfreeblock();
    uint8_t bank = bankblock >> 8;
    uint8_t block = bankblock & 0xFF;

    // if no more blocks are available, return
    if(bank == 0xFF) {
        return 0xFFFF;
    }

    // set the bank
    sst39sf_set_bank(bank);

    // calculate and set header addr
    const uint16_t meta_addr = 0x100 + 0x40 * block;

    // start writing to chip
    led_wr_on();

    // mark block
    sst39sf_write_byte(meta_addr + 8, 0x00);

    // copy header
    copyheader_ram_rom(TRANSFER, meta_addr + 0x20);

    // copy the block
    copyblock_ram_rom(BUFFER, 0x1000 + 0x400 * block);

    // write total blocks and current block
    sst39sf_write_byte(meta_addr + 9, currentblock);
    sst39sf_write_byte(meta_addr + 10, totalblocks);

    // calculate the CRC16 checksum
    const uint16_t checksum = crc16(BUFFER, 0x400);

    // write checksum (note big endian)
    uint8_t checksum_lowbyte = checksum & 0xFF;
    uint8_t checksum_highbyte = checksum >> 8;
    sst39sf_write_byte(meta_addr + 6, checksum_lowbyte);
    sst39sf_write_byte(meta_addr + 7, checksum_highbyte);

    // if the current block is *not* the first block, also write a reference
    // from the previous block to the current one
    if(currentblock != 0) {
        uint8_t prevbank = prevbankblock >> 8;
        uint8_t prevblock = prevbankblock & 0xFF;

        sst39sf_set_bank(prevbank);
        sst39sf_write_byte(0x100 + 0x40 * prevblock + 3, bank);
        sst39sf_write_byte(0x100 + 0x40 * prevblock + 4, block);
    }

    // stop writing to chip
    led_wr_off();

    return bankblock;
}

void write_startbyte(uint16_t bankblock) {
    uint8_t bank = bankblock >> 8;
    uint8_t block = bankblock & 0xFF;

    sst39sf_set_bank(bank);

    led_rd_on();
    uint16_t romptr = 0x0000;
    while(sst39sf_read_byte(romptr) != 0xFF) {
        romptr++;
    }
    led_rd_off();

    led_wr_on();
    sst39sf_write_byte(romptr, block);
    led_wr_off();
}
