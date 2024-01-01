#
# Calculate the two checksums
#

import numpy as np
import argparse

def main():
    parser = argparse.ArgumentParser(prog='launcher-checksum-tester',
                                     description='Produces checksum of the launcher firmware')
    parser.add_argument('filename')
    args = parser.parse_args()

    f = open(args.filename, 'rb')
    data = bytearray(f.read())
    f.close()

    print('Reading: ', args.filename)
    print('Filesize: %i bytes' % len(data))
    data.extend(np.zeros(0x4000 - len(data)))
    print()
    print("Outputting checksums:")
    for i in range(0,2):
        checksum = crc16(data[i*0x1000:(i+1)*0x1000])
        print('%02i: %04X' % (i,checksum))

    print()
    print("First 64 bytes:")
    for i in range(8):
        for j in range(8):
            print('%02X' % data[i*8+j], end=' ' if j<7 else '\n')

def crc16(data):
    """
    Calculate CRC16 XMODEM checksum
    """
    crc = int(0)

    poly = 0x1021

    for c in data: # fetch byte
        crc ^= (c << 8) # xor into top byte
        for i in range(8): # prepare to rotate 8 bits
            crc = crc << 1 # rotate
            if crc & 0x10000:
                crc = (crc ^ poly) & 0xFFFF # xor with XMODEN polynomic

    return crc

if __name__ == '__main__':
    main()
