# P2000T FAT GUI

## Purpose

User-friendly way of interfacing with P2000T-FAT ROMS using the
PICO-flasher utility.

## Compilation under Linux

Ensure that all dependencies are installed

```bash
sudo apt update && sudo apt install -y qtbase5-dev qt5-qmake libqt5serialport5-dev cmake
```

Create a new build folder and compile the GUI

```
mkdir build && cd build && qmake ../gui && make -j
```