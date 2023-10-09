;# MAIN="main.asm"
;-------------------------------------------------------------------------------
; Load all files from external ROM
;-------------------------------------------------------------------------------
loadfiles:
	call copyprogblocks
	call copydesceroera
	call copyfileext
	call copyfilelengths
	call copyblocktokens
	ret

;-------------------------------------------------------------------------------
; Copy starting blocks from external rom to external ram
;
; Programs (files) are indicated by two bytes corresponding to the starting
; bank and block. This information can at most cover 2*8*60 = 960 bytes of data, 
; for which $0000-$0400 in RAM is allocated.
;
;-------------------------------------------------------------------------------
copyprogblocks:
	ld hl,0
	ld (MAXFILES),hl		; set file counter to 0
	ld b,8					; set bank counter
	ld c,0					; current bank
	ld hl,$0000				; set start ram storage location
.nextbank:
	ld a,c
	out (O_ROM_BANK),a		; set bank
	ld de,0					; first address on the bank
.nextblock:
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
	ld ixh,a				; put block in ixh
	ld a,c					; load current bank
	call ramsendhl			; store current bank
	inc hl
	ld a,ixh				; retrieve current block
	call ramsendhl			; store current block in ext ram
	inc hl					; increment ext ram addr
	inc de					; increment rom addr
	push hl					; put current ram addr on stack
	ld hl,(MAXFILES)		; load number of files in hl
	inc hl					; increment number of files
	ld (MAXFILES),hl		; store back
	pop hl					; retrieve current ram addr from stack
	jr .nextblock
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
	call retrievebankblock
	cp $FF					; check if this is the last block
	ret z					; return if so
	push hl					; push external ram addr to stack
	ld de,$0126				; descriptor offset
	call calcheaderaddr		; get address in hl from (a * $40) + de
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
	pop hl					; retrieve external ram addr to stack
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
	call retrievebankblock
	cp $FF					; check if this is the last block
	ret z					; return if so
	push hl					; push external ram addr to stack
	ld a,ixh				; recover block number
	ld de,$012E				; extension offset
	call calcheaderaddr		; get address in hl from (a * $40) + de
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
	call retrievebankblock
	cp $FF					; check if this is the last block
	ret z					; return if so
	push hl					; push external ram addr to stack
	ld de,$0122				; file length offset
	call calcheaderaddr		; get address in hl from (a * $40) + de
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
; Copy block tokens
;
; Copy the block tokens to indicate which block is in use and which block is
; free. To store this information, at most 60 * 8 = 480 bytes of data is needed.
; Memory locations $2C00 - $2E00 is reserved for this
;-------------------------------------------------------------------------------
copyblocktokens:
	ld hl,$2C00				; set ram storage location
	ld (FEXTRAMPTR),hl
	ld c,0					; current bank
.nextbank:
	ld a,c
	out (O_ROM_BANK),a		; set bank
	ld de,$0108				; first address on the bank
	ld b,60					; number of blocks
.nextblock:
	ld hl,(FEXTRAMPTR)
	call sst39sfrecvextrom	; read block token from external rom
	call ramsendhl
	inc hl
	ld (FEXTRAMPTR),hl
	ld hl,$0040
	add hl,de
	ex de,hl
	djnz .nextblock
.donebank:
	ld hl,(FEXTRAMPTR)
	ld de,$0004
	add hl,de
	ld (FEXTRAMPTR),hl
	inc c
	ld a,c
	cp 8
	jp nz,.nextbank
	ret

;-------------------------------------------------------------------------------
; Retrieve bank and block from external RAM
;
; input: hl - external ram address
;
; return: a  - block number
;		  hl - external ram address incremented by 2
;-------------------------------------------------------------------------------
retrievebankblock:
	call ramrecvhl			; load bank number in accumulator
	out (O_ROM_BANK),a		; set external rom bank
	inc hl
	call ramrecvhl			; load block number in accumulator
	inc hl					; next program address
	ret

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
	cp 49						; compare to 'o'
	call z,showoverview			; call routine to show overview
	cp 52 						; compare to 'ENTER'
	call z,showfileinfo			; call show info of single file routine
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
; Exit routine for pointers
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

;-------------------------------------------------------------------------------
; Show overview of used blocks and enter an infinite loop waiting on user
; input. Leave the infinite loop on a press of 'b'
;-------------------------------------------------------------------------------
showoverview:
	call clearscreen
	call showusedblocks
	ld de,$5000 + 23*$50
	ld hl,.instructions
	call printstring
.userinput:
	ld a,(NKEYBUF)
	cp 0
	jp z,.userinput
	ld de,KEYBUF
.nextkey:
	ld a,(de)					; load key from buffer
	cp 29 						; compare to 'b'
	jr z,.exitloop
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
	call filesdraw
	ld a,0
	ld (KEYBUF),a
	ret

.instructions:
	DB COL_MAG,"b - back to program list",255

;-------------------------------------------------------------------------------
; Show used blocks on screen
;-------------------------------------------------------------------------------
showusedblocks:
	ld hl,.title
	ld de,$5000
	call printstring
	ld hl,0
	ld (BLOCKSUSED),hl
	ld hl,$2C00
	ld b,8						; bank counter
	ld de,$5000+2*$50			; set video position
.nextbank:
	push hl
	ld hl,.str
	call printstring
	pop hl
	ld a,8
	sub b
	call printhex
	ld a,COL_CYAN
	ld (de),a
	inc de
	ld c,60
.nextblock:
	call ramrecvhl				; receive byte
	inc hl						; progress ram pointer
	cp $00						; check if block is used
	jp z,.printdot				; occupied, so print a dot
	jp .printsquare				; else, print a square
.cont:
	dec c						; decrement block counter
	jp z,.gonextbank			; go to next bank
	ld a,c
	cp 30						; check if 30 blocks have been printed
	jp nz,.nextblock			; if not, go to next block
	push hl						; else, go to next row in video
	ld hl,$50-30
	add hl,de
	ex de,hl
	pop hl						; retrieve ram pointer
	jp .nextblock
.gonextbank:
	dec b
	jp z,.exit
	push hl
	ld hl,$50-39
	add hl,de
	ex de,hl
	pop hl
	inc hl
	inc hl
	inc hl
	inc hl
	jp .nextbank
.printdot:						; print occupied char
	ld ix,(BLOCKSUSED)
	inc ix
	ld (BLOCKSUSED),ix
	ld a,'.'
	jr .print
.printsquare:
	ld a,127
.print:
	ld (de),a
	inc de
	jp .cont
.exit:
	ld de,$5000 + 19*$50
	ld hl,.str2
	call printstring
	push de
	ld de,(BLOCKSUSED)
	ld hl,60*8
	or a
	sbc hl,de
	pop de
	call printdec16
	ld a,'/'
	ld (de),a
	inc de
	ld hl,60*8
	call printdec16
	ld de,$5000 + 21 * $50
	ld hl,.str3
	call printstring
	ret

.str: DB "Bank:",COL_YELLOW,255
.title: DB COL_CYAN,150,127,127
		DB 127,127,127,127,127,127,127,00
		DB "STORAGE CAPACITY"
		DB 00,127,127,127,127,127,127,127,127,127,135,255
.str2: DB "Free blocks: ",255
.str3: DB COL_MAG,CHAR_SQUARE," = available, . = in use",255

;-------------------------------------------------------------------------------
; Show info for single file
;-------------------------------------------------------------------------------
showfileinfo:
	call clearscreen
	ld hl,(PRGPOINTER)			; load current program pointer
	ld de,$5000
	ld a,h
	call printhex
	ld a,l
	call printhex
	add hl,hl					; multiply by 2
	call ramrecvhl				; get bank
	ld b,a
	inc hl
	call ramrecvhl				; get block
	ld c,a
	ld de,$5000+$50
	ld a,b
	call printhex
	ld a,c
	call printhex
	call createchain			; build chain of blocks
	call printallocatedblocks
; -- print instructions on screen
	ld de,$5000 + 23*$50
	ld hl,.instructions2
	call printstring
	call showfileuserinput		; wait for user input, repeat on screen
	call loadfiles				; reload file information
	call filesdraw				; redraw file screen
	ret

.instructions2:
	DB COL_MAG,"b - back to monitor",255

;-------------------------------------------------------------------------------
; Print an overview of the blocks allocated by the file
;-------------------------------------------------------------------------------
printallocatedblocks:
;-- First print an overview containing only dots
	ld b,8						; bank counter
	ld de,$5000+2*$50			; set video position
.nextbank:
	ld hl,.str
	call printstring
	ld a,8
	sub b
	call printhex
	ld a,COL_CYAN
	ld (de),a
	inc de
	ld c,60
.nextblock:
	ld a,"."
	ld (de),a
	inc de
.cont:
	dec c						; decrement block counter
	jp z,.gonextbank			; go to next bank
	ld a,c
	cp 30						; check if 30 blocks have been printed
	jp nz,.nextblock			; if not, go to next block
	ld hl,$50-30
	add hl,de
	ex de,hl
	jp .nextblock
.gonextbank:
	dec b
	jp z,.exit
	ld hl,$50-39
	add hl,de
	ex de,hl
	jp .nextbank
.exit:
; -- next fill out squares for the blocks that the file is using
	ld hl,FILEBLADDR
.nextbankblock:
	call ramrecvhl
	inc hl
	ld b,a						; store bank in b
	cp $FF
	ret z
	call ramrecvhl
	inc hl
	push hl
	ld c,a						; store block in c
	ld a,b						; load bank counter in a
	add a						; multiply by 2 (number of rows)
	ld e,a
	ld h,$50					; number of bytes per row
	call mult8hehl				; perform multiplication, store in hl
	ld de,$5000+2*$50+9 		; set starting position
	add hl,de					; screen position in hl
	ld a,c
	cp 30
	jr c,.goprint
	ld de,$50
	add hl,de					; print in next row
	ld a,c
	sub 30						; decrement a by 30
.goprint:
	ld d,0
	ld e,a
	add hl,de					; jump c positions in the row
	ld a,CHAR_SQUARE
	ld (hl),a
	pop hl
	jp .nextbankblock
	
.str: DB "Bank:",COL_YELLOW,255

;-------------------------------------------------------------------------------
; User input routine for single file
;-------------------------------------------------------------------------------
showfileuserinput:
.userinput:
	ld a,(NKEYBUF)
	cp 0
	jp z,.userinput
	ld de,KEYBUF
.nextkey:
	ld a,(de)					; load key from buffer
	cp 29 						; compare to 'b'
	jr z,.exitloop
	cp 12						; compare to 'd'
	jp z,.checkdeletefile
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
.checkdeletefile:
	ld hl,.str1
	ld de,.str2
	call confirmmodal
	cp 0
	call z,deletefile
	jp .getkeycont

.str1: DB "Are you sure you want to",255
.str2: DB "delete this file? (Y/N)",255