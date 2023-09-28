#!/bin/bash

# set directory of the assembler
CPATH="/d/PROGRAMMING/P2000T/assembler"

# compile custom assembly
$CPATH/tniasm.exe bootstrap.asm bootstrap.bin
$CPATH/tniasm.exe launcher.asm launcher.bin
$CPATH/tniasm.exe excode.asm excode.bin

# modify BASIC.rom
python hackrom.py

# waiting for key press to continue
read -p "Press any key to continue... " -n1 -s