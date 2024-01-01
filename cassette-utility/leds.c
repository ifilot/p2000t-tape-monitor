#include "leds.h"

uint8_t __led_status = 0;

void led_rd_on(void) {
    __led_status |= (1 << 0);
    z80_outp(LEDBANK, __led_status);
}

void led_rd_off(void) {
    __led_status &= ~(1 << 0);
    z80_outp(LEDBANK, __led_status);
}

void led_wr_on(void) {
    __led_status |= (1 << 1);
    z80_outp(LEDBANK, __led_status);
}

void led_wr_off(void) {
    __led_status &= ~(1 << 1);
    z80_outp(LEDBANK, __led_status);
}

void ledbank_init(void) {
    __led_status = 0x00;
    z80_outp(LEDBANK, __led_status);
}
