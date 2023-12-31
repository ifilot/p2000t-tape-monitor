;# MAIN="main.asm"
;-------------------------------------------------------------------------------
; file.asm
;
; File and "Drive" operations
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; format drive
;-------------------------------------------------------------------------------
format:
	call chiperase				; completely erase chip
	ld a,0						; start with bank 0
	ld (ROMBANK),a				; store bank zero in memory
.nextbank:
	ld hl,.msg
	call printmessage
	ld a,(ROMBANK)				; load rom bank
	out (O_ROM_BANK),a			; set bank in register
	call printhex
	ld c,O_ROM_EXT				; set which chip to erase
	call formatbank
	ld a,(ROMBANK)
	inc a
	cp 8
	ret z
	ld (ROMBANK),a
	jp .nextbank

.msg: DB "Writing FAT on Bank $",255

;-------------------------------------------------------------------------------
; format bank
; input: ROMBANK
; uses: all
;
; note that sst39sfwrbytexxx conserves port number c and rom address de
;-------------------------------------------------------------------------------
formatbank:
	ld a,(ROMCHIP)				; load which port
	ld c,a
	ld b,60						; number of blocks per bank
	ld de,$0100					; start of first metadata segment
	ld hl,$1000					; start of first block
	ld (METASTORE2),hl			; store in metadata2
.nextblock:
	push bc						; push counter to stack
	ld hl,ROMBANK				; store pointer to ROM bank address
	call sst39sfwrbytemem
	inc de						; next address
	ld hl,(METASTORE2)
	ld a,l
	call sst39sfwrbyteacc		; store lower byte
	inc de
	ld hl,(METASTORE2)
	ld a,h
	call sst39sfwrbyteacc		; store upper byte
	pop bc						; retrieve counter from stack
	dec b
	ret z						; return when all blocks are done
	ex de,hl					; set rom address in hl
	ld de,$40-2					; next metadata address
	add hl,de					; go to start address of next block
	ex de,hl					; set rom address back in de
	push de
	ld hl,(METASTORE2)			; load location of previous block
	ld de,$400					; add $400 to go to next block
	add hl,de					; store in hl
	ld (METASTORE2),hl			; store in RAM
	pop de						; get metadata location back in de
	jp .nextblock

;-------------------------------------------------------------------------------
; Find the first free available block to put new data into.
;
; Loops over the $40 byte sections until a free section is found. The bank
; and block are stored in (FREEBANK) and (FREEBLOCK) memory locations.
;
; uses: all
;-------------------------------------------------------------------------------
findfreeblock:
	ld a,0						; start with bank 0
	ld (ROMBANK),a				; store bank zero in memory
.nextbank:
	ld a,(ROMBANK)				; load rom bank
	out (O_ROM_BANK),a			; set bank in register
	ld de,$0108					; verification byte in metadata
	ld b,0						; block counter
.nextblock:
	ld c,O_ROM_EXT
	call sst39sfrecv			; load verification byte
	cp $FF
	;and $00					; for debugging purposes
	jp z,.exit
	ex de,hl					; increment block by 40
	ld de,$40
	add hl,de
	ex de,hl
	inc b
	ld a,b
	cp 60						; last block reached, go to next bank
	jp z,.gotonextbank
	jp .nextblock
.exit:
	ld a,b
	ld (FREEBLOCK),a
	ld a,(ROMBANK)
	ld (FREEBANK),a
	ret
.gotonextbank:
	ld a,(ROMBANK)				; load rom bank
	inc a
	cp 8
	jp z,.failure
	ld (ROMBANK),a
	jp .nextbank
.failure:
	ld a,$FF
	ld (FREEBANK),a
	ld (FREEBLOCK),a
	ret

;-------------------------------------------------------------------------------
; given the block number as set in FREEBLOCK, calculate the ROM address
;
; input:  FREEBLOCK
; output: ROMADDR
; uses: all
;-------------------------------------------------------------------------------
calcromaddr:
	ld a,(FREEBLOCK)
	or a
	rla
	rla
	and $FC
	ld h,a
	ld l,0
	ld de,$1000
	add hl,de
	ex de,hl
	ld (ROMADDR),de
	ld (ROMADDRSTR),de
	ret

;-------------------------------------------------------------------------------
; calculate addresses from block number
;
; input:  FREEBLOCK
; output: HEADERADDR - cartridge header start address
;		  MARKERADDR - rom block marker address
;
; uses: all
;-------------------------------------------------------------------------------
calcmetaaddr:
	ld a,(FREEBLOCK)
	call calccasheader
	ld (HEADERADDR),hl
	ld de,24
	or a				; reset carry flag
	sbc hl,de
	ld (MARKERADDR),hl
	ret

;-------------------------------------------------------------------------------
; calculate metadata CAS header addresses from block number
;
; This routine effectively multiplies the value in a with 40 and adds 
; $0120 to it to find the starting byte of the CAS header.
;
; input:  a - block number (retained)
; output: hl - cartridge header start address
;
; uses: de,ixl
;-------------------------------------------------------------------------------
calccasheader:
	ld de,$0120
	call calcheaderaddr
	ret

;-------------------------------------------------------------------------------
; calculate header offset using block address and offset index
;
; input: a  - block number (retained)
;        de - header offset	(retained)
;
; uses: ixl
;
; return: hl - (a * $40) + de
;-------------------------------------------------------------------------------
calcheaderaddr:
	call amul40hl		; have a multiplied by 40 in hl
	add hl,de			; add de offset to hl
	ret

;-------------------------------------------------------------------------------
; Multiply value in a by 40 and store in hl
;
; input:  a  - value to be multiplied (retained)
; output: hl - a * 40
;
; uses: ixl
;-------------------------------------------------------------------------------
amul40hl:
	rla					; rotate left two times
	rla
	and $FC				; set two LSB to zero
	ld ixl,a
	rra					; rotate right four times
	rra
	rra
	rra
	and $0F				; place center 4 bits at right end
	ld h,a				; store upper byte
	ld a,ixl
	rla
	rla
	rla
	rla
	and $F0				; clears lower nibble
	ld l,a				; store lower byte
	ld a,ixl			; ensure value of a is retained
	ret

;-------------------------------------------------------------------------------
; copies block from buffer to rom, uses fixed positions in memory 
; for location data
;
; input:  ROMBANK - which ROM bank to write to
;		  ROMADDR - which ROM address to write to
;		  ROMPORT - which chip to write to
; output: de - last rom address written to
; uses: all
;-------------------------------------------------------------------------------
copyblock:
	ld a,(FREEBANK)		; get rom bank
	out (O_ROM_BANK),a	; set rom bank
	ld de,(ROMADDR)		; get rom address
	ld bc,$400			; set counter
	ld hl,BUFFER		; set source start address
.next:
	push bc				; store counter
	ld a,(ROMPORT)
	ld c,a
	call sst39sfwrbytemem
	pop bc				; retrieve counter
	inc de				; next rom address
	inc hl				; next source address
	dec bc				; decrement counter
	ld a,b
	or c				; check if zero
	jp nz,.next			; if not, next byte
	ld (ROMADDR),de		; store rom address
	ret

;-------------------------------------------------------------------------------
; copies header data from fixed memory position to ROM
; uses: all
;-------------------------------------------------------------------------------
copyheader:
	ld a,(FREEBANK)			; get rom bank
	out (O_ROM_BANK),a		; set rom bank
	ld de,(HEADERADDR)		; get rom address
	ld bc,$20				; set counter
	ld hl,TRANSFER			; set source start address
.next:
	push bc					; store counter
	ld a,(ROMPORT)
	ld c,a
	call sst39sfwrbytemem
	pop bc					; retrieve counter
	inc de					; next rom address
	inc hl					; next source address
	dec bc					; decrement counter
	ld a,b
	or c					; check if zero
	jp nz,.next				; if not, next byte
	ret

;-------------------------------------------------------------------------------
; mark byte $08 in the metadata section to indicate that this block
; of $100 bytes is used
;
; input: MARKERADDR - rom address of markerbyte
;        ROMPORT    - which chip to use
;        FREEBANK   - which bank to write to
;-------------------------------------------------------------------------------
markblock:
	ld a,(FREEBANK)
	out (O_ROM_BANK),a
	ld de,(MARKERADDR)
	ld a,(ROMPORT)
	ld c,a
	ld a,0
	call sst39sfwrbyteacc
	ret

;-------------------------------------------------------------------------------
; calculate a 16 bit checksum
;-------------------------------------------------------------------------------
calcchecksum:
	ld de,$0000					; set initial checksum to $0000
	ld hl,BUFFER				; set address to cassette DATA buffer
	ld bc,$400					; parse $400 bytes = 1kb
	call crc16					; call crc routine, result returned in de
	ld (CRC),de					; store crc in memory
	ld hl,(CRC)
	ld de,$5022
	ld a,'$'
	ld (de),a
	inc de
	ld a,h
	call printhex
	ld a,l
	call printhex
	ret

;-------------------------------------------------------------------------------
; write the 16 bit checksum to the rom header
;-------------------------------------------------------------------------------
writechecksum:
	ld a,(ROMPORT)				; set rom port
	ld c,a
	ld hl,CRC					; load CRC address
	ld de,(MARKERADDR)			; load ROM header address
	dec de						; checksum address lies two bytes earlier
	dec de
	call sst39sfwrbytemem
	inc hl
	inc de
	call sst39sfwrbytemem
	ret

;-------------------------------------------------------------------------------
; writes references for the next block in the current
; block's metadata area
;-------------------------------------------------------------------------------
setlinkedlist:
	ld a,(BLOCKCTR)				; load remaining number of blocks
	ld b,a
	ld a,(TOTNUMBLK)			; load total number of blocks
	cp b						; check if this is the first block
	jp z,.storestartbyte		; only write block data
.storereference:
	ld a,(PREVBANK)				; set previous bank
	out (O_ROM_BANK),a
	ld a,(ROMPORT)				; set rom port
	ld c,a
	ld hl,(PREVMKADDR)			; store marker address
	ld de,5
	or a						; reset carry flag
	sbc hl,de					; load next bank address ($0003)
	ex de,hl					; set in register de
	ld a,(FREEBANK)				; load current bank
	call sst39sfwrbyteacc		; store current bank as reference
	inc de						; go to next address
	ld a,(FREEBLOCK)			; load current block number
	call sst39sfwrbyteacc		; store current bank as reference
.storepreviousblock:			; store data for building linked list
	ld a,(FREEBANK)
	ld (PREVBANK),a				; store bank number
	ld a,(FREEBLOCK)
	ld (PREVBLOCK),a			; store block index
	ld hl,(MARKERADDR)
	ld (PREVMKADDR),hl			; store marker address
.writeblockmetadata:
	ld a,(ROMPORT)				; set rom port
	ld c,a
	ld a,(FREEBANK)				; set current bank
	out (O_ROM_BANK),a
	ld a,(BLOCKCTR)				; load remaining number of blocks
	ld b,a
	ld a,(TOTNUMBLK)			; load total number of blocks
	sub b						; subtract remaining to get current block nr.
	ld de,(MARKERADDR)			; load marker byte address
	inc de
	call sst39sfwrbyteacc		; write current block index
	inc de						; next byte
	ld a,(TOTNUMBLK)				
	call sst39sfwrbyteacc		; write total number of blocks
	ret
.storestartbyte:
	call findfirstfreestartblock
	ld a,(FREEBLOCK)
	call sst39sfwrbyteacc
	jp .storepreviousblock

;-------------------------------------------------------------------------------
; Get the address of the first free startblock; these correspond to addresses
; in the bank metadata section of the rom chip. Each non-0xFF byte in this
; section corresponds to the starting block of a file.
;
; Uses: FREEBANK: 	which bank to probe
;       ROMPORT:	which rom chip to check
; Output: de - address of free rom byte
; Uses: a,de
;-------------------------------------------------------------------------------
findfirstfreestartblock:
	ld a,(FREEBANK)				; set current bank
	out (O_ROM_BANK),a
	ld a,(ROMPORT)				; set rom port
	ld c,a
	ld de,0						; first byte
.next:
	call sst39sfrecv
	cp $FF						; check if this byte is free
	ret z
	inc de
	jp .next

;-------------------------------------------------------------------------------
; write string to rom chip
; input: de - target address
;		 hl - string pointer
; uses: all
;-------------------------------------------------------------------------------
writestring:
	ld a,(hl)
	cp 255
	ret z
	call sst39sfwrbytemem
	inc de
	inc hl
	jp writestring

;-------------------------------------------------------------------------------
; Delete a file from the external ROM as pointed by the file linked list at
; external memory $6000
;-------------------------------------------------------------------------------
deletefile:
	ld hl,FILEBLADDR
	call ramrecvhl
	ld (CURBANK),a			; set bank counter
.nextbank:
;-- set the bank --
	ld a,(CURBANK)
	out (O_ROM_BANK),a		; set starting bank
;-- copy bank data --
	ld bc,$1000				; number of bytes
	ld de,$0000				; external rom start addr
	ld hl,FILEIOBUF			; external ram start addr
	call copysectorrora		; copy metadata section from rom to ram
	ld hl,FILEBLADDR
	call ramrecvhl			; get first bank from external ram
	ld b,a
	ld a,(CURBANK)
	cp b
	jp nz,.skipstartblocks	; if not the same, skip rebuilding starting blocks
	call rebuildstartblocks	; else, rebuild the starting blocks for this bank
.skipstartblocks:
	call formatheader		; format $40 header blocks that are no longer in use
	ld de,$0000
	ld a,(CURBANK)			; load current bank and store in b
	ld b,a
	ld c,(O_ROM_EXT)		; set port to external rom chip
	; --
	call sst39sferase		; erase the first sector (4kb)
	; copy external ram data back to internal rom
	ld bc,$1000				; number of bytes
	ld de,$0000				; external rom start addr
	ld hl,FILEIOBUF			; external ram start addr
	call copysectorraro		; copy metadata section from ram to rom
;-- loop over the remaining 15 sectors and reset the 1kb blocks --
	call buildblockwipelist
	ld a,(CURBANK)
	inc a
	ld (CURBANK),a
	cp 8					; check for last bank
	ret z
	jp .nextbank			; go to next bank

;-------------------------------------------------------------------------------
; When a file is deleted, the starting block should be removed from the
; metadata sector $0000-$00FF and all remaining programs should be shifted to
; the left
;
;-------------------------------------------------------------------------------
rebuildstartblocks:
	ld hl,FILEBLADDR+1		; set address starting block
	call ramrecvhl			; load starting block in a
	ld c,a					; store in c
	ld hl,FILEIOBUF			; set starting address
.nextblock:
	call ramrecvhl			; read bank
	inc hl					; increment address
	cp c					; compare retrieved block with c
	jp nz,.nextblock		; if not the same, try next block
.nextbyte:
	call ramrecvhl			; receive next block
	dec hl
	call ramsendhl			; overwrite block
	cp $FF					; verify if this was the last block
	ret z					; return if so
	inc hl					; move addr two steps
	inc hl
	jr .nextbyte			; overwrite block

;-------------------------------------------------------------------------------
; Format all block headers that are no longer in use on this bank
;
; This function essentially loops over all the bank/block of the linked list.
; This function assumes that all bank/block pairs are in ascending order and
; that the headers are already copied to external RAM. 
;
; If a non-matching bank is encountered, this function automatically skips
; towards the next block. The function stops when a terminating character 
; ($FF) is encountered.
;
; input: CURBANK - current bank
;-------------------------------------------------------------------------------
formatheader:
	ld hl,FILEBLADDR		; set starting address linked list
	ld (FEXTRAMPTR),hl
.nextblock:
	ld hl,(FEXTRAMPTR)
	call ramrecvhl			; receive bank
	ld b,a					; store bank into b
	inc hl
	call ramrecvhl			; receive block
	ld c,a					; store block into c
	inc hl					; increment external ram addr
	ld (CURBANKBLOCK),bc	; store current bank and block
	ld (FEXTRAMPTR),hl
	ld a,b					; load bank into a
	cp $FF					; else check if terminating character is found
	ret z					; if so, return functions, else
	ld a,(CURBANK)			; load current bank into a
	cp b
	jr nz,.continuenextblock; if not, go to next block
;-- calculate block metadata start addr --
	ld a,c
	ld de,FILEIOBUF+$100	; load offset (as seen from external ram)
	call calcheaderaddr		; calculate hl = (a * $40) + de, garbles ixl
	; set first three bytes (formatting)
	ld a,b					; get bank
	call ramsendhl
	inc hl					; increment memory position
	ld a,$00				; set lower byte of rom start address
	call ramsendhl
	inc hl					; increment memory position
	ld a,c					; get block
	or a					; reset carry
	rla						; rotate left twice (multiply by 4)
	rla
	add $10					; add upper byte of $1000
	call ramsendhl
	inc hl
	; wipe the remaining bytes
	ld b,$40-3				; set number of bytes
	ld a,$FF				; set 'wipe' character
.wipenextbyte:
	call ramsendhl			; write to external ram
	inc hl					; increment memory position
	djnz .wipenextbyte		; loop until b = 0
;-- restore stack and go to next block --
.continuenextblock:
	jp .nextblock

;-------------------------------------------------------------------------------
; Build a list of wipe operations that need to be conducted over the current
; bank
;
; input: CURBANK - current bank
;-------------------------------------------------------------------------------
buildblockwipelist:
	ld a,0
	ld (CURSECTOR),a		; set sector counter
.nextsector:
	call findblocksdelete	; populate FILEOPLIST with operations
	ld hl,FILEOPLIST		; set pointer to operations list
	call ramrecvhl
	cp $FF					; check if first character is terminating string
	jr z,.donesector		; bail out if so
	push de
	call reformatsector		; else, execute wipe operations for this sector
	pop de
.donesector:
	ld a,(CURSECTOR)
	inc a
	ld (CURSECTOR),a
	cp 15
	ret z
	jr .nextsector

;-------------------------------------------------------------------------------
; Investigate if any blocks need to be deleted for the current sector and place
; these blocks in an array starting at FILEOPLIST.
;
; input: CURSECTOR - current sector
;-------------------------------------------------------------------------------
findblocksdelete:
	ld a,(CURSECTOR)
	or a					; clear carry
	rla						; rotate left twice, multiply by 2
	rla
	ld e,a					; set lower bound
	add 4
	ld d,a					; set upper bound
	ld hl,FILEBLADDR		; set external ram addr
	ld bc,FILEOPLIST
.nextblock:
	push bc
	call ramrecvhl			; receive bank
	ld b,a					; store bank into b
	inc hl
	call ramrecvhl			; receive block
	ld c,a					; store block into c
	inc hl					; increment external ram addr
	cp $FF					; check end of block
	jr z,.exit
	ld a,(CURBANK)			; load bank
	cp b
	jp nz,.contnextblock
	ld a,c					; load block
	cp e					; check if bank is larger or equal to lower bound
	jr c,.contnextblock
	cp d					; check if bank is lower than upper bound
	jr nc,.contnextblock
	ld a,c					; store block to delete in ixh
	pop bc
	call ramsendbc
	inc bc
	jr .nextblock
.contnextblock:
	pop bc
	jr .nextblock
.exit:
	pop bc
	ld a,$FF
	call ramsendbc			; set terminating byte
	ret

;-------------------------------------------------------------------------------
; Print the delete sector operations for each block on the screen at memory
; address de
;-------------------------------------------------------------------------------
printopts:
	ld hl,FILEOPLIST
.nextop:
	call ramrecvhl
	cp $FF
	ret z
	call printhex
	inc de
	inc hl
	jr .nextop	

;-------------------------------------------------------------------------------
; Delete blocks from sector as indicated by FILEOPLIST
;
; input: CURBANK   - current bank
;        CURSECTOR - current sector
;-------------------------------------------------------------------------------
reformatsector:
; -- calculate address of current sector --
	ld a,(CURSECTOR)
	inc a					; increment by one to take header offset into account
	or a					; clear carry
	rla
	rla
	rla
	rla
	ld d,a					; load in d
	ld e,$00
	; --
	ld (TEMPCURSEC),de		; store absolute ROM addr in memory
	ld hl,FILEIOBUF			; external ram start addr
	ld bc,$1000				; number of bytes
	call copysectorrora	; copy metadata section from rom to ram
	; --
	ld hl,FILEOPLIST
.nextopt:
	push hl
	call ramrecvhl			; call operation
	cp $FF					; check if terminating character
	jp z,.finalize
	call writeloghex		; print the value
	or a					; clear carry
	rla
	rla
	add $10
	ld h,a					; multiply a by $400 and add $1000 and store in hl
	ld l,$00
	ld de,(TEMPCURSEC)		; load absolute ROM addr of sector
	or a
	sbc hl,de				; get addr relative to sector
	ld de,FILEIOBUF
	add hl,de				; get relative addr in buffer
	ld bc,$400				; set number of bytes to wipe
.nextbyte:
	ld a,$FF				; set wipe character
	call ramsendhl			; wipe
	inc hl					; next memory position
	dec bc					; decrement counter
	ld a,b
	or c
	jp nz,.nextbyte			; check if zero, if not, continue
	pop hl					; retrieve fileoplist address
	inc hl					; increment addr
	jp .nextopt				; try next operation
.finalize:
	pop hl
; -- done with all operations, now write back --
	; -- erase sector --
	ld a,(CURBANK)			; call writeloghexput current bank number in b
	ld b,a
	ld c,(O_ROM_EXT)		; set port to external rom chi
	ld de,(TEMPCURSEC)
	call sst39sferase		; erase the first sector (4kb)
	; -- write back --
	ld bc,$1000				; number of bytes
	ld de,(TEMPCURSEC)
	ld hl,FILEIOBUF			; external ram start addr
	call copysectorraro
	ret

;-------------------------------------------------------------------------------
; Create a list of all the blocks the file resides on
;
; input: b - starting bank of file (retained)
;        c - starting block of file (retained)
;
; uses: all
;
; Note that getnextblock uses calcheaderaddr which in turn uses the ix register
;-------------------------------------------------------------------------------
createchain:
	ld hl,FILEBLADDR	; start location of blocklist
	ld a,b
	call ramsendhl		; store first bank
	inc hl
	ld a,c
	call ramsendhl		; store first block
	inc hl
.nextblock:
	push hl				; put external ram address on the stack
	call getnextblock	; grab next bank/block in de (clobbers hl)
	pop hl				; retrieve external ram addr
	ld a,d
	call ramsendhl		; store subsequent bank
	inc hl
	ld a,e
	call ramsendhl		; store subsequent block
	inc hl
	cp $FF
	ret z
	ld b,d				; update current bank
	ld c,e				; update current block
	jr .nextblock

;-------------------------------------------------------------------------------
; Get next bank and block of file
; 
; input: b - starting bank of file (retained)
;        c - starting block of file (retained)
;
; uses: hl,ixl
;
; return d - next bank number
;        e - next block number
;-------------------------------------------------------------------------------
getnextblock:
	ld a,b					; load bank number
	out (O_ROM_BANK),a		; set bank
	ld a,c					; load block number
	ld de,$103 				; next bank offset
	call calcheaderaddr		; get address in hl from (a * 40) + de
	call sst39sfrecvextromhl; receive next bank in a
	ld d,a
	inc hl
	call sst39sfrecvextromhl; receive next block in a
	ld e,a
	ret

;-------------------------------------------------------------------------------
; erase chip
;-------------------------------------------------------------------------------
chiperase:
	ld a,0
	ld (ROMBANK),a
.nextbank:
	ld hl,.msg
	call printmessage
	ld a,(ROMBANK)
	call printhex
	ld c,O_ROM_EXT				; set which chip to erase
	call sst39erase64kb			; 64kb of rom chip
	ld a,(ROMBANK)
	inc a
	cp 8
	ret z
	ld (ROMBANK),a
	jp .nextbank

.msg: DB "Wiping bank: $",255