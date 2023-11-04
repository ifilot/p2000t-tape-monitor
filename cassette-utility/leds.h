#ifndef _LED_H
#define _LED_H

#include <z80.h>
#include <stdint.h>
#include "constants.h"

extern uint8_t __led_status;

void led_rd_on(void);
void led_rd_off(void);

void led_wr_on(void);
void led_wr_off(void);

void ledbank_init(void);

#endif // _LED_H
