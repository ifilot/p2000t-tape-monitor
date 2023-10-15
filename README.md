# P2000T Tape Monitor

![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/ifilot/p2000t-tape-monitor?label=version)
[![build](https://github.com/ifilot/p2000t-tape-monitor/actions/workflows/build.yml/badge.svg)](https://github.com/ifilot/p2000t-tape-monitor/actions/workflows/build.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Features

This project is still under development. Below a list of features can be found.
Checked features are implemented, unchecked features are work in progress.

- [x] Launch tape files from data cartridge in SLOT2
- [ ] Write tape data to data cartridge in SLOT2
- [ ] Write data back to tapes from the data cartridge

## Explainer

In the image below, the working of the data cartridge is schematically shown.
In the conventional approach, the user would start the P2000T and load programs
from the cassette. Under the hood, data is copied from the cassette to the
internal memory after which the program can be started.

The data cartridge essentially imitates on this process. Upon boot, a bit of
firmware is loaded from the data cartridge into memory and launched. This firmware
scans the external ram chip for programs and shows a list of those programs. The
user can then select a program and execute it. Upon selection, the program is
first copied from the external chip to the internal RAM chip in the data cartridge.
Next, the firmware is removed (actually, it is simply overwritten), and the new
data is copied from the RAM chip to the same position as where normally cassette
data is copied. Finally, the `RUN` command is executed which starts the program.

![Explain how the data cartridge works](img/datacartridge_explainer.jpg)

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

## FAQ

* Where can I find programs?

  *A rather huge archive of P2000T cassette programs 
  (which is also being actively maintained), can be found in the
  [P2000T Preservation Project](https://github.com/p2000t/software) repository.*
* Where can I find the documentation?

  *All documentation can be found on the [philips-p2000t.nl](https://philips-p2000t.nl) website.*