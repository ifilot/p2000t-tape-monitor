// set various memory locations

__at(0x0000) char MEMORY[];
char* memory = MEMORY;

__at (0x5000) char VIDMEM[];
char* vidmem = VIDMEM;

__at (0x6000) char KEYMEM[];
char* keymem = KEYMEM;
