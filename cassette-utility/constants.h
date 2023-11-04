#ifndef _CONSTANTS_H
#define _CONSTANTS_H

// variables for screen colors
#define COL_NONE    0x00
#define COL_RED     0x01
#define COL_GREEN   0x02
#define COL_YELLOW  0x03
#define COL_BLUE    0x04
#define COL_MAGENTA 0x05
#define COL_CYAN    0x06
#define COL_WHITE   0x07

// variables for the cassette header
#define CASSTAT    0x6017
#define TRANSFER   0x6030
#define LENGTH     0x6032
#define FILESIZE   0x6034
#define DESC1      0x6036
#define DESC2      0x6047
#define EXT        0x603E
#define FILETYPE   0x6041
#define BLOCKCTR   0x604F
#define MEMSIZE    0x605C
#define TAPE       0x0018
#define BUFFER     0x6100

#endif
