#ifndef _COPY_H
#define _COPY_H

void copyblock_ram_rom(uint16_t ramptr, uint16_t romptr) __z88dk_callee;

void copyheader_ram_rom(uint16_t ramptr, uint16_t romptr) __z88dk_callee;

#endif // _COPY_H
