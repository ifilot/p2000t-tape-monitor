# P2000T Tape Monitor

## Purposes
- [x] Launch tape files from data cartridge in SLOT2
- [ ] Write tape data to data cartridge in SLOT2

## Contents
This repository is organized as follows

* `basicmod`: Modified BASIC ROM. This ROM is needed for the cartridge in SLOT1.
* `cases`: Enclosures for the data cartridge
* `docs`: Technical documentation; mainly needed for development
* `firmwareflasher`: SLOT1 program to transfer launch-os from external ROM chip
  on the data cartridge to the internal ROM.
* `gui`: GUI to add and delete programs from the data cartridge and to format a
  chip.
* `pcb`: PCBs for the SLOT2 datacartridge.
* `src`: Source files for the SLOT1 program "tape monitor" that can be used to
  transfer tapes to the external rom. **This program is still in development,
  use at your own risk.**

## File system

Data is stored on the ROM using a custom file system. Specifications of the file
system are documented [in a separate file](docs/fat.md).