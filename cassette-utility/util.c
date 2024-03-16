#include "util.h"

void printhex(uint16_t vidaddr, uint8_t val) {
    uint8_t v = (val >> 4) & 0x0F;
    
    if(v < 10) {
        vidmem[vidaddr] = v + 48;
    } else {
        vidmem[vidaddr] = v + 65 - 10;
    }

    vidaddr++;

    v = val & 0x0F;
    if(v < 10) {
        vidmem[vidaddr] = v + 48;
    } else {
        vidmem[vidaddr] = v + 65 - 10;
    }
}

/**
 * @brief Wait for key-press
 *
 */
void wait_for_key(void) {
    keymem[0x0C] = 0;
    while(keymem[0x0C] == 0) {} // wait until a key is pressed
}

/**
 * @brief Wait but check for a specific key press
 *
 */
uint8_t wait_for_key_fixed(uint8_t quitkey) {
    wait_for_key();
    if(keymem[0x00] == quitkey) {
        return 1;
    } else {
        return 0;
    }
}

void clearline(uint8_t row) {
    memset(&vidmem[row * 0x50], 0x00, 40);
}

void clear_screen(void) {
    memset(vidmem, 0x00, 0x1000);
}