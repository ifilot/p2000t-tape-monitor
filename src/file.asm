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
; find the first free available block to put new data into
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
	call calcheader
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
; input:  a - block number
; output: hl - cartridge header start address
;
; uses: de,i
; fixed: a
;-------------------------------------------------------------------------------
calcheader:
	rla					; rotate left two times
	rla
	and $FC
	ld i,a
	rra					; rotate right four times
	rra
	rra
	rra
	and $0F				; place center 4 bits at right end
	ld h,a				; store upper byte
	ld a,i
	rla
	rla
	rla
	rla
	and $F0
	ld l,a				; store lower byte
	ld de,$0120
	add hl,de
	ld a,i
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
; mark a block in the metadata as being used
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

;-------------------------------------------------------------------------------
; Copy starting blocks from external rom to external ram
;
; Programs (files) are indicated by two bytes, the first byte is the first block
; of the file on the bank and the second byte is the bank number. This
; information can at most cover 2*8*60 = 960 bytes of data, for which
; $0000-$0400 in RAM is allocated.
;
;-------------------------------------------------------------------------------
copyprogblocks:
	ld b,8					; set bank counter
	ld c,0					; current bank
	ld hl,0					; set start ram storage location
.nextbank:
	ld a,c
	out (O_ROM_BANK),a		; set bank
	ld de,0					; first address on the bank
.nextbyte:
	call sst39sfrecvexrom	; read start block from external rom
	cp $FF					; check if end of bank
	jr z,.endbank			; if so, end reading of this bank
	jr .storebytes			; if not, store data in ram
.endbank:
	dec b
	jr z,.done
	inc c
	jr .nextbank
.storebytes:
	call ramsendhl			; store current block (still in a)
	ld a,c					; load current bank in a
	inc hl					; increment ext ram addr
	call ramsendhl			; store current bank in ext ram
	inc hl					; increment ext ram addr (for next program)
	inc de					; increment rom addr
	jr .nextbyte
.done:
	ld a,(ROMBANK)			; restore rom bank
	out (O_ROM_BANK),a
	ld a,$FF				; write terminating byte (twice)
	call ramsendhl			; store terminating byte
	inc hl
	call ramsendhl			; store terminating byte

;-------------------------------------------------------------------------------
; Copy CAS descriptors from external rom to external ram
;
; Filenames are stored as 16 byte strings which can take at most 7680 bytes of
; information. To store the filenames, $0400-$2200 in memory is reserved.
;-------------------------------------------------------------------------------
copydesceroera:
	ld hl,0					; start at first program
	ld bc,$400				; start of string locations
.nextprog:
	call ramrecvhl			; load block number in accumulator
	cp $FF					; check if this is the last block
	ret z					; return if so
	ld i,a					; store temporarily in i
	inc hl
	call ramrecvhl			; load bank number in accumulator
	out (O_ROM_BANK),a		; set external rom bank
	inc hl					; next program address
	push hl					; push block index addr to stack
	ld a,i					; recover block number
	call calcheader			; determine start header addr, result stored in hl
	ld de,$0006				; add $26 to get to start descriptor
	add hl,de
	ex de,hl				; de is set to start of RAM descriptor
	ld h,8					; use h as byte counter
.nextbyte1:
	call sst39sfrecvexrom	; read descriptor byte from ext rom
	call ramsendbc			; send to external ram
	inc de					; next byte from external rom
	inc bc					; next byte in external ram
	dec h					; decrement counter
	jr nz,.nextbyte1		; check if zero, if not, next byte
	ex de,hl				; set rom address in hl
	ld de,10				; set increment for next descriptor block
	add hl,de				; add to address
	ex de,hl				; set rom address back into de
	ld h,8					; set byte counter
.nextbyte2:
	call sst39sfrecvexrom	; read descriptor byte from ext rom
	call ramsendbc			; send to external ram
	inc de					; next byte from external rom
	inc bc					; next byte in external ram
	dec h					; decrement counter
	jr nz,.nextbyte2		; check if zero, if not, next byte
	pop hl					; recover hl
	jp .nextprog			; try to grab next program