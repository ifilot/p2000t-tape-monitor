;-------------------------------------------------------------------------------
; "tapemon.asm"
;-------------------------------------------------------------------------------
;
; Tape Monitor Program
;
; Author: Ivo Filot / ivo@ivofilot.nl
;-------------------------------------------------------------------------------

include "constants.asm"

;-------------------------------------------------------------------------------
; Initialization routine
;-------------------------------------------------------------------------------
	org $1000

	; signature, byte count, checksum
	DB $5E,00h,00h,00h,00h

	; name of the cartridge (11 bytes)
	DB "TAPEMONITOR"

	; start program
	jp start

;-------------------------------------------------------------------------------
; start of program
;-------------------------------------------------------------------------------
start:
	call init
	jp loop

;-------------------------------------------------------------------------------
; initialization routine
;-------------------------------------------------------------------------------
init:
	;call initlog
	call clearscreen
	call clearcmd
	call prttitle
	ld hl,BUFFER
	ld (MONADDR),hl
	call printblock
	call prttapedata
	call resetarchivepointers
	call sst39checkchip
	ld a,0						; set rombank to 0
	call setrombank
	ld hl,0						; set rom address to 0
	ld (ROMADDR),hl
	ld (EXRAMADDR),hl			; set external ram address to 0
	ld a,0						; point monitor to internal RAM
	ld (RAMFLAG),a
	ld a,$FF
	ld (FREEBANK),a
	ld (FREEBLOCK),a
	call cmdversion
	ret

;-------------------------------------------------------------------------------
; infinite loop routine
;-------------------------------------------------------------------------------
loop:
	call getkey
	jp loop

;-------------------------------------------------------------------------------
; Parse command instructions
;
; Note that from here, the programs jumps to the specific function and that
; functions then performs the return from call
;-------------------------------------------------------------------------------
parsecmd:
	ld (STKTEMP),sp			; store stack pointer
;-------------------------------------------------------------------------------
; loop over commands and verify if the command buffer matches the command
; instruction, if so, load the address pointed to by ix into hl and jump
; to the function
;-------------------------------------------------------------------------------
	ld hl,.strptrs			; pointer to start of array of string pointers
	ld ix,.cmdptrs			; pointer to start of array of function pointers
	ld iy,.cmdlengths		; pointer to array of string lengths
	ld b,.NUMCMDS			; number of commands
.nextcmd:
	push hl
	push bc
	ld c,(iy)				; load length of string
	ld de,CMDBUF			; set pointer to command buffer
	call cpstring			; compare string, garbles bc,de,hl
	pop bc
	pop hl
	cp 0
	jp z,.launchfunc		; if match, jump to address pointed by (ix)
	ld d,0
	ld e,(iy)
	add hl,de
	inc hl					; move string pointer to start of next string
	inc iy					; next length of string
	inc ix
	inc ix					; next function pointer
	dec b					; decrement counter
	jp nz,.nextcmd
	jp .singlebyte
.launchfunc:
	; --- uncomment the lines below for debugging
	;ld de,$5000 + 22 * $50 + 20
	;ld a,(ix+1)
	;call printhex
	;ld a,(ix)
	;call printhex
	; ---
	ld l,(ix)
	ld h,(ix+1)				; load memory value pointed to by ix into hl
	jp (hl)
;-------------------------------------------------------------------------------
; single byte/character instructions
;-------------------------------------------------------------------------------
.singlebyte:
	ld de,CMDBUF
	ld a,(de)
	cp 'w'					; rewind tape
	jp z,cmdrewind
	cp 'W'					; rewind tape
	jp z,cmdrewind
	cp 'i'					; index tape
	jp z,cmdindex
	cp 'I'					; index tape
	jp z,cmdindex
	cp 'r'					; read instruction
	jp z,cmdreadmon
	cp 'R'					; read instruction
	jp z,cmdreadmon
	cp 'L'  				; read block from tape
	jp z,cmdreadblocktape
	cp 'l'  				; read block from tape
	jp z,cmdreadblocktape
	cp 'n'  				; forward $60 bytes in monitor
	jp z,cmdnext
	cp 'p'  				; reverse $60 bytes in monitor
	jp z,cmdprev
	cp 'P'  				; print the archive
	jp z,prtarchive
	ld hl,.msgunknown		; print unknown command warning
	ld de,RSPSCRN
	call printstring
	ret

;-------------------------------------------------------------------------------
; command instructions
;
; When a command is submitted by the user, the program will parse through this
; list and see if a string matches. If so, the corresponding subroutine
; corresponding to the command label is called.
;-------------------------------------------------------------------------------
.NUMCMDS:		equ .cmdptrs - .cmdlengths

.strptrs:
.strcopyram:	DB "copyram",255
.strcopybuf:	DB "copybuf",255
.strcopy:		DB "copy",255
.strshowboot:	DB "showboot",255
.strbootload:	DB "bootload",255
.strchip:   	DB "chip",255
.strmodal:		DB "modal",255
.strformat:		DB "format",255
.strfindblk:	DB "findblk",255
.strversion:	DB "version",255
.strsetramint:	DB "sri",255
.strsetramext:	DB "sre",255
.strstairram:	DB "srs",255
.strlist:		DB "list",255

.cmdlengths: 	DB 7,7,4,8,8,4,5,6,7,7,3,3,3,4

.cmdptrs:		DW cmdcopyram
				DW cmdcopybuf
				DW cmdcopy
				DW cmdshowboot
				DW cmdbootload
				DW sst39checkchip
				DW cmdmodal
				DW cmdformat
				DW cmdfindblk
				DW cmdversion
				DW cmdsri
				DW cmdsre
				DW cmdstairram
				DW cmdlist

.msgunknown: 	DB 3,"Unknown command",0,255

;-------------------------------------------------------------------------------
; Show a modal test window on the screen
;-------------------------------------------------------------------------------
cmdmodal:
	ld hl,.strconfirm1
	ld de,.strconfirm2
	call confirmmodal
	ret

.strconfirm1: DB "Are you sure you would",255
.strconfirm2: DB "like to continue? (y/n)",255

;-------------------------------------------------------------------------------
; Show a modal test window on the screen
;-------------------------------------------------------------------------------
cmdversion:
	ld hl,.message
	call printmessage
	ret

.message: DB "TAPEMONITOR v.0.1.0.1",255

;-------------------------------------------------------------------------------
; Set monitor to internal RAM
;-------------------------------------------------------------------------------
cmdsri:
	ld a,0
	ld (RAMFLAG),a
	ld hl,.message
	call printmessage
	call printblock
	ret

.message: DB "Monitor set to *INTERNAL* RAM",255

;-------------------------------------------------------------------------------
; Set monitor to external RAM
;-------------------------------------------------------------------------------
cmdsre:
	ld a,1
	ld (RAMFLAG),a
	ld hl,.message
	call printmessage
	call printblock
	ret

.message: DB "Monitor set to *EXTERNAL* RAM",255

;-------------------------------------------------------------------------------
; Set incrementing values for addresses in RAM
;-------------------------------------------------------------------------------
cmdstairram:
	ld hl,.message
	call printmessage
	call stairram
	call cleanmessage
	ld hl,.msgdone
	call printmessage
	ret

.message: DB "Performing stair-ram test...",255
.msgdone: DB "Done stair-ram test.",255

;-------------------------------------------------------------------------------
; Copy program metadata from external ROM to external RAM, such that it can
; be easily displayed.
;
;
;-------------------------------------------------------------------------------
cmdlist:
	call copyprogblocks
	call copydesceroera
	call copyfileext
	call copyfilelengths
	call showfiles
	ret

;-------------------------------------------------------------------------------
; Find the next free block on external ROM chip
;-------------------------------------------------------------------------------
cmdfindblk:
	call findfreeblock
	ret

;-------------------------------------------------------------------------------
; Copy current buffer to ROM chip
; 
; !! THIS FUNCTION NEEDS TO BE REMOVED !!
;-------------------------------------------------------------------------------
cmdcopybuf:
	ld a,O_ROM_EXT			; set external rom chip
	ld (ROMPORT),a
	ld hl,.message
	call printmessage
	push de					; store screen address on stack
	call findfreeblock		; load first free block and bank in bc
	call calcromaddr		; calculate rom address in de
	call calcmetaaddr		; calculate header storage address
	pop de
	call printromaddr		; print rom address
	push de
	;call copyramromlog		; store data in log
	call markblock			; indicate that this block has been used
	call copyheader
	call copyblock			; copy block from RAM to ROM
	pop de					; recall screen address
	ld a,'-'
	ld (de),a
	inc de
	call printromaddr
	ret

.message: DB "Copy current buffer to ROM:",255

;-------------------------------------------------------------------------------
; Copy $400 bytes from RAM to $9400 and display it
;-------------------------------------------------------------------------------
cmdcopyram:
	call cleanmessage	; clean message
	ld hl,.message		; inform user on operation
	call printmessage
	ld bc,$400			; set counter (1kb)
	ld hl,BUFFER		; set destination address
	ld de,0 			; set ram chip address
.nextbyte:
	call ramrecvde		; load character from external ram (set by de) into a
	ld (hl),a			; put a into memory
	inc de				; increment external ram memory address
	inc hl				; increment internal ram memory address
	dec bc				; decrement rounter
	ld a,c
	or b				; check if counter reached zero
	jr nz,.nextbyte		; if not, next byte
	ld hl,BUFFER   		; put BUFFER address into hl
	ld (MONADDR),hl		; use buffer address as monitor address
	call printblock		; show buffer in monitor
	ret

.message: DB "Copying current RAM buffer.",255

;-------------------------------------------------------------------------------
; Copy $400 bytes from bank 7 of internal rom (boot record) to $9400 
; and display it
;-------------------------------------------------------------------------------
cmdshowboot:
	call cleanmessage
	ld hl,.message
	call printmessage
	ld bc,$400
	ld hl,BUFFER		; set destination address
	ld de,0 			; set ram chip address
	ld a,7				; set bank 7
	out (O_ROM_BANK),a
.nextbyte:
	push bc
	ld c,O_ROM_RW
	call sst39sfrecv
	pop bc
	ld (hl),a
	inc de
	inc hl
	dec bc
	ld a,c
	or b 
	jp nz,.nextbyte
	ld hl,BUFFER   		; load monitor address from RAM
	ld (MONADDR),hl
	call printblock
	ret

.message: DB "Copying boot sector to $9400",255

;-------------------------------------------------------------------------------
; Change monitor address and read from that address
; Uses: all registers
;-------------------------------------------------------------------------------
cmdreadmon:
	ld a,(NCMDBUF)
	cp 5
	jp c,cmderror
	inc de			; get second character
	ld a,(de)
	ld b,a			; store into b
	inc de			; get third character
	ld a,(de)	
	ld c,a			; store into c
	push bc
	call atoi		; convert to int, store in a
	pop bc
	push af
	or b
	or c
	jp z,cmderror	; check for errors
	pop af
	ld (TEMP1),a	; store upper address
	inc de			; get fourth character
	ld a,(de)
	ld b,a			; store into b
	inc de			; get fifth character
	ld a,(de)	
	ld c,a			; store into c
	push bc
	call atoi		; convert to int, store in a
	pop bc
	push af
	or b
	or c
	jp z,cmderror	; check for errors
	pop af
	ld l,a
	ld a,(TEMP1)
	ld h,a			; address is not set in hl
	ld a,(RAMFLAG)	; read RAM flag
	cp 0
	jr nz,.setexramaddr
	ld (MONADDR),hl
	jr .end
.setexramaddr:
	ld (EXRAMADDR),hl
.end:
	call printblock
	ret

;-------------------------------------------------------------------------------
; Perform a complete copy of the cassette to the ROM chip.
; Uses: all registers
;-------------------------------------------------------------------------------
cmdcopy:
	ld hl,0
	ld (ROMADDR),hl
	call sst39checkchip			; check whether chip is present
	ld a,(CHIPCHECK)			; load chip character from video ram
	cp 'S'						; check if S
	jp nz,.askforce				; throw error when no chip
.force:
	call taperewind
	call resetarchive
.nextfile:
	call tapesingleblock
	ld a,(CASSTAT)				; check for errors
	cp 0
	jp nz,prtarchive			; stop on error
	call prttapedata
	call storeprogdata			; store program data
	call prtarchive				; print program archive
	call copyramrom				; copy to ROM chip
	ld a,(BLOCKCTR)
	cp 1						; check if one-block program
	jp z,.nextfile				; immediately go back
.nextblock:
	call tapesingleblock
	call prttapedata
	ld a,(CASSTAT)				; check for errors
	cp 0
	jp nz,prtarchive			; stop on error
	call copyramrom				; copy block from system RAM to ROM
	ld a,(BLOCKCTR)				; get number of blocks
	ld b,a
	dec b
	ld a,b
	cp 0						; check whether this is the last block
	jp nz,.nextblock
	jp .nextfile
	ret
.askforce:
	ld hl,.strconfirm1
	ld de,.strconfirm2
	call confirmmodal
	cp 0
	jp z,.force
.cancel:
	call cleanmessage
	ld hl,.strcancel
	call printmessage
	ret

.strconfirm1: DB "Invalid chip ID read!",255
.strconfirm2: DB "Force operation? (y/n)",255
.strcancel:   DB "Copy operation cancelled.",255

;-------------------------------------------------------------------------------
; Copy a bank from the external chip to bank 7 of the internal ROM chip. The
; user is being asked which bank to copy from
;-------------------------------------------------------------------------------
cmdbootload:
	ld hl,.banksel0
	ld de,.banksel1
	call selectbankmodal	; returns bank in a
	ld (ROMBANK),a			; set bank id from modal
	cp 8					; check if cancelled
	jp nz,.exec				; go to exit if so
.cancel:
	call cleanmessage
	ld hl,.cancelmsg
	call printmessage
	ret	
.exec:
	ld hl,.strconfirm1
	ld de,.strconfirm2
	call confirmmodal
	cp 0
	jp z,.proceed
	jp .cancel
.proceed:
	ld hl,.strwaitmsg
	call printmessage
	ld a,(ROMBANK)
	call printhex
	ld hl,.strdots
	call printstring		; inform user which bank to read from
	ld a,O_ROM_EXT
	di
	ld (ROMCHIP),a			; set external chip to read from
	ld de,0					; start address of copy instruction
	ld hl,$4000				; number of bytes to copy
	call ramrinse
	call ramrinse
	call copybank_rora
	;---
	;ex de,hl
	;ld de,$5000 + $50 * 22 + 20
	;ld a,h
	;call printhex
	;ld a,l
	;call printhex
	;---
	ld a,7					; set rom bank
	ld (ROMBANK),a
	ld a,O_ROM_RW			; set internal rom
	ld (ROMCHIP),a
	ld c,a
	call sst39erase64kb		; format bank 7
	ld de,0					; start destination address of copy instruction
	ld hl,$4000				; number of bytes to copy
	call copybank_raro		; copy from ram chip to internal rom chip
	ei
	call cleanmessage
	ld hl,.strdone
	call printmessage
	ret

.banksel0: DB "Please select bank <0-7>.",255
.banksel1: DB "Hit <8> to cancel.",255
.cancelmsg: DB "Operation cancelled",255
.strconfirm1: DB "OK overwriting bank 7?",255
.strconfirm2: DB "Continue? (y/n)",255
.strwaitmsg: DB "Copying data from bank ",255
.strdots: DB "...",255
.strdone: DB "Done copying bootloader!",255

;-------------------------------------------------------------------------------
; Format the ROM chip
;-------------------------------------------------------------------------------
cmdformat:
	ld hl,.strconfirm1
	ld de,.strconfirm2
	call confirmmodal
	cp 0
	jp nz,cmdcancel
	ld hl,0
	ld (ROMADDR),hl
	call sst39checkchip			; check whether chip is present
	ld a,(CHIPCHECK)			; load chip character
	cp 'S'						; check if S
	jp nz,.askforce				; throw error when no chip
.force:
	ld a,O_ROM_EXT
	ld (ROMCHIP),a
	call format
	call cleanmessage
	ld hl,.msg
	call printmessage
	ret
.askforce:
	ld hl,cmdcopy.strconfirm1
	ld de,cmdcopy.strconfirm2
	call confirmmodal
	cp 0
	jp z,.force
	jp cmdcancel

.strconfirm1: DB "All data will be lost!",255
.strconfirm2: DB "Continue? (y/n)",255
.msg:		  DB "Chip formatted.",255

;-------------------------------------------------------------------------------
; Copy cartridge header ($40 bytes) and part in BUFFER RAM ($400 bytes) to ROM.
; Uses first free available rom block as storage location.
;
; Sets the following variables in memory:
; FREEBANK		- next free bank
; FREEBLOCK		- next free block
; MARKERADDR	- rom address for storing block marker
; HEADERADDR	- rom address for storing cassette header
;-------------------------------------------------------------------------------
copyramrom:
	ld a,O_ROM_EXT			; set external rom chip
	ld (ROMPORT),a
	ld hl,.message
	call printmessage
	push de					; store screen address on stack
	call findfreeblock		; load first free block and bank in bc
	call prtrombank			; show current rom bank
	call calcromaddr		; calculate rom address in de
	call calcmetaaddr		; calculate header storage address
	pop de
	call printromaddr		; print rom address
	push de
	;call copyramromlog		; store data in log
	di
	call markblock          ; mark that the block is used
	call copyheader         ; copy header from RAM to ROM
	call copyblock			; copy block from RAM to ROM
	call calcchecksum		; calculate the checksum from memory
	call writechecksum		; write a two byte checksum of the rom data
	call setlinkedlist      ; set this block as the next element in the l-list
	ei
	pop de					; recall screen address
	ld a,'-'
	ld (de),a
	inc de
	call printromaddr
	ret

.message: DB "Copy datablock to ROM:",255

;-------------------------------------------------------------------------------
; print rom address
; input: de - screen address
;  uses: a,bc,de,hl
;-------------------------------------------------------------------------------
printromaddr:
	ld a,'$'
	ld (de),a
	inc de
	ld hl,(ROMADDR)
	ld a,h
	call printhex
	ld a,l
	call printhex
	ret

;-------------------------------------------------------------------------------
; Show next block in monitor
; Uses: de,hl
;-------------------------------------------------------------------------------
cmdnext:
	ld hl,(MONADDR)
	ld de,BLOCKSIZE
	add hl,de
	ld (MONADDR),hl
	call printblock
	ret

;-------------------------------------------------------------------------------
; Show previous block in monitor
; Uses: de,hl
;-------------------------------------------------------------------------------
cmdprev:
	ld hl,(MONADDR)
	ld de,BLOCKSIZE
	or a					; reset carry flag
	sbc hl,de
	ld (MONADDR),hl
	call printblock
	ret

;-------------------------------------------------------------------------------
; Show next block in monitor
;-------------------------------------------------------------------------------
cmdrewind:
	call taperewind
	call prttapedata
	ret

;-------------------------------------------------------------------------------
; Read block from tape
;-------------------------------------------------------------------------------
cmdreadblocktape:
	call tapesingleblock
	call prttapedata
	ld hl,BUFFER
	ld (MONADDR),hl
	call printblock
	ret

;-------------------------------------------------------------------------------
; Index tape
;-------------------------------------------------------------------------------
cmdindex:
	call taperewind
	call resetarchive
cisnewprog:
	call tapesingleblock
	ld a,(CASSTAT)
	cp 0
	jp nz,prtarchive			; stop on error
	call prttapedata
	call storeprogdata			; list this program
	call prtarchive				; print the archive
	ld a,(BLOCKCTR)
	cp 1						; check is one-block program
	jp z,cisnewprog				; immediately go back
ciskipblk:
	call tapesingleblock
	call prttapedata
	ld a,(CASSTAT)			; check for errors
	cp 0
	jp nz,prtarchive		; stop on error
	ld a,(BLOCKCTR)			; get number of blocks
	ld b,a
	dec b
	ld a,b
	cp 0					; check whether this is the last block
	jp nz,ciskipblk
	jp cisnewprog

;-------------------------------------------------------------------------------
; Invalid command routine
;-------------------------------------------------------------------------------
cmderror:
	ld de,RSPSCRN
	ld hl,.msg
	call printstring
	ret

.msg: DB COL_RED,"ERROR",0,255

;-------------------------------------------------------------------------------
; Invalid command routine
;-------------------------------------------------------------------------------
cmdcancel:
	ld de,RSPSCRN
	ld hl,.msg
	call printstring
	ret

.msg: DB COL_BLUE,"OPERATION CANCELLED",0,255

;-------------------------------------------------------------------------------
; print all tape data
;-------------------------------------------------------------------------------
prttapedata:
	call prttransfer
	call prtlength
	call prtfilesize
	call prtdescriptor
	call prtext
	call prtfiletype
	call prtblockctr
	call prtstatus
	call prtblockidx
	ret

;-------------------------------------------------------------------------------
; print filename descriptor (basically the filename) to the screen
; Uses: a,bc,de,hl (all)
;-------------------------------------------------------------------------------
prtdescriptor:
	ld a,'D'
	ld de,CDCSCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld bc,8
	ld hl,DESC1
	ldir
	ld hl,DESC2
	ld bc,8
	ldir
	ret

;-------------------------------------------------------------------------------
; print transfer address
; Uses: a,bc,de,hl (all)
;-------------------------------------------------------------------------------
prttransfer:
	ld a,'T'
	ld de,CTRSCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld a,'$'
	ld (de),a
	inc de
	ld hl,(TRANSFER)
	call prtword
	ret

;-------------------------------------------------------------------------------
; print length
; Uses: a,bc,de,hl (all)
;-------------------------------------------------------------------------------
prtlength:
	ld a,'L'
	ld de,CLSCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld a,'$'
	ld (de),a
	inc de
	ld hl,(LENGTH)
	call prtword
	ret

;-------------------------------------------------------------------------------
; print filesize
; Uses: a,bc,de,hl (all)
;-------------------------------------------------------------------------------
prtfilesize:
	ld a,'F'
	ld de,CFSSCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld a,'$'
	ld (de),a
	inc de
	ld hl,(FILESIZE)
	call prtword
	ret

;-------------------------------------------------------------------------------
; print the filename extension
; Uses: a,bc,de,hl (all)
;-------------------------------------------------------------------------------
prtext:
	ld a,'E'
	ld de,CEXSCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld hl,EXT
	ld bc,3
	ldir
	ret

;-------------------------------------------------------------------------------
; print the file type
; uses: a,b,de
;-------------------------------------------------------------------------------
prtfiletype:
	ld a,'F'
	ld de,CFTSCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld a,'$'
	ld (de),a
	inc de
	ld a,(FILETYPE)
	call printhex
	ret

;-------------------------------------------------------------------------------
; print block counter
; this counter indicates the total number of blocks
; for the current file
;-------------------------------------------------------------------------------
prtblockctr:
	ld a,'B'
	ld de,BCSCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld a,(BLOCKCTR)
	call printdec
	ret

;-------------------------------------------------------------------------------
; print block index label
;-------------------------------------------------------------------------------
prtblockidx:
	ld a,'I'
	ld de,CBISCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld a,(BLKIDX)
	call printdec
	ret

;-------------------------------------------------------------------------------
; print cassette status
;-------------------------------------------------------------------------------
prtstatus:
	ld de,CSSCR
	ld hl,.text
	call printstring
	ld a,(CASSTAT)
	ld (hl),a
	ret

.text: DB "Status:",255

;-------------------------------------------------------------------------------
; print data word
; input: hl - data word
; uses: a + registers of printhex
;-------------------------------------------------------------------------------
prtword:
	ld a,h
	call printhex
	ld a,l
	call printhex
	ret

;-------------------------------------------------------------------------------
; print rom bank
;-------------------------------------------------------------------------------
prtrombank:
	ld de,CBSCR
	ld a,'R'
	ld (de),a
	inc de
	ld a,'B'
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	inc de
	ld a,(ROMBANK)
	call printhex
	ret

;-------------------------------------------------------------------------------
; print the archive
;-------------------------------------------------------------------------------
prtarchive:
	call clearinterface
	call resetarchivepointers
	ld de,IDXSCRN+1 		; set initial video address
	push de
.nextprog:
	ld hl,(PIDXADDR)		; load block idx
	ld a,(hl)
	call printdec			; print idx
	inc hl
	ld (PIDXADDR),hl		; store pointer
	ld a,":"
	ld (de),a
	inc de
	ld a," "
	ld (de),a
	inc de					; increment video address
	ld hl,(PNAMEADDR)		; set source address
	ld bc,16				; set length
	ldir					; copy program name
	ld (PNAMEADDR),hl		; store pointer
	ld a,COL_YELLOW			; change color
	ld (de),a
	inc de					; advance screen position
	ld a,'$'
	ld (de),a
	inc de
	ld hl,(PLNADDR)			; load program length address
	inc hl					; move to upper byte
	ld a,(hl)
	call printhex			; print upper byte program length
	dec hl					; move to lower byte
	ld a,(hl)
	call printhex			; print lower byte program length
	inc hl
	inc hl
	ld (PLNADDR),hl			; store pointer
	ld a,COL_CYAN			; change color
	ld (de),a
	inc de					; advance screen position
	ld a,'$'
	ld (de),a
	ld hl,(PNBADDR)			; load address nr blocks
	ld a,(hl)
	inc de					; advance screen position
	call printhex			; print number of program blocks
	inc hl					; next nr blocks addr
	ld (PNBADDR),hl			; store pointer
	pop de					; get initial screen position
	ld a,(hl)				; load number of blocks of next file
	cp 0					; check if this is zero (end of files)
	ret z					; stop when next block is zero
	ex de,hl				; load video address in hl
	ld de,$50				; prepare to add $50 to video address
	add hl,de				; go to next line on screen
	push hl
	ex de,hl				; set video address back in de
	jp .nextprog			; go to next program

;-------------------------------------------------------------------------------
; print title
;-------------------------------------------------------------------------------
prttitle:
	ld hl,.title
	ld de,TITLESCRN
	call printstring
	ld a,COL_CYAN
	ld (IFCSCRN2),a
	ld a,127
	ld de,IFCSCRN2+1
	ld (de),a
	ld hl,IFCSCRN2+1
	inc de
	ld bc,37
	ldir
	ret

.title:	DB COL_CYAN,150,127,127,127,127,127,127
		DB 127,127,127,127,127,00
		DB "TAPE MONITOR"
		DB 00,127,127,127,127,127
		DB 127,127,127,127,127,127,127,255

;-------------------------------------------------------------------------------
; get key from keyboard buffer
;-------------------------------------------------------------------------------
getkey:
	ld a,(NKEYBUF)
	cp 0
	ret z
	ld b,a				; number of keys
	ld de,KEYBUF
nextkey:
	ld a,(de)			; load key from buffer
	cp KRETURN			; check for enter
	jp z,keyenter
	cp KBACKSPACE		; check for enter
	jp z,keybackspace
	cp 144
	jp nc,getkeycont
	call keytoascii		; convert key to ascii
	call storekey
getkeycont:
	inc de				; next position in key buffer
	dec b				; decrement number of keys to print
	ld a,b
	ld (NKEYBUF),a		; store this number in nkeybuf
	cp 0				; zero keys reached, return
	ret z
	jp nextkey

;-------------------------------------------------------------------------------
; Decrement key counter
;-------------------------------------------------------------------------------
deckeycnt:
	ld a,(NKEYBUF)
	dec a
	ld (NKEYBUF),a		; store this number in nkeybuf
	ret
	
;-------------------------------------------
; store key on screen and in command buffer
; input: a - key to store
; uses: hl
;-------------------------------------------
storekey:
	push af
	ld a,(NCMDBUF)
	inc a
	cp 9				; check if buffer would overflow
	jp nz,storekeycont	; if not continue, else rewrite last key
	pop af
	ld hl,(CMDSCRNPTR)	; load screen addr
	dec hl
	ld (hl),a			; put character on screen
	ld hl,(CMDBUFPTR)	; load command buffer addr
	dec hl
	ld (hl),a			; put character in command buffer
	ret
storekeycont:
	pop af
	ld hl,(CMDSCRNPTR)	; load screen addr
	ld (hl),a			; put character on screen
	inc hl				; increment CMDSCRNPTR
	ld (CMDSCRNPTR),hl	; and store back
	ld hl,(CMDBUFPTR)	; load command buffer addr
	ld (hl),a			; put character in command buffer
	inc hl				; increment CMDBUFPTR
	ld (CMDBUFPTR),hl	; and store back
	; uncomment the lines below to show the hexcode
	; of the last character that is pressed
	;push bc			
	;ld b,a
	;ld hl,$5000
	;call printhex
	;pop bc
	ld a,(NCMDBUF)
	inc a
	ld (NCMDBUF),a
	ret

;-------------------------------------------------------------------------------
; enter key is pressed
; 
; the getkey routine JUMPS to this address
;-------------------------------------------------------------------------------
keyenter:
	call deckeycnt		; remove enter from key buffer
	call clearresp
	call parsecmd
	call clearcmd
	ld a,0
	ld (NKEYBUF),a		; store this number in nkeybuf
	ret					; return from getkey routine

;-------------------------------------------------------------------------------
; clear the response line on the screen
;-------------------------------------------------------------------------------
clearresp:
	ld a,0				; clear response line
	ld (RSPSCRN),a
	ld de,RSPSCRN+1
	ld bc,40
	dec bc
	ld hl,CMDSCRN
	ldir
	ret

;-------------------------------------------------------------------------------
; clear line on screen and command memory
;-------------------------------------------------------------------------------
clearcmd:
	ld a,0				; clear command line
	ld (CMDSCRN),a
	ld de,CMDSCRN+1
	ld bc,8
	dec bc
	ld hl,CMDSCRN
	ldir
	ld a,0				; clear command buffer
	ld (CMDBUF),a
	ld de,CMDBUF+1
	ld bc,10
	dec bc
	ld hl,CMDBUF
	ldir
	call clearcmdbuf
	ld a,'>'			; reset line symbol
	ld (CMDSCRN-1),a
	ret

;-------------------------------------------------------------------------------
; clear the command buffers
;-------------------------------------------------------------------------------
clearcmdbuf:
	ld hl,CMDSCRN
	ld (CMDSCRNPTR),hl
	ld a,0
	ld (NCMDBUF),a
	ld hl,CMDBUF
	ld (CMDBUFPTR),hl
	ret

;-------------------------------------------------------------------------------
; backspace key is pressed
;
; the getkey routine JUMPS to this address
;-------------------------------------------------------------------------------
keybackspace:
	ld a,(NCMDBUF)		; check if there are any keys in buffer
	cp 0
	jp z,getkeycont		; if not, return
	ld hl,(CMDSCRNPTR)	; load screen addr
	dec hl
	ld a,0
	ld (hl),a			; put empty space on screen
	ld (CMDSCRNPTR),hl	; and store back
	ld hl,(CMDBUFPTR)	; load command buffer addr
	dec hl
	ld a,0
	ld (hl),a			; put empty space in buffer
	ld (CMDBUFPTR),hl	; and store back
	ld a,(NCMDBUF)
	dec a
	ld (NCMDBUF),a
	jp getkeycont		; return to key routine

;-------------------------------------------------------------------------------
; convert keyboard signal to ASCII character
; input:  a - keyboard characters
; output: a - ASCII character
;-------------------------------------------------------------------------------
keytoascii:
	push hl				; push registers
	push bc
	ld hl,asciitab		; load location of conversion table
	ld b,0				; set b to zero
	ld c,a				; store offset on c
	add hl,bc			; get address of ascii value
	ld a,(hl)			; load ascii value
	pop bc				; restore registers
	pop hl
	ret

;-------------------------------------------------------------------------------
; print message to the screen
; input: hl - pointer to message
;  uses: a,hl
;-------------------------------------------------------------------------------
printmessage:
	ld de,MSGSCR-1
	ld a,COL_MAG
	ld (de),a
	ld de,MSGSCR
	call printstring
	ret	

;-------------------------------------------------------------------------------
; clean the message area
; uses: a,b,hl
;-------------------------------------------------------------------------------
cleanmessage:
	ld b,40
	ld hl,MSGSCR
	ld a,0
clnnxt:
	ld (hl),a
	inc hl
	dec b
	jp nz,clnnxt
	ret

;-------------------------------------------------------------------------------
; Rewind the cassette and reset the block
; index counter
;-------------------------------------------------------------------------------
taperewind:
	ld a,CAS_INIT
	call tape
	ld a,CAS_REWIND
	call tape
	ld a,0
	ld (BLKIDX),a
	ret

;-------------------------------------------------------------------------------
; Read a single block from the tape to
; the buffer area
;-------------------------------------------------------------------------------
tapesingleblock:
	ld a,(CASSTAT)		; load tape status
	cp 'M'				; check for M
	ret z
	ld hl,BUFFER
	ld ($6030),hl
	ld hl,$0400
	ld ($6032),hl
	ld hl,$0400
	ld ($6034),hl
	ld a,CAS_INIT
	call TAPE
	ld a,CAS_READ
	call TAPE
	call checktapeerror
	ld a,(BLKIDX)
	inc a
	ld (BLKIDX),a
	ret

;-------------------------------------------------------------------------------
; Check for tape errors
;-------------------------------------------------------------------------------
checktapeerror:
	ld a,(BLKIDX)
	cp 0
	ret nz
	ld a,(CASSTAT)		; load tape status
	cp 'M'				; check for M
	ret nz
.fixm:
	ld hl,.message
	call printmessage
	ld hl,BUFFER
	ld ($6030),hl
	ld hl,$0400
	ld ($6032),hl
	ld hl,$0400
	ld ($6034),hl
	ld a,CAS_INIT
	call TAPE
	ld a,CAS_READ
	call TAPE
	call cleanmessage
	ret

.message: DB "Received M on first call, bypassing...",255

;-------------------------------------------------------------------------------
; Copy header from RAM to ROM
;
; Automatically increments ROMADDR by $100
;
; uses: a,bc,de,hl (all)
;-------------------------------------------------------------------------------
;copyheader:
;	ld bc,$30				; length to copy
;	call copyzeros			; pad first $30 bytes by zeros
;---------------------------------------------------------
;	ld hl,(ROMADDR)			; load ROM address
;	ld de,$30				; increment by $30
;	add hl,de
;	ld (ROMADDR),hl			; and store back
;----------------------------------------------------------
;	ld bc,$20				; copy $20 cassette header bytes
;	ld hl,TRANSFER			; set start at transfer address
;	ld de,(ROMADDR)			; target address
;.next:
;	push bc					; store everything
;	push de					; on the stack
;	push hl
;	ld c,O_ROM_EXT
;	call sst39sfwrbytemem  	; send byte to chip; use address from BC
;	pop hl					; recall everything
;	pop de					; from the stack
;	pop bc
;	dec bc					; decrement counter
;	ld a,b
;	or c					; check whether counter is zero
;	jp z,.exit
;	inc hl					; next source address
;	inc de					; next target address
;	jp .next
;.exit:
;	ld hl,(ROMADDR)			; load ROM address
;	ld de,$20				; increment by $20
;	add hl,de
;	ld (ROMADDR),hl			; and store back
;---------------------------------------------------------
;	ld bc,$B0				; length to copy
;	call copyzeros			; pad final $B0 bytes by zeros
;---------------------------------------------------------
;	ld hl,(ROMADDR)			; load ROM address
;	ld de,$B0				; increment by $B0
;	add hl,de
;	ld (ROMADDR),hl			; and store back
;	ret

;-------------------------------------------------------------------------------
; Copy a number of zeros to ROM
;
; !!DOES NOT AUTOMATICALLY INCREMENT ROMADDR!!
;
; input: bc - number of bytes
;  uses: a,bc,de,hl
;-------------------------------------------------------------------------------
copyzeros:
	ld de,(ROMADDR)			; target address
.next:
	push bc					; put counter on stack
	push de					; put target address on stack
	ld a,0					; load '0' byte
	ld c,O_ROM_EXT
	call sst39sfwrbyteacc  	; send byte to chip; use address
	pop de					; recall target address from stack
	pop bc					; recall counter from stack
	dec bc					; decrement counter
	ld a,b
	or c					; check whether counter is zero
	ret z
	inc de					; next target address
	jp .next

;-------------------------------------------------------------------------------
; Copy block from BUFFER TO ROM
;
; Automatically increments ROMADDR by $400
;
; input: ROMADDR - ROM address
;  uses: a,bc,de,hl
;-------------------------------------------------------------------------------
;copyblock:
;	ld bc,$400				; length to copy
;	ld hl,BUFFER			; source address
;	ld de,(ROMADDR)			; target address
;.next:
;	push bc					; store everything
;	push de					; on the stack
;	push hl
;	ld c,O_ROM_EXT			; set port number
;	call sst39sfwrbytemem  	; send byte to chip; use address from HL
;	pop hl					; recall everything
;	pop de					; from the stack
;	pop bc
;	dec bc					; decrement counter
;	ld a,b
;	or c					; check whether counter is zero
;	jp z,.exit
;	inc hl					; next source address
;	inc de					; next target address
;	jp .next
;.exit:
;	ld hl,(ROMADDR)			; load ROM address
;	ld de,$400				; increment by $400
;	add hl,de
;	ld (ROMADDR),hl			; and store back
;	ret

;-------------------------------------------------------------------------------
; archive filetype index
;-------------------------------------------------------------------------------
storeprogdata:
	ld de,(PNAMEADDR)	; store description
	ld hl,DESC1
	ld bc,8
	ldir
	ld hl,DESC2
	ld bc,8
	ldir
	ld (PNAMEADDR),de	; increment pointer
	ld a,(BLKIDX)		; store block index
	dec a				; decrement index
	ld hl,(PIDXADDR)
	ld (hl),a
	inc hl
	ld (PIDXADDR),hl	; store pointer
	ld de,(FILESIZE)	; store program size
	ld hl,(PLNADDR)
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl				; increment pointer
	ld (PLNADDR),hl		; store pointer
	ld a,(BLOCKCTR)		; store number of blocks
	ld hl,(PNBADDR)
	ld (hl),a
	ld (TOTNUMBLK),a	; store also for file copying routines
	inc hl				; increment pointer
	ld (PNBADDR),hl		; store pointer
	ret

;-------------------------------------------------------------------------------
; reset the archive
;-------------------------------------------------------------------------------
resetarchive:
	ld de,PROGNAMES
	ld a,0
	ld (de),a
	inc de
	ld hl,PROGNAMES
	ld bc,$300
	ldir
	call resetarchivepointers
	ret

;-------------------------------------------------------------------------------
; reset the archive pointers
;-------------------------------------------------------------------------------
resetarchivepointers:
	ld hl,PROGNAMES		; program names
	ld (PNAMEADDR),hl
	ld hl,PROGBIDX		; program block (start) indices
	ld (PIDXADDR),hl
	ld hl,PROGLN		; program lengths
	ld (PLNADDR),hl
	ld hl,PROGNB		; program number of blocks
	ld (PNBADDR),hl
	ret

;-------------------------------------------------------------------------------
; clear the block occupied by the monitor
;-------------------------------------------------------------------------------
clearinterface:
	ld a,0 ; load 0 into first byte
	ld (IFCSCRN),a
	ld de,IFCSCRN+1
	ld bc,$50*14
	dec bc
	ld hl,IFCSCRN
	ldir ; copy next byte from previous
	ret

;-------------------------------------------------------------------------------
; compare two strings
; input: de - address of string 1
;        hl - address of string 2
;		  c - number of bytes
; output: a - 0 is true, 1 false
; uses:  all
;-------------------------------------------------------------------------------
cpstring:
	ld a,(de)
	ld b,(hl)
	cp b
	jp nz,.cpstringfalse
	dec c
	jp z,.cpstringtrue
	inc de
	inc hl
	jp cpstring
.cpstringfalse:
	ld a,1
	ret
.cpstringtrue:
	ld a,0
	ret

;-------------------------------------------------------------------------------
; Check chip id and report result
;-------------------------------------------------------------------------------
sst39checkchip:
	ld a,'C'		; print 'C' label on screen
	ld de,CHIPSCR
	ld (de),a
	inc de
	ld a,':'
	ld (de),a
	ld c,O_ROM_EXT
	call sst39sfid
	ld (CHIPID),hl	; store chip id
	ld a,h			; load lower byte
	cp $BF			; check lower byte
	jp nz,.false
	ld a,l
	ld h,l			; temporarily store on h
	and $B0
	cp $B0			; check upper nibble
	jp nz,.false
	ld a,h
	sub $B0
	cp 5
	jp z,.ssc10
	cp 6
	jp z,.ssc20
	cp 7
	jp z,.ssc40
	jp .false
.ssc10:
	ld b,$30+1
	jp .true
.ssc20:
	ld b,$30+2
	jp .true
.ssc40:
	ld b,$30+4
.true:
	ld de,CHIPSCR+2	; print name of the chip
	ld hl,.msgchip
	call printstring
	ld a,b
	ld (de),a
	ld a,'0'
	inc de
	ld (de),a
	ld a,0			; print two empty cells after chip name
	inc de
	ld (de),a
	inc de
	ld (de),a
	ret
.false:				; parse invalid CHIP id
	ld hl,.msgnochip
	ld de,CHIPSCR+2
	call printstring
	ld hl,(CHIPID)
	ld de,CHIPSCR+11
	ld a,h
	call printhex
	ld a,l
	call printhex
	ret

.msgchip: DB COL_GREEN,"SST39SF0",255

.msgnochip:	DB COL_RED,"No chip: ",255

;-------------------------------------------------------------------------------
; set rom bank
; input: a - ROM BANK
; uses: a,hl
;-------------------------------------------------------------------------------
setrombank:
	ld (ROMBANK),a
	out (O_ROM_BANK),a
	call prtrombank
	ret

;-------------------------------------------------------------------------------
; include functionalities
;-------------------------------------------------------------------------------
include "sst39sf0x0.asm"
include "util.asm"
include "monitor.asm"
include "modal.asm"
include "file.asm"
include "crc16.asm"
include "copy.asm"
include "ram.asm"
include "programlist.asm"

;-------------------------------------------------------------------------------
; ascii conversion table
;-------------------------------------------------------------------------------
asciitab:
include "asciitable.asm"

;-------------------------------------------
; textstrings to print
;-------------------------------------------

strerasechip:
	DB "Erasing chip block:",255