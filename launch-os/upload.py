#
# Quick upload method to development cartridge
#

import numpy as np
import serial
import serial.tools.list_ports

def main():
    ser = connect()
    test_board_id(ser)
    upload_rom(ser, 'main.rom')
    ser.close()

def connect():
    # autofind any available boards
    ports = serial.tools.list_ports.comports()
    portfound = None
    for port in ports:
        if port.pid == 0x0A and port.vid == 0x2E8A:
            portfound = port.device
            break

    # specify the COM port below
    if portfound:
        ser = serial.Serial(portfound, 
                            19200, 
                            bytesize=serial.EIGHTBITS,
                            parity=serial.PARITY_NONE,
                            stopbits=serial.STOPBITS_ONE,
                            timeout=None)  # open serial port
                   
        if not ser.isOpen():
            ser.open()
    
    return ser

def test_board_id(ser):
    """
    Test reading board id
    """
    ser.write(b'READINFO')
    rsp = ser.read(8)
    rsp = ser.read(16)
    print(rsp)

def upload_rom(ser, filename):
    ser.write(b'DEVIDSST')
    rsp = ser.read(8)
    rsp = ser.read(2)
    if rsp[0] == 0xBF and rsp[1] in [0xB5, 0xB6, 0xB7]:
        print('Chip ID verified: %s' % rsp)
    else:
        raise Exception("Incorrect chip id.")
        
    f = open(filename, 'rb')
    data = bytearray(f.read())
    f.close()
    
    # wipe first bank
    for i in range(0,4):
        ser.write(b'ESST00%02X' % (i * 0x10))
        res = ser.read(8)
        print(res)
        res = ser.read(2)
        print(res)
    
    # expand data to 4k-size
    data.extend(np.zeros(0x4000 - len(data)))
    
    for i in range(0,4):
        ser.write(b'WRSECT%02X' % i)
        res = ser.read(8)
        print(res)
        parcel = data[i*0x1000:(i+1)*0x1000]
        ser.write(parcel)
        crc16checksum = np.uint16(ser.read(2)[0])
        print('%04X' % crc16checksum)

if __name__ == '__main__':
    main()
