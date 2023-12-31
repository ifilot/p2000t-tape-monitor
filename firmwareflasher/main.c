#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "sst39sf.h"
#include "memory.h"
#include "util.h"
#include "copy.h"
#include "leds.h"
#include "config.h"

// forward declarations
void init(void);

int main(void) {
    init();

    uint8_t row = 0;
    vidmem[0x0000] = 0x06;    // cyan color
    vidmem[0x0001] = 0x0D;    // double height
    const char titlestr[] = "Datacartridge flasher";
    memcpy(&vidmem[0x0002], titlestr, strlen(titlestr));
    row += 3;

    const char msgstart[] = "Press any key to start flashing.";
    memcpy(&vidmem[row * 0x50], msgstart, strlen(msgstart));

    while(keymem[0x0C] == 0) {}

    clearline(row);
    const char copyfirmwarestr[] = "Copying firmware (8kb). Please wait...";
    memcpy(&vidmem[row * 0x50], copyfirmwarestr, strlen(copyfirmwarestr));

    sst39sf_set_bank(0);
    sst39sf_set_bank_romint(0);

    // only wipe the first two sectors as the launch-os is (by design)
    // constrainted to 0x2000 bytes
    led_wr_on();
    for(uint16_t i=0; i<2; i++) { // loop over sectors
        sst39sf_wipe_sector_romint(i * 0x1000);
    }
    led_wr_off();

    // copy external bank0 to internal rom chip
    led_wr_on();
    copyfirsttwosectors();
    led_wr_off();

    clearline(row);
    const char msgdone[] = "Completed data transfer: 8kb.";
    memcpy(&vidmem[row*0x50], msgdone, strlen(msgdone));

    row += 2;
    const char calccrc16str[] = "Calculating CRC16 checksums...";
    memcpy(&vidmem[0x50*row], calccrc16str, strlen(calccrc16str));

    // calculate CRC16
    led_rd_on();
    calculatecrc16();
    led_rd_off();

    clearline(row);
    const char crcstr[] = "CRC16 checksums:";
    memcpy(&vidmem[0x50*row], crcstr, strlen(crcstr));
    row++;
    for(uint8_t i=0; i<2; i++) {
        printhex(row*0x50+i*5, highmem9000[i*2]);
        printhex(row*0x50+i*5+2, highmem9000[i*2+1]);
    }

    row += 2;
    const char outputstr[] = "Output first 64 bytes:";
    memcpy(&vidmem[0x50*row], outputstr, strlen(outputstr));
    for(uint8_t i=0; i<8; i++) {
        row++;
        for(uint8_t j=0; j<8; j++) {
            printhex(row*0x50+j*3, sst39sf_read_byte_romint(i*8+j));
        }
    }

    row += 2;
    const char alldonestr1[] = "Flashing complete. Please carefully";
    memcpy(&vidmem[0x50*row], alldonestr1, strlen(alldonestr1));

    row++;
    const char alldonestr2[] = "verify that the checksums are correct.";
    memcpy(&vidmem[0x50*row], alldonestr2, strlen(alldonestr2));

    return 0;
}

void init(void) {
    ledbank_init(); // turn all leds off
    sprintf(&vidmem[0x50*22], "Version: %s", __VERSION__);
    sprintf(&vidmem[0x50*23], "Compiled at: %s / %s", __DATE__, __TIME__);
}
