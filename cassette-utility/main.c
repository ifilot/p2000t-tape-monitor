#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "sst39sf.h"
#include "memory.h"
#include "leds.h"
#include "config.h"

// forward declarations
void init(void);

int main(void) {
    init();

    return 0;
}

void init(void) {
    ledbank_init(); // turn all leds off
    sprintf(&vidmem[0x50*22], "Version: %s", __VERSION__);
    sprintf(&vidmem[0x50*23], "Compiled at: %s / %s", __DATE__, __TIME__);
}
