#
# Calculate the four checksums
#

import numpy as np

def main():
    f = open('main.rom', 'rb')
    data = bytearray(f.read())
    f.close()

    data.extend(np.zeros(0x4000 - len(data)))
    for i in range(0,4):
        checksum = crc16(data[i*0x1000:(i+1)*0x1000])
        print('%02i: %04X' % (i,checksum))

def crc16(data):
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
