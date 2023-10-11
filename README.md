# P2000T Tape Monitor

[![build](https://github.com/ifilot/p2000t-tape-monitor/actions/workflows/build.yml/badge.svg)](https://github.com/ifilot/p2000t-tape-monitor/actions/workflows/build.yml)

## Features
- [x] Launch tape files from data cartridge in SLOT2
- [ ] Write tape data to data cartridge in SLOT2
- [ ] Write data back to tapes from the data cartridge

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

## Files

The latest version of the files below can be obtained from the action artifacts
of the [last build](https://github.com/ifilot/p2000t-tape-monitor/actions/workflows/build.yml).

* [`BASICBOOTSTRAP.BIN`](https://nightly.link/ifilot/p2000t-tape-monitor/workflows/build/master/BASICBOOTSTRAP.BIN.zip): Modified BASIC cartridge (SLOT1)
* [`FIRMWAREFLASHER.BIN`](https://nightly.link/ifilot/p2000t-tape-monitor/workflows/build/master/FIRMWAREFLASHER.BIN): Firwmare flasher for the data cartridge firmware (SLOT1)
* [`LAUNCHER.BIN`](https://nightly.link/ifilot/p2000t-tape-monitor/workflows/build/master/LAUNCHER.BIN): Firmware for the data cartridge (SLOT2)
* [`p2000t-fat-flasher--installer-win64.exe`](https://nightly.link/ifilot/p2000t-tape-monitor/workflows/build/master/p2000t-fat-flasher-installer-win64.exe.zip): Windows installer for GUI

## File system

Data is stored on the ROM using a custom file system. Specifications of the file
system are documented [in a separate file](docs/fat.md).