#ifndef _LED_H
#define _LED_H

#include <z80.h>
#include <stdint.h>

extern uint8_t __led_status;

#define LEDBANK 0x66

void led_rd_on(void);
void led_rd_off(void);

void led_wr_on(void);
void led_wr_off(void);

void ledbank_init(void);

#endif // _LED_H
