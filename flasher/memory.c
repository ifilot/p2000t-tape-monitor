// set video memory
__at (0x5000) char VIDMEM[];
char* vidmem = VIDMEM;

__at (0x6000) char KEYMEM[];
char* keymem = KEYMEM;

__at (0x9000) char HIGHMEM9000[];
char* highmem9000 = HIGHMEM9000;
