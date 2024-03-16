#ifndef _UTIL_H
#define _UTIL_H

#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "memory.h"

void printhex(uint16_t, uint8_t);
void clearline(uint8_t);
void wait_for_key(void);
uint8_t wait_for_key_fixed(uint8_t quitkey);
void clearscreen(void);
void clear_screen(void);

#endif
