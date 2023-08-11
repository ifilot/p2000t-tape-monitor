# -*- coding: utf-8 -*-

#
# Test quick calculation of header addresses
#

def main():
    blockid = int(1)
    
    h = (((blockid << 2) & 0x00FC) >> 4) & 0x000F
    l = (blockid << 6) & 0x00F0
    
    res = (h << 8) | l
    
    print('%04X' % res)

if __name__ == '__main__':
    main()