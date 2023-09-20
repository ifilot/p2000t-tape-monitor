;# MAIN="main.asm"
;-------------------------------------------------------------------------------
; VARIABLES
;-------------------------------------------------------------------------------
TAPE: 		equ $0018   ; address of the "tape" function
BUFFER: 	equ $9400   ; position to store tape data

; variables for command buffer
CMDSCRN:	equ $5000+23*$50+1
RSPSCRN:	equ $5000+22*$50
BLKSCRN:	equ $5000+03*$50
IFCSCRN:	equ $5000+02*$50
TITLESCRN:	equ $5000+01*$50		; start row header
IDXSCRN:	equ $5000+03*$50		; start row program index
IFCSCRN2:	equ $5000+16*$50
NUMROWS:	equ 12		; number of rows for printblock
CMDBUF:		equ $9002   ; command buffer
CMDBUFPTR:  equ $9010	; current position in command buffer
CMDSCRNPTR: equ $9012	; current screen position of command
NCMDBUF:  	equ $9014	; number of keys in command buffer
BLKIDX:  	equ $9015	; block index (current block in file)
BLOCKSIZE:  equ $60		; number of bytes in one 'page'

; program names storage locations, each program name
; gets a 16 byte area, there is a maximum capacity of 
; 32 program names
PROGNAMES:	equ $8000	; names of the programs (32 x 16 bytes)
PROGBIDX:	equ $8200	; block indices of the programs (32 bytes)
PROGLN:		equ $8220	; lengths of the programs (32 x 2 bytes)
PROGNB:		equ $8260	; number of blocks on tape for programs

VIDEO:		equ $5000	; start of video
VIDEOTEMP:  equ $8400	; address to store video screen

; LOGGING DATA
LOGSTART:	equ $8800	; address for storing log messages
LOGPOINTER: equ $8800-2 ; current position to write log messages to

; temporary storage locations
TEMP1:		equ $9100
STKTEMP:	equ $9102
TEMPDESC:	equ $9110	; store current description of CAS file
PNAMEADDR:	equ $9120
PIDXADDR:	equ $9122
PLNADDR:	equ $9124
PNBADDR:	equ $9126	; pointer to address storing number of blocks
ROMADDR:	equ $9128	; ROM chip address (first 16 bits)
ROMBANK:	equ $9129	; ROM chip block (upper 3 bits)
ROMPORT:    equ $9130	; which chip to write to
MODALSEL:	equ $9131	; current modal selection
METASTORE1: equ $9132   ; store metadata for rom chips (1 byte)
METASTORE2: equ $9134   ; store metadata for rom chips (2 bytes)
FREEBANK:	equ $9135   ; next free bank
FREEBLOCK:	equ $9136   ; next free block
MARKERADDR: equ $9138   ; rom address for storing block marker
HEADERADDR: equ $913A   ; rom address for storing cassette header
PREVBANK:	equ $913C   ; previous free bank	 (required for linked list)
PREVBLOCK:	equ $913D   ; previous free block 	 (required for linked list)
PREVMKADDR: equ $913E	; prevous marker address (required for linked list)
ROMADDRSTR: equ $9140	; start of rom address
TOTNUMBLK:  equ $9142	; total number of blocks of current tape file
ROMCHIP:	equ	$9143	; which rom chip to use (internal or external)
CHIPID:		equ $9144	; chip id
CMDPTR:		equ $9146	; command pointer
STRPTR:		equ $9148	; string pointer
CRC:		equ $9150	; used to store intermediary CRC result (2 bytes)
RAMFLAG:	equ $9152	; byte which RAM should be shown

; variables for file deletion and program monitor
CURBANK:		equ $9154	; counter to keep track of which bank we are in
CURBLOCK: 		equ $9155	; counter to keep track of which block we are in
CURBANKBLOCK:	equ $9156	; current bank and block holder in linked list
FVIDPOS:		equ $9158   ; current video position
FEXTRAMPTR:		equ $915A	; pointer to external ram address
CURSECTOR:		equ $915C	; current sector
BLOCKSUSED:		equ $915E	; count number of blocks used

; MONITOR RAM FLAG constants
RAMFLAGRAMINT: equ $00
RAMFLAGRAMEXT: equ $01
RAMFLAGROMINT: equ $02
RAMFLAGROMEXT: equ $03

; MONITOR STARTING ADDRESS LOCATIONS
MONADDR: 	equ $9160	; address for monitor (word)
EXTRAMADDR:	equ $9162	; current address in external RAM for monitor (2 bytes)
INTROMADDR:	equ $9164	; current address in internal ROM for monitor (2 bytes)
EXTROMADDR:	equ $9166	; current address in external ROM for monitor (2 bytes)
MAXFILES:	equ $9168	; how many files are on the external ROM (2 bytes)
FILESTART:	equ $916A   ; which file to look at (2 bytes)
PRGPOINTER: equ $916C	; currently selected program (2 bytes)
TEMPCURSEC: equ $916E	; temporary variable current sector

; addresses for file I/O (external RAM)
FILEBLADDR: equ $6000
FILEOPLIST:	equ $6400
FILEIOBUF:	equ $7000

; variables for keyboard interface
KEYBUF:		equ $6000	; start of key buffer
NKEYBUF:	equ $600C	; number of keys in buffer

; some special keyboard keys
KRETURN:	equ $34
KBACKSPACE: equ $2C

; screen positions for cassette data
CDCSCR:		equ $5000+17*$50+1		; status label
CTRSCR:		equ $5000+18*$50+1		;
CLSCR:		equ $5000+19*$50+1		;
CFSSCR:		equ $5000+20*$50+1		; filesize label
CEXSCR:		equ $5000+18*$50+10		; extension label
CFTSCR:		equ $5000+19*$50+10		; filetype label
BCSCR:		equ $5000+20*$50+10		; block counter label
CSSCR:		equ $5000+17*$50+20		; status label
CBISCR:		equ $5000+18*$50+20		; block index label
MSGSCR:		equ $5000+21*$50+1		; area for messages
CHIPSCR:	equ $5000+19*$50+20		; position to print chip info
CHIPCHECK:  equ CHIPSCR + 3
CBSCR:		equ $5000+20*$50+20		; position to print chip bank

; variables for cassette
CASSTAT:	equ $6017
TRANSFER:	equ $6030
LENGTH:		equ $6032
FILESIZE:	equ $6034
DESC1:		equ	$6036
DESC2:		equ $6047
EXT:		equ $603E
FILETYPE:	equ $6041
BLOCKCTR:	equ $604F
MEMSIZE:	equ $605C

; constants for cassette instructions
CAS_INIT:	equ $00
CAS_REWIND:	equ $01
CAS_SKIPF:	equ $02
CAS_SKIPB:	equ $03
CAS_EOT:	equ $04
CAS_WRITE:	equ $05
CAS_READ:	equ $06
CAS_STATUS:	equ $07

; constants for ROM instructions
O_ROM_LA:	equ $60		; rom lower address
O_ROM_UA:	equ $61		; rom upper address
O_ROM_RW:	equ $62		; rom read/write line
O_ROM_BANK:	equ $63		; rom bank (upper 3 bytes)
O_RAM_RW:	equ $64		; RAM chip
O_ROM_EXT:	equ $65		; external ROM read/write line

; color constants
COL_NONE:	equ $00
COL_RED:	equ $01
COL_GREEN:	equ $02
COL_YELLOW:	equ $03
COL_BLUE:	equ $04
COL_MAG:	equ $05
COL_CYAN:	equ $06
COL_WHITE:	equ $07

GRAPHIC_RED: equ 145

TEXT_WHITE: equ 135

CHAR_SQUARE: equ 127