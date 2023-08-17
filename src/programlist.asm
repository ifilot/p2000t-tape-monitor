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
	call sst39sfrecvextrom	; read start block from external rom
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
	ld ixh,a				; store temporarily in i
	inc hl
	call ramrecvhl			; load bank number in accumulator
	out (O_ROM_BANK),a		; set external rom bank
	inc hl					; next program address
	push hl					; push block index addr to stack
	ld a,ixh				; recover block number
	call calcheader			; determine start header addr, result stored in hl
	ld de,$0006				; add 6 to get to start descriptor
	add hl,de
	ex de,hl				; de is set to start of RAM descriptor
	ld h,8					; use h as byte counter
.nextbyte1:
	call sst39sfrecvextrom	; read descriptor byte from ext rom
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
	call sst39sfrecvextrom	; read descriptor byte from ext rom
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
	ld ixh,a				; store temporarily in i
	inc hl
	call ramrecvhl			; load bank number in accumulator
	out (O_ROM_BANK),a		; set external rom bank
	inc hl					; next program address
	push hl					; push block index addr to stack
	ld a,ixh				; recover block number
	call calcheader			; determine start header addr, result stored in hl
	ld de,$000E				; add $000E to get to start extension
	add hl,de
	ex de,hl				; de is set to start of RAM descriptor
	ld h,3					; use h as byte counter
.nextbyte:
	call sst39sfrecvextrom	; read descriptor byte from ext rom
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
	ld ixh,a				; store temporarily in i
	inc hl
	call ramrecvhl			; load bank number in accumulator
	out (O_ROM_BANK),a		; set external rom bank
	inc hl					; next program address
	push hl					; push block index addr to stack
	ld a,ixh				; recover block number
	call calcheader			; determine start header addr, result stored in hl
	ld de,$0002				; add 2 to get to start of file lengths
	add hl,de
	ex de,hl				; de is set to start of RAM descriptor
	ld h,2					; use h as byte counter
.nextbyte:
	call sst39sfrecvextrom	; read descriptor byte from ext rom
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
	ld hl,0					
	ld (FILESTART),hl		; set current file counter to 0
	ld (PRGPOINTER),hl		; set current program counter to 0
	call filesdraw
	call showfilesuserinput
	ret

;-------------------------------------------------------------------------------
; Draw routine for the files
;-------------------------------------------------------------------------------
filesdraw:
	call clearscreen
	ld hl,.title
	ld de,$5000
	call printstring
	ld de,$5000 + 22*$50
	ld hl,.instructions1
	call printstring
	ld de,$5000 + 23*$50
	ld hl,.instructions2
	call printstring
	ld de,$5000 + 31
	ld hl,(FILESTART)
	inc hl						; start counting from 1
	call printdec16_3
	ld a,'/'
	ld (de),a
	inc de
	ld hl,(MAXFILES)
	call printdec16_3
	ld hl,(MAXFILES)
	ld a,h
	or l
	ret z
	call showdescriptions
	call showextensions
	call showfilelengths
	call showpointer
	ret

.title: DB COL_CYAN,150,127
		DB 127,127,127,127,127,127,127,00
		DB "FILE LIST"
		DB 00,127,127,127,127,127,127,127,127,135,255

.instructions1:
	DB COL_MAG,"p - previous page  n - next page",255

.instructions2:
	DB COL_MAG,"b - back to monitor",255

;-------------------------------------------------------------------------------
; Show descriptions
;-------------------------------------------------------------------------------
showdescriptions:
	ld bc,(FILESTART)			; set bc as program counter
	ld ixh,20					; number of files on screen
	ld de, $5000+$50 * 2 + 2	; set start address
.nextprogram:
	ld a,COL_CYAN
	ld (de),a
	inc de
	push bc						; put program number on stack
	inc bc						; start counting from 1
	ld h,b						; put bc into hl
	ld l,c
	call printdec16_3			; print program value, garbles bc
	pop bc						; retrieve program number from stack
	ld a,COL_WHITE
	ld (de),a
	inc de
	ld a,b						; load upper address in b
	rla							; shift right by 4 (multiply by 16)
	rla
	rla
	rla
	and $F0						; keep only upper nibble of upper byte
	ld h,a						; store upper byte in h
	ld a,c						; load lower byte
	rra							; shift right by 4 (divide by 16)
	rra
	rra
	rra
	and $0F						; keep only lower nibble
	or h						; put together with upper nibble of upper byte
	ld h,a						; store upper byte position
	ld a,c						; load lower byte
	rla							; shift left by 4 (multiply by 16)
	rla
	rla
	rla
	and $F0						; keep only upper nibble
	ld l,a						; store lower byte in l
	push de						; put video addr on stack
	ld de,$400					; set ex ram offset
	add hl,de					; add to ex ram address
	pop de						; get video ram from stack
	ld ixl,16					; number of bytes
.nextbyte:
	call ramrecvhl				; get character from external ram
	ld (de),a					; store in video ram
	inc de						; increment video ram addr
	inc hl						; increment ex ram addr
	dec ixl						; decrement byte counter
	jr nz,.nextbyte				; if not zero, go to next byte
	inc bc						; increment program counter
	ld hl,(MAXFILES)			; load maximum number of files
	or a						; reset carry flag
	sbc hl,bc					; subtract bc from hl, check if zero flag is set
	ret z						; return if max files is reached
	dec ixh						; decrement program per page counter
	ret z						; check if zero, if so, return
	ex de,hl					; swap de,hl
	ld de,$50-21				; load next line increment
	add hl,de					; add increment to video ram
	ex de,hl					; swap hl and de
	jp .nextprogram				; go to next program if not zero

;-------------------------------------------------------------------------------
; Show extensions
;-------------------------------------------------------------------------------
showextensions:
	ld bc,(FILESTART)			; set bc as program counter
	ld ixh,20					; number of files on screen
	ld de, $5000+$50 * 2 + 24	; set start address
.nextprogram:
	ld a,COL_GREEN
	ld (de),a
	inc de
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
	ld de,$50-4				; load next line increment
	add hl,de				; add increment to video ram
	ex de,hl				; swap hl and de
	jp .nextprogram			; go to next program if not zero

;-------------------------------------------------------------------------------
; Show file lengths
;-------------------------------------------------------------------------------
showfilelengths:
	ld bc,(FILESTART)			; set bc as program counter
	ld ixh,20					; number of files on screen
	ld de, $5000+$50 * 2 + 28	; set start address
.nextprogram:
	ld a,COL_YELLOW
	ld (de),a
	inc de
	ld h,b
	ld l,c
	add hl,bc				; multiply program counter by 2
	push de					; put video addr on stack
	ld de,$2800				; set ex ram offset
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
	ld a,COL_WHITE
	ld (de),a
	inc de
	inc hl
	inc bc					; increment program counter
	ld hl,(MAXFILES)		; load maximum number of files
	or a					; reset carry flag
	sbc hl,bc				; subtract bc from hl, check if zero flag is set
	ret z					; return if max files is reached
	dec ixh					; decrement program per page counter
	ret z					; check if zero, if so, return
	ex de,hl				; swap de,hl
	ld de,$50-7				; load next line increment
	add hl,de				; add increment to video ram
	ex de,hl				; swap hl and de
	jp .nextprogram			; go to next program if not zero

;-------------------------------------------------------------------------------
; Clear all pointers
;-------------------------------------------------------------------------------
clearpointers:
	ld b,20
	ld a,0
	ld hl, $5000 + $50 * 2
.nextline:
	ld (hl),a
	inc hl
	ld (hl),a
	ld de,$50 - 1
	add hl,de
	dec b
	ret z
	jr .nextline

;-------------------------------------------------------------------------------
; Show pointer for currently selected program
;-------------------------------------------------------------------------------
showpointer:
	ld bc,(FILESTART)			; set bc as program counter
	ld ixh,20					; number of files on screen
	ld de, $5000+$50 * 2		; set start address
.nextline:
	ld hl,(PRGPOINTER)
	or a
	sbc hl,bc
	jr nz,.cont
	ld a,93
	ld (de),a
.cont:
	inc bc					; increment program counter
	ld hl,(MAXFILES)		; load maximum number of files
	or a					; reset carry flag
	sbc hl,bc				; subtract bc from hl, check if zero flag is set
	ret z					; return if max files is reached
	dec ixh					; decrement program per page counter
	ret z					; check if zero, if so, return
	ex de,hl				; swap de,hl
	ld de,$50				; load next line increment
	add hl,de				; add increment to video ram
	ex de,hl				; swap hl and de
	jp .nextline			; go to next line if not zero

;-------------------------------------------------------------------------------
; Loop waiting for user input
;-------------------------------------------------------------------------------
showfilesuserinput:
.userinput:
	ld a,(NKEYBUF)
	cp 0
	jp z,.userinput
	ld de,KEYBUF
.nextkey:
	ld a,(de)					; load key from buffer
	cp 29 						; compare to 'b'
	jr z,.exitloop
	cp 25						; compare to 'n'
	call z,filesnextpage		; call routine next page
	cp 53						; compare to 'p'
	call z,filesprevpage		; call routine to previous page
	cp 38						; compare to 'u'
	call z,pointerdec			; call routine increment pointer position
	cp 12						; compare to 'd'
	call z,pointerinc			; call routine pointer decrement
.getkeycont:
	ld hl,KEYBUF
	ld d,0
	ld a,(NKEYBUF)
	ld e,a
	add hl,de
	ex de,hl
	inc de						; next position in key buffer
	ld a,(NKEYBUF)
	dec a						; decrement number of keys to print
	ld (NKEYBUF),a				; store this number in nkeybuf
	cp 0						; zero keys reached, return
	jp z,.userinput
	jp .nextkey					; else parse next key
.exitloop:
	ld a,0
	ld (KEYBUF),a
	ret

;-------------------------------------------------------------------------------
; Go to next page
;-------------------------------------------------------------------------------
filesprevpage:
	ld hl,(FILESTART)
	ld a,h
	or l
	jp z,filekeyreturn
	ld de,20
	or a
	sbc hl,de
	ld (FILESTART),hl
	jp filekeyreturn			; clean return when parsing keys

;-------------------------------------------------------------------------------
; Go to previous page
;-------------------------------------------------------------------------------
filesnextpage:
	ld hl,(MAXFILES)
	ld a,h
	or l
	jp z,filekeyreturn
	ld hl,(FILESTART)
	ld de,20
	add hl,de
	ld bc,(MAXFILES)
	or a
	sbc hl,bc
	jp nc,filekeyreturn
	ld hl,(FILESTART)
	ld de,20
	add hl,de
	ld (FILESTART),hl
	jp filekeyreturn			; clean return when parsing keys

;-------------------------------------------------------------------------------
; Increment pointer position
;-------------------------------------------------------------------------------
pointerinc:
	ld hl,(PRGPOINTER)
	inc hl
	ld (PRGPOINTER),hl
	jp pointerexit

;-------------------------------------------------------------------------------
; Decrement pointer position
;-------------------------------------------------------------------------------
pointerdec:
	ld hl,(PRGPOINTER)
	dec hl
	ld (PRGPOINTER),hl
	jp pointerexit

;-------------------------------------------------------------------------------
; Exit rountine for pointers
;-------------------------------------------------------------------------------
pointerexit:
	call clearpointers
	call showpointer
	jp exitkeys

filekeyreturn:
	call filesdraw
	jp exitkeys

exitkeys:
	ld a,0						; set zero in key buffer
	ld (KEYBUF),a
	ret