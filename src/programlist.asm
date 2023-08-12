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
	ld hl,0
	ld (MAXFILES),hl		; set file counter to 0
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
	inc a
	ld a,c					; load current bank in a
	inc hl					; increment ext ram addr
	call ramsendhl			; store current bank in ext ram
	inc hl					; increment ext ram addr (for next program)
	inc de					; increment rom addr
	push hl					; put current ram addr on stack
	ld hl,(MAXFILES)		; load number of files in hl
	inc hl					; increment number of files
	ld (MAXFILES),hl		; store back
	pop hl					; retrieve current ram addr from stack
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
	ld de,$0006				; add 6 to get to start descriptor
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
	ld de,9 				; set increment for next descriptor block
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

;-------------------------------------------------------------------------------
; Copy CAS file extensions from external rom to external ram
;
; extensions are stored as 3 byte strings which can take at most 1440 bytes of
; information. To store the filenames, $2200-$2800 in memory is reserved.
;-------------------------------------------------------------------------------
copyfileext:
	ld hl,0					; start at first program
	ld bc,$2200				; start of string locations
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
	ld de,$000E				; add $000E to get to start extension
	add hl,de
	ex de,hl				; de is set to start of RAM descriptor
	ld h,3					; use h as byte counter
.nextbyte:
	call sst39sfrecvexrom	; read descriptor byte from ext rom
	call ramsendbc			; send to external ram
	inc de					; next byte from external rom
	inc bc					; next byte in external ram
	dec h					; decrement counter
	jr nz,.nextbyte			; check if zero, if not, next byte
	pop hl					; recover hl
	jp .nextprog			; try to grab next program

;-------------------------------------------------------------------------------
; Copy file lengths
;
; file lengths are stored as 2 byte strings which can take at most 960 bytes of
; information. To store the filenames, $2800-$2C00 in memory is reserved.
;-------------------------------------------------------------------------------
copyfilelengths:
	ld hl,0					; start at first program
	ld bc,$2800				; start of string locations
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
	ld de,$0002				; add 2 to get to start of file lengths
	add hl,de
	ex de,hl				; de is set to start of RAM descriptor
	ld h,2					; use h as byte counter
.nextbyte:
	call sst39sfrecvexrom	; read descriptor byte from ext rom
	call ramsendbc			; send to external ram
	inc de					; next byte from external rom
	inc bc					; next byte in external ram
	dec h					; decrement counter
	jr nz,.nextbyte			; check if zero, if not, next byte
	pop hl					; recover hl
	jp .nextprog			; try to grab next program

;-------------------------------------------------------------------------------
; Show all files on the ROM
;-------------------------------------------------------------------------------
showfiles:
	ld hl,0					; set current file counter to 0
	ld (FILESTART),hl
.interface:
	call clearscreen
	ld de,$5000 + 28
	ld a,'$'
	ld (de),a
	inc de
	ld hl,(FILESTART)
	ld a,h
	call printhex
	ld a,l
	call printhex
	ld a,'/'
	ld (de),a
	inc de
	ld a,'$'
	ld (de),a
	inc de
	ld hl,(MAXFILES)
	ld a,h
	call printhex
	ld a,l
	call printhex
	call showdescriptions
	call showextensions
	call showfilelengths
	ret

;-------------------------------------------------------------------------------
; Show descriptions
;-------------------------------------------------------------------------------
showdescriptions:
	ld bc,(FILESTART)			; set bc as program counter
	ld ixh,20					; number of files on screen
	ld de, $5000+$50 * 2 		; set start address
.nextprogram:
	ld a,b
	call printhex
	ld a,c
	call printhex
	inc de
	ld a,b					; load upper address in b
	rla						; shift right by 4 (multiply by 16)
	rla
	rla
	rla
	and $F0					; keep only upper nibble of upper byte
	ld h,a					; store upper byte in h
	ld a,c					; load lower byte
	rra						; shift right by 4 (divide by 16)
	rra
	rra
	rra
	and $0F					; keep only lower nibble
	or h					; put together with upper nibble of upper byte
	ld h,a					; store upper byte position
	ld a,c					; load lower byte
	rla						; shift left by 4 (multiply by 16)
	rla
	rla
	rla
	and $F0					; keep only upper nibble
	ld l,a					; store lower byte in l
	push de					; put video addr on stack
	ld de,$400				; set ex ram offset
	add hl,de				; add to ex ram address
	pop de					; get video ram from stack
	ld ixl,16				; number of bytes
.nextbyte:
	call ramrecvhl			; get character from external ram
	ld (de),a				; store in video ram
	inc de					; increment video ram addr
	inc hl					; increment ex ram addr
	dec ixl					; decrement byte counter
	jr nz,.nextbyte			; if not zero, go to next byte
	inc bc					; increment program counter
	ld hl,(MAXFILES)		; load maximum number of files
	or a					; reset carry flag
	sbc hl,bc				; subtract bc from hl, check if zero flag is set
	ret z					; return if max files is reached
	dec ixh					; decrement program per page counter
	ret z					; check if zero, if so, return
	ex de,hl				; swap de,hl
	ld de,$50-21			; load next line increment
	add hl,de				; add increment to video ram
	ex de,hl				; swap hl and de
	jp .nextprogram			; go to next program if not zero

;-------------------------------------------------------------------------------
; Show extensions
;-------------------------------------------------------------------------------
showextensions:
	ld bc,(FILESTART)			; set bc as program counter
	ld ixh,20					; number of files on screen
	ld de, $5000+$50 * 2 + 22	; set start address
.nextprogram:
	ld h,b
	ld l,c
	add hl,bc
	add hl,bc
	push de					; put video addr on stack
	ld de,$2200				; set ex ram offset
	add hl,de				; add to ex ram address
	pop de					; get video ram from stack
	ld ixl,3				; number of bytes for extension
.nextbyte:
	call ramrecvhl			; get character from external ram
	ld (de),a				; store in video ram
	inc de					; increment video ram addr
	inc hl					; increment ex ram addr
	dec ixl					; decrement byte counter
	jr nz,.nextbyte			; if not zero, go to next byte
	inc bc					; increment program counter
	ld hl,(MAXFILES)		; load maximum number of files
	or a					; reset carry flag
	sbc hl,bc				; subtract bc from hl, check if zero flag is set
	ret z					; return if max files is reached
	dec ixh					; decrement program per page counter
	ret z					; check if zero, if so, return
	ex de,hl				; swap de,hl
	ld de,$50-3				; load next line increment
	add hl,de				; add increment to video ram
	ex de,hl				; swap hl and de
	jp .nextprogram			; go to next program if not zero

;-------------------------------------------------------------------------------
; Show file lengths
;-------------------------------------------------------------------------------
showfilelengths:
	ld bc,(FILESTART)			; set bc as program counter
	ld ixh,20					; number of files on screen
	ld de, $5000+$50 * 2 + 26	; set start address
.nextprogram:
	ld h,b
	ld l,c
	add hl,bc
	push de					; put video addr on stack
	ld de,$2200				; set ex ram offset
	add hl,de				; add to ex ram address
	pop de					; get video ram from stack
	ld a,'$'
	ld (de),a
	inc de
	call ramrecvhl			; get character from external ram
	call printhex
	inc hl
	call ramrecvhl			; get character from external ram
	call printhex
	inc hl
	inc bc					; increment program counter
	ld hl,(MAXFILES)		; load maximum number of files
	or a					; reset carry flag
	sbc hl,bc				; subtract bc from hl, check if zero flag is set
	ret z					; return if max files is reached
	dec ixh					; decrement program per page counter
	ret z					; check if zero, if so, return
	ex de,hl				; swap de,hl
	ld de,$50-5				; load next line increment
	add hl,de				; add increment to video ram
	ex de,hl				; swap hl and de
	jp .nextprogram			; go to next program if not zero