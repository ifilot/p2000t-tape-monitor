# Firmware Flasher

## Purpose

This SLOT1 program allows the user to copy the firmware from bank 1 on an
*external* ROM chip to the *internal* ROM chip.

## Usage

Put the firmware (`launcher-os`) on the external ROM chip and start the P2000T
with this program in SLOT1. Press any key to start the copying procedure. When
done, the copying process is validated on the basis of a checksum. You need
to verify that this checksum matches the expected checksum. The expected checksum
is provided upon compilation of `launcher-os`.
