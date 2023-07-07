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
; calculate rom address from block number
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
; calculate metadata header address from block number
;
; input:  FREEBLOCK
; output: HEADERADDR - cartridge header start address
;		  MARKERADDR - rom block marker address
;
; uses: all
;-------------------------------------------------------------------------------
calcheaderaddr:
	ld a,(FREEBLOCK)
	rla
	rla
	and $FC
	push af				; store result
	rra
	rra
	rra
	rra
	and $0F
	ld h,a				; store upper byte
	pop af
	rla
	rla
	rla
	rla
	and $F0
	ld l,a				; store lower byte
	ld de,$0120
	add hl,de
	ld (HEADERADDR),hl
	ld de,24
	sbc hl,de
	ld (MARKERADDR),hl
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